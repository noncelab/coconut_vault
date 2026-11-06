// QA generated host test (logic_coverage.autofill)
// Target: SignIsolates.canSignToPsbtWithMultisignatureVault
// Intent (50065d91): "sign_isolates: canSignTo*Vault가 matchesVault 사용.
//   _isMultisigInputConsistentWithVault 중복 검증 제거." -> matchesVault가 input별 derivation path·
//   공개키·witness script·witness utxo까지 검증하므로, 제거된 조건(모든 키스토어 공개키 포함,
//   모든 input의 정책 일치 = mixed-policy/threshold 차단)이 여전히 지켜져야 한다. 파싱 실패는 false.
//
// Real classes only (coconut_lib vaults/PSBT, SignIsolates called directly).
// Fixtures copied from test/providers/view_model/airgap/psbt_scanner_view_model_test.dart:243-277 and
// mixed-policy construction from the same file :117-160.
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    NetworkType.setNetworkType(NetworkType.regtest);
  });

  group('SignIsolates.canSignToPsbtWithMultisignatureVault', () {
    test('같은 정책의 멀티시그 PSBT면 true', () async {
      final vault = _createP2wshVault();
      final psbtBase64 = _createP2wshPsbt(vault).serialize();

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vault, psbtBase64]), isTrue);
    });

    test('global xpub이 없는(BlueWallet) 같은 정책 PSBT도 true', () async {
      final vault = _createP2wshVault();
      final psbt = Psbt.parse(_createP2wshPsbt(vault).serialize());
      (psbt.psbtMap['global'] as Map).removeWhere((key, _) => (key as String).startsWith('01'));

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vault, psbt.serialize()]), isTrue);
    });

    test('서명자 구성이 다른 멀티시그 PSBT면 false', () async {
      final vault = _createP2wshVault();
      final otherPsbt = _createP2wshPsbt(_createP2wshVault(passphrases: ['D', 'E', 'F'])).serialize();

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vault, otherPsbt]), isFalse);
    });

    test('일부 서명자만 겹치는(키 하나 다른) 멀티시그 PSBT면 false', () async {
      final vault = _createP2wshVault(passphrases: ['A', 'B', 'C']);
      final partial = _createP2wshPsbt(_createP2wshVault(passphrases: ['A', 'B', 'Z'])).serialize();

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vault, partial]), isFalse);
    });

    test('같은 서명자지만 threshold가 다른 PSBT면 false', () async {
      final vault = _createP2wshVault();
      final threeOfThree = MultisignatureVault.fromKeyStoreList(vault.keyStoreList, 3);
      final psbtBase64 = _createP2wshPsbt(threeOfThree).serialize();

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vault, psbtBase64]), isFalse);
    });

    test('input 1이 다른 정책인 mixed-policy PSBT면 false', () async {
      final vaultA = _createP2wshVault(passphrases: ['A', 'B', 'C']);
      final vaultB = MultisignatureVault.fromKeyStoreList([
        vaultA.keyStoreList[0],
        KeyStore.fromSeed(_createP2wpkhVault(passphrase: 'D').keyStore.seed, AddressType.p2wsh),
      ], 1);
      final psbtA = Psbt.parse(_createP2wshPsbt(vaultA).serialize());
      final psbtB = Psbt.parse(_createP2wshPsbt(vaultB).serialize());
      psbtA.psbtMap['inputs'][1] = psbtB.psbtMap['inputs'][1];

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vaultA, psbtA.serialize()]), isFalse);
    });

    test('input 1이 같은 서명자·다른 threshold인 mixed-threshold PSBT면 false', () async {
      final vaultA = _createP2wshVault(passphrases: ['A', 'B', 'C']);
      final vaultB = MultisignatureVault.fromKeyStoreList(vaultA.keyStoreList, 3);
      final psbtA = Psbt.parse(_createP2wshPsbt(vaultA).serialize());
      final psbtB = Psbt.parse(_createP2wshPsbt(vaultB).serialize());
      psbtA.psbtMap['inputs'][1] = psbtB.psbtMap['inputs'][1];

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vaultA, psbtA.serialize()]), isFalse);
    });

    test('싱글시그 PSBT면 false', () async {
      final vault = _createP2wshVault();
      final single = _createP2wpkhVault(passphrase: 'A');
      final singlePsbt = _createP2wpkhPsbt(single).serialize();

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vault, singlePsbt]), isFalse);
    });

    test('파싱할 수 없는 PSBT 문자열이면 예외 없이 false', () async {
      final vault = _createP2wshVault();

      expect(await SignIsolates.canSignToPsbtWithMultisignatureVault([vault, 'not-a-psbt']), isFalse);
    });
  });
}

SingleSignatureVault _createP2wpkhVault({required String passphrase}) {
  return SingleSignatureVault.fromMnemonic(
    utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
    passphrase: utf8.encode(passphrase),
  );
}

Psbt _createP2wpkhPsbt(SingleSignatureVault vault) {
  final utxo = Utxo(Codec.encodeHex(Hash.sha256('psbt-scanner-view-model-test')), 0, 100000, "m/84'/1'/0'/0/0");
  final tx = Transaction.forSinglePayment([utxo], vault.getAddress(1), '${vault.derivationPath}/1/1', 15000, 3, vault);
  return Psbt.fromTransaction(tx, vault);
}

MultisignatureVault _createP2wshVault({List<String> passphrases = const ['A', 'B', 'C']}) {
  final keyStores =
      passphrases.map((passphrase) {
        final vault = _createP2wpkhVault(passphrase: passphrase);
        return KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2wsh);
      }).toList();
  return MultisignatureVault.fromKeyStoreList(keyStores, 2);
}

Psbt _createP2wshPsbt(MultisignatureVault vault) {
  final utxos = [
    Utxo(Codec.encodeHex(Hash.sha256('psbt-scanner-view-model-test-multisig-0')), 0, 100000, "m/48'/1'/0'/2'/0/0"),
    Utxo(Codec.encodeHex(Hash.sha256('psbt-scanner-view-model-test-multisig-1')), 0, 110000, "m/48'/1'/0'/2'/0/1"),
  ];
  final tx = Transaction.forSinglePayment(utxos, vault.getAddress(1), '${vault.derivationPath}/1/1', 15000, 3, vault);
  return Psbt.fromTransaction(tx, vault);
}
