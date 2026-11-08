import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';

const _mnemonic = 'machine crack daughter fish credit glare raven fever tunnel delay fish record';

/// An input of a payjoin PSBT, in transaction order.
sealed class PayjoinInput {
  final Utxo utxo;
  const PayjoinInput(this.utxo);
}

/// An input of the vault under test: unsigned, with its derivation metadata.
final class OwnedInput extends PayjoinInput {
  const OwnedInput(super.utxo);
}

/// The other party's input: finalized with a valid witness, no derivations.
final class ForeignInput extends PayjoinInput {
  final SingleSignatureVault signer;
  const ForeignInput(super.utxo, this.signer);
}

sealed class PayjoinOutput {
  final int amount;
  const PayjoinOutput(this.amount);
}

/// An output paying the vault under test, with its derivation metadata.
final class OwnedOutput extends PayjoinOutput {
  final String derivationPath;
  const OwnedOutput(super.amount, this.derivationPath);
}

final class ForeignOutput extends PayjoinOutput {
  final String address;
  const ForeignOutput(super.amount, this.address);
}

/// Builds payjoin-shaped PSBTs: some inputs belong to the vault under test,
/// the rest are the other party's, already signed and finalized.
abstract final class PayjoinPsbtFixture {
  static Seed seed(String passphrase) => Seed.fromMnemonic(utf8.encode(_mnemonic), passphrase: utf8.encode(passphrase));

  static SingleSignatureVault vault(String passphrase) =>
      SingleSignatureVault.fromMnemonic(utf8.encode(_mnemonic), passphrase: utf8.encode(passphrase));

  static SingleSignatureVault ourVault() => vault('payjoin-ours');

  static SingleSignatureVault counterpartyVault() => vault('payjoin-counterparty');

  static Utxo ownedUtxo(WalletBase vault, int index, {int amount = 100000}) => Utxo(
    Codec.encodeHex(Hash.sha256('owned ${vault.descriptor} #$index')),
    0,
    amount,
    '${vault.derivationPath}/0/$index',
  );

  static ForeignInput foreignInput(SingleSignatureVault signer, int index, {int amount = 100000}) => ForeignInput(
    Utxo(
      Codec.encodeHex(Hash.sha256('foreign ${signer.descriptor} #$index')),
      0,
      amount,
      '${signer.derivationPath}/0/$index',
    ),
    signer,
  );

  /// The sender's view of a proposal: two of our inputs unsigned, the
  /// receiver's input finalized between them, the receiver's output bumped by
  /// its input. We spend 200000, keep 149000 as change.
  static Psbt senderProposal(WalletBase vault, {SingleSignatureVault? receiver}) {
    final signer = receiver ?? counterpartyVault();
    return build(
      vault,
      inputs: [OwnedInput(ownedUtxo(vault, 0)), foreignInput(signer, 0), OwnedInput(ownedUtxo(vault, 1))],
      outputs: [ForeignOutput(150000, signer.getAddress(5)), OwnedOutput(149000, '${vault.derivationPath}/1/1')],
    );
  }

  /// The receiver's view: the sender's two inputs finalized, one of ours
  /// unsigned, our output receiving 100000 plus our input. The PSBT carries
  /// the sender's global xpub.
  static Psbt receiverProposal(WalletBase vault, {SingleSignatureVault? sender}) {
    final signer = sender ?? counterpartyVault();
    return build(
      vault,
      inputs: [foreignInput(signer, 0), foreignInput(signer, 1), OwnedInput(ownedUtxo(vault, 0))],
      outputs: [
        ForeignOutput(99000, signer.getAddress(1, isChange: true)),
        OwnedOutput(200000, '${vault.derivationPath}/0/7'),
      ],
      globalsFrom: signer,
    );
  }

