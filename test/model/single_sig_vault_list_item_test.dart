import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SingleSigVaultListItem', () {
    const testId = 1;
    const testName = 'Test Vault';
    const testColorIndex = 0;
    const testIconIndex = 1;
    const testSecret =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const testPassphrase = 'test passphrase';

    test('생성자로 생성시 secret과 passphrase가 멤버변수에 저장되지 않아야 함', () {
      // Given
      final singleSigVaultListItem = SingleSigVaultListItem(
        id: testId,
        name: testName,
        colorIndex: testColorIndex,
        iconIndex: testIconIndex,
        secret: testSecret,
        passphrase: testPassphrase,
      );

      // Then
      expect(singleSigVaultListItem.secret, isNull);
      expect(singleSigVaultListItem.passphrase, isNull);
    });

    test('toJson 결과에 secret과 passphrase가 포함되지 않아야 함', () {
      // Given
      final singleSigVaultListItem = SingleSigVaultListItem(
        id: testId,
        name: testName,
        colorIndex: testColorIndex,
        iconIndex: testIconIndex,
        secret: testSecret,
        passphrase: testPassphrase,
      );

      // When
      final json = singleSigVaultListItem.toJson();

      // Then
      expect(json['secret'], isNull);
      expect(json['passphrase'], isNull);

      // 다른 필드들은 정상적으로 저장되어야 함
      expect(json['id'], testId);
      expect(json['name'], testName);
      expect(json['colorIndex'], testColorIndex);
      expect(json['iconIndex'], testIconIndex);
      expect(json['vaultType'], 'singleSignature');
    });
  });
}
