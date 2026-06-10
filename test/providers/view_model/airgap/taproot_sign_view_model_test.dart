import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/providers/view_model/airgap/taproot/taproot_sign_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // group('TaprootSignViewModel.resolveSignType', () {
  //   setUp(() {
  //     NetworkType.setNetworkType(NetworkType.regtest);
  //   });

  //   test('모든 input의 tapLeafScript가 null이면 keyPath로 판정한다', () {
  //     final vault = _createP2trVault();
  //     final psbt = _createP2trPsbt(vault);

  //     expect(psbt.inputs.any((input) => input.tapLeafScript != null), isFalse);
  //     expect(TaprootSignViewModel.resolveSignType(psbt), TaprootSignType.keyPath);
  //   });

  //   test('모든 input에 tapLeafScript가 있으면 scriptPath로 판정한다', () {
  //     final vault = _createP2trVault();
  //     final psbt = _createP2trPsbt(vault, inputCount: 2);
  //     psbt.inputs[0].tapLeafScript = Script([]);
  //     psbt.inputs[1].tapLeafScript = Script([]);

  //     expect(psbt.inputs.every((input) => input.tapLeafScript != null), isTrue);
  //     expect(TaprootSignViewModel.resolveSignType(psbt), TaprootSignType.scriptPath);
  //   });

  //   test('일부 input에만 tapLeafScript가 있으면 FormatException을 던진다', () {
  //     final vault = _createP2trVault();
  //     final psbt = _createP2trPsbt(vault, inputCount: 2);
  //     psbt.inputs[1].tapLeafScript = Script([]);

  //     expect(psbt.inputs.any((input) => input.tapLeafScript != null), isTrue);
  //     expect(psbt.inputs.every((input) => input.tapLeafScript != null), isFalse);
  //     expect(() => TaprootSignViewModel.resolveSignType(psbt), throwsA(isA<FormatException>()));
  //   });
  // });
}

SingleSignatureVault _createP2wpkhVault({required String passphrase}) {
  return SingleSignatureVault.fromMnemonic(
    utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
    passphrase: utf8.encode(passphrase),
  );
}

TaprootVault _createP2trVault() {
  final keyStores =
      ['taproot-A', 'taproot-B'].map((passphrase) {
        final vault = _createP2wpkhVault(passphrase: passphrase);
        return KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2tr);
      }).toList();
  return TaprootVault.fromKeyStoreList(keyStores, []);
}

Psbt _createP2trPsbt(TaprootVault vault, {int inputCount = 1}) {
  final utxos = List<Utxo>.generate(inputCount, (index) {
    return Utxo(
      Codec.encodeHex(Hash.sha256('taproot-sign-view-model-test-$index')),
      0,
      100000 + index,
      "m/86'/1'/0'/0/$index",
    );
  });
  final tx = Transaction.forSinglePayment(utxos, vault.getAddress(1), '${vault.derivationPath}/1/0', 15000, 3, vault);
  return Psbt.fromTransaction(tx, vault);
}