  /// Assembles the PSBT and signs and finalizes every [ForeignInput] over the
  /// final transaction, so the foreign witnesses are valid.
  static Psbt build(
    WalletBase vault, {
    required List<PayjoinInput> inputs,
    required List<PayjoinOutput> outputs,
    WalletBase? globalsFrom,
  }) {
    final prevouts =
        inputs
            .map(
              (input) => TransactionOutput.forPayment(
                input.utxo.amount,
                (input is ForeignInput ? input.signer : vault).getAddressWithDerivationPath(input.utxo.derivationPath),
              ),
            )
            .toList();
    final tx = Transaction.withInputsAndOutputs(
      inputs.map((input) => TransactionInput.forPayment(input.utxo.transactionHash, input.utxo.index)).toList(),
      outputs
          .map(
            (output) => TransactionOutput.forPayment(output.amount, switch (output) {
              OwnedOutput(:final derivationPath) => vault.getAddressWithDerivationPath(derivationPath),
              ForeignOutput(:final address) => address,
            }),
          )
          .toList(),
      // Legacy serialization, as PSBT_GLOBAL_UNSIGNED_TX requires.
      AddressType.p2pkh,
    );

    final Map<String, dynamic> globals = {'00': tx.serialize()};
    if (globalsFrom != null) {
      final walletGlobals = Map<String, dynamic>.from(
        _ownedPsbt(globalsFrom, ownedUtxo(globalsFrom, 0)).toKeyMap()['global'],
      );
      globals.addAll(walletGlobals..remove('00'));
    }
    final inputMaps = <Map<String, dynamic>>[
      for (final (i, input) in inputs.indexed)
        switch (input) {
          OwnedInput() => Map<String, dynamic>.from(_ownedPsbt(vault, input.utxo).toKeyMap()['inputs'][0]),
          ForeignInput() => {
            '01': prevouts[i].serialize(),
            '08': _serializeWitness(_foreignWitness(tx, i, input, prevouts)),
          },
        },
    ];
    final outputMaps = [
      for (final output in outputs)
        switch (output) {
          OwnedOutput(:final derivationPath) => Map<String, dynamic>.from(
            _ownedPsbt(vault, ownedUtxo(vault, 0), changePath: derivationPath).toKeyMap()['outputs'][1],
          ),
          ForeignOutput() => <String, dynamic>{},
        },
    ];

    final psbt = Psbt.fromMap({'global': globals, 'inputs': inputMaps, 'outputs': outputMaps});
    return Psbt.parse(psbt.serialize());
  }

  /// Returns [psbt] with the BIP 32 derivation of our input at [fromIndex]
  /// copied onto the foreign input at [toIndex], as a PSBT forging our
  /// ownership of the other party's input would.
  static Psbt withForgedDerivation(Psbt psbt, {required int fromIndex, required int toIndex}) {
    final map = psbt.toKeyMap();
    final inputs = map['inputs'] as List<dynamic>;
    final from = inputs[fromIndex] as Map<String, dynamic>;
    final to = inputs[toIndex] as Map<String, dynamic>;
    for (final entry in from.entries.where((entry) => entry.key.startsWith('06'))) {
      to[entry.key] = entry.value;
    }
    return Psbt.parse(Psbt.fromMap(map).serialize());
  }

  /// BIP 141 witness stack serialization, as stored in a PSBT.
  static String _serializeWitness(List<String> items) {
    final buffer = StringBuffer(Codec.encodeHex(Codec.encodeVariableInteger(items.length)));
    for (final item in items) {
      buffer
        ..write(Codec.encodeHex(Codec.encodeVariableInteger(item.length ~/ 2)))
        ..write(item);
    }
    return buffer.toString();
  }

  static List<String> _foreignWitness(Transaction tx, int index, ForeignInput input, List<TransactionOutput> prevouts) {
    final path = input.utxo.derivationPath;
    final addressIndex = WalletUtility.getAccountIndexFromDerivationPath(path);
    final isChange = WalletUtility.isChangeFromDerivationPath(path);
    final keyStore = input.signer.keyStore;
    final publicKey = keyStore.getPublicKey(addressIndex, isChange: isChange);
    final psbtInput = PsbtInput.forSegwit(prevouts[index], [
      DerivationPath(publicKey, keyStore.masterFingerprint, path),
    ], []);
    keyStore.addSignatureToPsbtInput(
      psbtInput,
      AddressType.p2wpkh,
      path,
      tx.getSigHash(index, prevouts[index], AddressType.p2wpkh),
    );
    return [psbtInput.partialSig!.single.signature, publicKey];
  }

  static Psbt _ownedPsbt(WalletBase vault, Utxo utxo, {String? changePath}) {
    final tx = Transaction.forSinglePayment(
      [utxo],
      // Any address works: only the input and change metadata are reused.
      counterpartyVault().getAddress(0),
      changePath ?? '${vault.derivationPath}/1/0',
      1000,
      1,
      vault,
    );
    return Psbt.fromTransaction(tx, vault);
  }
}
