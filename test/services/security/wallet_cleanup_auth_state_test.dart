import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_storage_cleaner.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CleanupStorage implements SecureStorageRepositoryContract {
  final values = <String, String>{
    PinAuthService.lockKey: 'test-only-permanent-lock',
    PinAuthService.verifierKey: 'test-only-verifier',
    SecureStorageKeys.kVaultPin: 'test-only-legacy-hash',
    'test-only-wallet-key': 'test-only-encrypted-wallet',
  };
  @override
  Future<List<String>> getAllKeys() async => values.keys.toList();
  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class CleanupZone implements SecureZoneRepositoryContract {
  List<String> deleted = [];
  @override
  Future<List<String>> deleteKeys({required List<String> aliasList}) async {
    deleted.addAll(aliasList);
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('wallet cleanup preserves authentication until AuthProvider completes credential reset', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsRepository().init();
    final storage = CleanupStorage();
    final zone = CleanupZone();
    await WalletStorageCleaner.clearAll(storageService: storage, secureZoneRepository: zone);
    expect(storage.values.keys.toSet(), {
      PinAuthService.lockKey,
      PinAuthService.verifierKey,
      SecureStorageKeys.kVaultPin,
    });
    expect(zone.deleted, ['test-only-wallet-key']);
  });
}
