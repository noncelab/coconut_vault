import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/wallet_persistence_strategy.dart';
import 'package:coconut_vault/repository/wallet_storage_cleaner.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:coconut_vault/usecases/reset_credentials_and_wallets_usecase.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_reset_flow_test.dart' show ResetPreferences;
import 'wallet_cleanup_auth_state_test.dart' show CleanupZone;
import 'pin_auth_service_test.dart' show TestKdf;

class CleanerWallets implements WalletProvider {
  final CleanupZone zone;
  CleanerWallets(this.zone);
  @override
  Future<void> reset() => WalletStorageCleaner.clearAll(secureZoneRepository: zone);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class RepositoryPinStorage implements PinAuthStorage {
  final repository = SecureStorageRepository();
  @override
  Future<String?> read(String key) => repository.readStrict(key: key);
  @override
  Future<void> write(String key, String value) => repository.write(key: key, value: value);
  @override
  Future<void> delete(String key) => repository.delete(key: key);
}

class FailingZone extends CleanupZone {
  bool fail = true;
  @override
  Future<List<String>> deleteKeys({required List<String> aliasList}) async =>
      fail ? aliasList : super.deleteKeys(aliasList: aliasList);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const keyChannel = MethodChannel('onl.coconut.vault/secure_storage_keys');
  const valueChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const publicList = '[{"id":1,"vaultType":"singleSignature"}]';
  final walletKey = WalletStorageKeys.walletKey(1, WalletType.singleSignature);
  final privacyKey = WalletStorageKeys.privacyInfoKey(walletKey);
  final prefs = SharedPrefsRepository();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> values;
  late AuthProvider auth;
  late PinAuthService pin;
  late CleanupZone zone;
  late List<String> events;
  late int enumerationFailures;
  late int deleteFailures;
  late int deleteAttempts;
  late int enumerationAttempts;
  late bool ignoreDeletes;
  String? failingDeleteKey;
  late Map<String, String> credentials;

  Future<void> reset() => ResetCredentialsAndWalletsUsecase.execute(
    walletProvider: CleanerWallets(zone),
    authProvider: auth,
    preferenceProvider: ResetPreferences(events),
  );

  void expectRetained() {
    expect(prefs.getString(SharedPrefsKeys.kVaultListField), publicList);
    expect(auth.isPinSet, true);
    expect(events, isEmpty);
    for (final entry in credentials.entries) {
      expect(values[entry.key], entry.value);
    }
  }

  Future<void> expectReset() async {
    expect(values.containsKey(walletKey), false);
    expect(values.containsKey(privacyKey), false);
    expect(prefs.getString(SharedPrefsKeys.kVaultListField), isEmpty);
    expect(auth.isPinSet, false);
    expect(await pin.hasPin(), false);
    expect(events, ['preferences']);
  }

