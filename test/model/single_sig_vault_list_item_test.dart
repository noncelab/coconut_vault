import 'package:coconut_lib/coconut_lib.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('니모닉, passphrase 없이 VaultListItem 생성', () {
    test('확장공개키, MFP로 SingleSignatureVault 생성 (SingleSigVaultListItem 생성자에서 사용하는 로직)', () {
      NetworkType.setNetworkType(NetworkType.mainnet);
      // mnemonic: hope disorder index rather outdoor response rain range genuine oil banana feed
      String masterFingerprint = "92DBF650";
      final keyStore = KeyStore.fromExtendedPublicKey(
          "zpub6rYqhgYyyvypyGmx5NomXL5DJobtWTrer9yKXQo5SP7X4jw6rYCbqmfgyBNiuFvrhAwUasmLE4jzd6DPosbSYL2z5bk4tSorCZ7bsFp6HPx",
          masterFingerprint);
      final singleSignatureVault = SingleSignatureVault.fromKeyStore(keyStore);
      expect(keyStore.masterFingerprint, masterFingerprint);
      expect(singleSignatureVault.keyStore.masterFingerprint, masterFingerprint);
      expect(singleSignatureVault.getAddress(0), "bc1q9p56zgq7zx67k0hsp34x7dk4hccs5h4f0h68ws");
      expect(singleSignatureVault.keyStore.hasSeed, false);
      expect(singleSignatureVault.derivationPath, "m/84'/0'/0'");
    });

    //test('확장공개키로 MultisigVaultListItem 생성', () {});
  });

  // group('SingleSigVaultListItem', () {
  //   const testId = 1;
  //   const testName = 'Test Vault';
  //   const testColorIndex = 0;
  //   const testIconIndex = 1;
  //   const testSecret =
  //       'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  //   const testPassphrase = 'test passphrase';

  //   test('생성자로 생성시 secret과 passphrase가 멤버변수에 저장되지 않아야 함', () {
  //     // Given
  //     final singleSigVaultListItem = SingleSigVaultListItem(
  //       id: testId,
  //       name: testName,
  //       colorIndex: testColorIndex,
  //       iconIndex: testIconIndex,
  //       secret: testSecret,
  //       passphrase: testPassphrase,
  //     );

  //     // Then
  //     expect(singleSigVaultListItem.secret, isNull);
  //     expect(singleSigVaultListItem.passphrase, isNull);
  //   });

  //   test('toJson 결과에 secret과 passphrase가 포함되지 않아야 함', () {
  //     // Given
  //     final singleSigVaultListItem = SingleSigVaultListItem(
  //       id: testId,
  //       name: testName,
  //       colorIndex: testColorIndex,
  //       iconIndex: testIconIndex,
  //       secret: testSecret,
  //       passphrase: testPassphrase,
  //     );

  //     // When
  //     final json = singleSigVaultListItem.toJson();

  //     // Then
  //     expect(json['secret'], isNull);
  //     expect(json['passphrase'], isNull);

  //     // 다른 필드들은 정상적으로 저장되어야 함
  //     expect(json['id'], testId);
  //     expect(json['name'], testName);
  //     expect(json['colorIndex'], testColorIndex);
  //     expect(json['iconIndex'], testIconIndex);
  //     expect(json['vaultType'], 'singleSignature');
  //   });
  // });
}
