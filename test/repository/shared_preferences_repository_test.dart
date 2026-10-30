import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsRepository.hasPublicVaultList', () {
    test('returns false when the public vault list key is absent', () async {
      SharedPreferences.setMockInitialValues({});
      await SharedPrefsRepository().init();

      expect(SharedPrefsRepository().hasPublicVaultList(), isFalse);
    });

    test('returns false when the public vault list is an empty string', () async {
      SharedPreferences.setMockInitialValues({SharedPrefsKeys.kVaultListField: ''});
      await SharedPrefsRepository().init();

      expect(SharedPrefsRepository().hasPublicVaultList(), isFalse);
    });

    test('returns false when the public vault list is an empty JSON array', () async {
      SharedPreferences.setMockInitialValues({SharedPrefsKeys.kVaultListField: '[]'});
      await SharedPrefsRepository().init();

      expect(SharedPrefsRepository().hasPublicVaultList(), isFalse);
    });

    test('returns true when the public vault list contains a wallet', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsKeys.kVaultListField: '[{"id":1,"vaultType":"singleSignature"}]',
      });
      await SharedPrefsRepository().init();

      expect(SharedPrefsRepository().hasPublicVaultList(), isTrue);
    });
  });

  group('SharedPrefsRepository.init', () {
    test('removes the deprecated VAULT_LIST_LENGTH key', () async {
      SharedPreferences.setMockInitialValues({SharedPrefsKeys.kDeprecatedVaultListLength: 3});
      await SharedPrefsRepository().init();

      expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kDeprecatedVaultListLength), isFalse);
    });
  });
}
