import 'package:coconut_vault/app_entry_flow.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_availability_checker.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:coconut_vault/usecases/resolve_authenticated_entry_flow_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pin_auth_service_test.dart' show MemoryStorage, TestKdf;

class EntryAuth implements AuthProvider {
  @override
  final bool isPermanentlyLocked;
  @override
  final bool isPinSet;
  @override
  final bool authenticationUnavailable;
  EntryAuth({this.isPermanentlyLocked = false, this.isPinSet = true, this.authenticationUnavailable = true});
  @override
  Future<void> get ready => Future.value();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returning after setting device passcode shows Keychain guidance despite failed startup', () async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.hasShownStartGuide: true,
      SharedPrefsKeys.isPinEnabled: true,
      SharedPrefsKeys.kVaultListField: 'test-only-wallet-metadata',
    });
    await SharedPrefsRepository().init();
    // Passcode-protected records were removed, and writing while the device
    // passcode is disabled fails before the devicePasswordRequired screen.
    final storage = MemoryStorage()..failWrite = PinAuthService.lockKey;
    final pin = PinAuthService(storage: storage, kdf: TestKdf());
    final auth = AuthProvider(pinAuth: pin, initializeDeviceBiometrics: false);
    addTearDown(auth.dispose);
    await auth.ready;
    expect(auth.authenticationUnavailable, true);
    expect(auth.isPinSet, true);

    // User sets the device passcode and returns in the same app session.
    storage.failWrite = null;
    final next = await ResolveAuthenticatedEntryFlowUsecase.execute(
      authProvider: auth,
      isIos: true,
      walletCount: 1,
      verifyIosKeychainValidity: () => SecureZoneManager().verifyIosKeychainValidity(pinAuth: pin),
    );
    expect(next, AppEntryFlow.cannotAccessToSecureZone);
    // Routing must not silently unlock authentication or erase wallet metadata.
    expect(auth.authenticationUnavailable, true);
    await expectLater(pin.hasPin(), throwsA(isA<PinAuthException>()));
    expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), 'test-only-wallet-metadata');
  });

  test('permanent lock takes precedence over Keychain guidance', () async {
    final next = await ResolveAuthenticatedEntryFlowUsecase.execute(
      authProvider: EntryAuth(isPermanentlyLocked: true),
      isIos: true,
      walletCount: 1,
      verifyIosKeychainValidity: () => throw StateError('must not run'),
    );
    expect(next, AppEntryFlow.pinCheck);
  });

  test('Android and iOS without existing PIN retain generic authentication error flow', () async {
    for (final isIos in [false, true]) {
      final next = await ResolveAuthenticatedEntryFlowUsecase.execute(
        authProvider: EntryAuth(isPinSet: !isIos),
        isIos: isIos,
        walletCount: 0,
        verifyIosKeychainValidity: () => throw StateError('must not run'),
      );
      expect(next, AppEntryFlow.pinCheck);
    }
  });

  test('valid Keychain retains PIN error and normal wallet entry decisions', () async {
    for (final (unavailable, wallets, expected) in [
      (true, 0, AppEntryFlow.pinCheck),
      (false, 1, AppEntryFlow.pinCheck),
      (false, 0, AppEntryFlow.vaultHome),
    ]) {
      final next = await ResolveAuthenticatedEntryFlowUsecase.execute(
        authProvider: EntryAuth(authenticationUnavailable: unavailable),
        isIos: true,
        walletCount: wallets,
        verifyIosKeychainValidity: () async => true,
      );
      expect(next, expected);
    }
  });
}
