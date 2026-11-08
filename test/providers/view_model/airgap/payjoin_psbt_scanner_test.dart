import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/payjoin_psbt_fixture.dart';

void main() {
  late SingleSignatureVault ours;
  late SingleSigVaultListItem ourItem;

  setUp(() {
    NetworkType.setNetworkType(NetworkType.regtest);
    ours = PayjoinPsbtFixture.ourVault();
    ourItem = _singleSigItem(1, ours);
  });

  Future<SignProvider> scan(Psbt psbt, List<VaultListItemBase> vaults) async {
    final signProvider = SignProvider();
    await PsbtScannerViewModel(_FakeWalletProvider(vaults), signProvider).setMatchingVault(psbt.serialize());
    return signProvider;
  }

  group('scanning a payjoin PSBT', () {
    test("matches the vault for a sender's proposal", () async {
      final signProvider = await scan(PayjoinPsbtFixture.senderProposal(ours), [ourItem]);

      expect(signProvider.vaultListItem, same(ourItem));
    });

    test("matches the vault for a receiver's PSBT that carries the sender's global xpub", () async {
      final psbt = PayjoinPsbtFixture.receiverProposal(ours);
      expect(
        psbt.extendedPublicKeyList.map((xpub) => xpub.masterFingerprint),
        isNot(contains(ours.keyStore.masterFingerprint)),
      );

      final signProvider = await scan(psbt, [ourItem]);

      expect(signProvider.vaultListItem, same(ourItem));
    });

    test('rejects a finalized input that claims our fingerprint', () async {
      final forged = PayjoinPsbtFixture.withForgedDerivation(
        PayjoinPsbtFixture.senderProposal(ours),
        fromIndex: 0,
        toIndex: 1,
      );

      await expectLater(scan(forged, [ourItem]), throwsA(isA<VaultSigningNotAllowedException>()));
    });

    test('tells a multisig vault that Payjoin needs a single-signature wallet', () async {
      final multisig = MultisignatureVault.fromKeyStoreList([
        for (final passphrase in ['A', 'B', 'C'])
          KeyStore.fromSeed(PayjoinPsbtFixture.seed(passphrase), AddressType.p2wsh),
      ], 2);
      final psbt = PayjoinPsbtFixture.build(
        multisig,
        inputs: [
          OwnedInput(PayjoinPsbtFixture.ownedUtxo(multisig, 0)),
          PayjoinPsbtFixture.foreignInput(PayjoinPsbtFixture.counterpartyVault(), 0),
        ],
        outputs: [ForeignOutput(150000, PayjoinPsbtFixture.counterpartyVault().getAddress(5))],
      );

      await expectLater(
        scan(psbt, [_multisigItem(2, multisig)]),
        throwsA(
          isA<VaultSigningNotAllowedException>().having((e) => e.message, 'message', t.errors.payjoin_single_sig_only),
        ),
      );
    });
  });

  group('signing a payjoin PSBT', () {
    for (final (shape, build) in [
      ("sender's proposal", PayjoinPsbtFixture.senderProposal),
      ("receiver's PSBT", PayjoinPsbtFixture.receiverProposal),
    ]) {
      test('signs our inputs of a $shape and leaves the foreign ones as they were', () async {
        final psbt = build(ours);
        final foreign = [
          for (final (index, input) in psbt.inputs.indexed)
            if (input.isFinalized) (index, input.finalScriptWitness),
        ];

        final signed = Psbt.parse(
          await SignIsolates.addSignatureToPsbtWithSingleVault([
            PayjoinPsbtFixture.seed('payjoin-ours'),
            psbt.serialize(),
          ]),
        );

        for (final (index, witness) in foreign) {
          expect(signed.inputs[index].finalScriptWitness, witness);
          expect(signed.inputs[index].partialSig ?? [], isEmpty);
        }
        for (final (index, input) in signed.inputs.indexed) {
          if (!input.isFinalized) {
            expect(input.partialSig, hasLength(1), reason: 'input $index');
          }
        }
        // The other party finalizes and broadcasts; the result must be a valid spend.
        final tx = signed.finalizeInputs().getSignedTransaction(AddressType.p2wpkh);
        expect(tx.inputs, hasLength(psbt.inputs.length));
      });
    }
  });
}

SingleSigVaultListItem _singleSigItem(int id, SingleSignatureVault vault) => SingleSigVaultListItem(
  id: id,
  name: 'vault $id',
  colorIndex: 0,
  iconIndex: 0,
  descriptor: vault.descriptor,
  signerBsmsByAddressType: {AddressType.p2wpkh: ''},
  createdAt: DateTime(2026),
);

MultisigVaultListItem _multisigItem(int id, MultisignatureVault vault) => MultisigVaultListItem(
  id: id,
  name: 'multisig $id',
  colorIndex: 0,
  iconIndex: 0,
  signers: [
    for (final (index, keyStore) in vault.keyStoreList.indexed)
      MultisigSigner(id: index, name: 'signer $index', keyStore: keyStore),
  ],
  requiredSignatureCount: 2,
  createdAt: DateTime(2026),
);

class _FakeWalletProvider implements WalletProvider {
  _FakeWalletProvider(this._vaultList);

  final List<VaultListItemBase> _vaultList;

  @override
  bool get isVaultsLoaded => true;

  @override
  List<VaultListItemBase> get vaultList => _vaultList;

  @override
  VaultListItemBase getVaultById(int id) => _vaultList.firstWhere((vault) => vault.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