  setUp(() async {
    enumerationFailures = deleteFailures = deleteAttempts = enumerationAttempts = 0;
    ignoreDeletes = false;
    failingDeleteKey = null;
    events = [];
    zone = CleanupZone();
    values = {walletKey: 'unreadable-wallet', privacyKey: 'unreadable-privacy'};
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.hasShownStartGuide: true,
      SharedPrefsKeys.kVaultListField: publicList,
      SharedPrefsKeys.vaultListLength: 1,
    });
    await prefs.init();
    messenger.setMockMethodCallHandler(keyChannel, (call) async {
      expect(call.method, 'getAllKeys');
      enumerationAttempts++;
      if (enumerationFailures-- > 0) throw PlatformException(code: 'KEYS_UNAVAILABLE');
      return values.keys.toList();
    });
    messenger.setMockMethodCallHandler(valueChannel, (call) async {
      final key = call.arguments['key'] as String?;
      switch (call.method) {
        case 'readAll':
          throw PlatformException(code: 'CORRUPT_VALUE');
        case 'read':
          if (key == walletKey || key == privacyKey) throw PlatformException(code: 'CORRUPT_VALUE');
          return values[key];
        case 'write':
          values[key!] = call.arguments['value'] as String;
          return null;
        case 'delete':
          deleteAttempts++;
          if (key == failingDeleteKey) throw PlatformException(code: 'DELETE_FAILED');
          if (deleteFailures-- > 0) throw PlatformException(code: 'DELETE_FAILED');
          if (!ignoreDeletes) values.remove(key);
          return null;
        default:
          throw StateError('Unexpected storage method: ${call.method}');
      }
    });
    pin = PinAuthService(storage: RepositoryPinStorage(), kdf: TestKdf());
    await pin.savePin('123456', false);
    values[SecureStorageKeys.kVaultPin] = 'legacy-pin';
    auth = AuthProvider(pinAuth: pin, initializeDeviceBiometrics: false);
    await auth.ready;
    expect(auth.isPinSet, true);
    credentials =
        Map.of(values)
          ..remove(walletKey)
          ..remove(privacyKey);
    deleteAttempts = enumerationAttempts = 0;
  });

  tearDown(() {
    auth.dispose();
    messenger.setMockMethodCallHandler(keyChannel, null);
    messenger.setMockMethodCallHandler(valueChannel, null);
  });

  test('unreadable wallet values are deleted without reading them; credentials survive cleaner', () async {
    await expectLater(SecureStorageRepository().readStrict(key: walletKey), throwsA(isA<PlatformException>()));
    await WalletStorageCleaner.clearAll(secureZoneRepository: zone);
    expect(values, credentials);
    expect(auth.isPinSet, true);
    expect(await pin.hasPin(), true);
    await auth.resetCredentials(afterWalletDeletion: true);
    expect(await pin.hasPin(), false);
  });

  test('full reset deletes unreadable wallet and privacy values before disabling PIN', () async {
    await reset();
    await expectReset();
  });

  test('key enumeration failure retains metadata and PIN, then full reset can be retried', () async {
    enumerationFailures = 3;
    await expectLater(reset(), throwsA(isA<PlatformException>()));
    expect(enumerationAttempts, 3);
    expect(deleteAttempts, 0);
    expectRetained();
    expect(await pin.hasPin(), true);
    await reset();
    await expectReset();
  });

  test('delete failure retains metadata and PIN, then full reset can be retried', () async {
    deleteFailures = 3;
    await expectLater(reset(), throwsA(isA<PlatformException>()));
    expect(deleteAttempts, 3);
    expectRetained();
    expect(await pin.hasPin(), true);
    await reset();
    await expectReset();
  });

  test('a successful delete response with remaining records cannot disable PIN', () async {
    ignoreDeletes = true;
    await expectLater(reset(), throwsStateError);
    expectRetained();
    expect(await pin.hasPin(), true);
    ignoreDeletes = false;
    await reset();
    await expectReset();
  });

  test('transient deletion failure succeeds within the retry limit', () async {
    deleteFailures = 1;
    await reset();
    await expectReset();
  });

  test('partial deletion retains public metadata and PIN until retry completes', () async {
    failingDeleteKey = privacyKey;
    await expectLater(reset(), throwsA(isA<PlatformException>()));
    expect(values.containsKey(walletKey), false);
    expect(values.containsKey(privacyKey), true);
    expectRetained();
    expect(await pin.hasPin(), true);
    failingDeleteKey = null;
    await reset();
    await expectReset();
  });

  test('fallback without public wallets deletes unreadable records and preserves credentials', () async {
    await prefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultListField);
    await WalletStorageCleaner.clearAll(secureZoneRepository: zone);
    expect(zone.deleted.toSet(), {walletKey, privacyKey});
    expect(values, credentials);
    expect(await pin.hasPin(), true);
  });

  test('Secure Zone partial failure also retains metadata and PIN for retry', () async {
    final failingZone = FailingZone();
    zone = failingZone;
    await expectLater(reset(), throwsStateError);
    expect(deleteAttempts, 0);
    expectRetained();
    failingZone.fail = false;
    await reset();
    await expectReset();
  });
}
