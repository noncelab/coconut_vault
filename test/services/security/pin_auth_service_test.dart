import 'dart:async';
import 'dart:convert';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_availability_checker.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryStorage implements PinAuthStorage {
  final values = <String, String>{};
  String? failWrite;
  String? failRead;
  String? failDelete;
  bool writeThenThrow = false;
  final events = <String>[];
  @override
  Future<String?> read(String key) async {
    events.add('read:$key');
    if (failRead == key) throw StateError('test-only secret must not escape');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    events.add('write:$key');
    if (failWrite == key) {
      if (writeThenThrow) values[key] = value;
      throw StateError('test-only secret must not escape');
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    events.add('delete:$key');
    if (failDelete == key) throw StateError('test-only secret must not escape');
    values.remove(key);
  }
}

/// Fast deterministic KDF only for state-machine tests. Real Argon2 is tested below.
class TestKdf implements PinKdf {
  int calls = 0;
  Completer<void>? gate;
  Uint8List? lastPin;
  Uint8List? lastSalt;
  Uint8List? lastOutput;
  @override
  Future<Uint8List> derive(Uint8List pin, Uint8List salt, PinKdfParameters parameters) async {
    calls++;
    lastPin = pin;
    lastSalt = salt;
    if (gate != null) await gate!.future;
    return lastOutput = Uint8List.fromList(sha256.convert([...pin, ...salt]).bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryStorage storage;
  late TestKdf kdf;
  late DateTime clock;
  late PinAuthService service;
  PinAuthService make({PinLockState Function()? legacy, Future<void> Function()? cleanup, bool debug = false}) =>
      PinAuthService(
        storage: storage,
        kdf: kdf,
        now: () => clock,
        debugDelay: debug,
        legacyState: legacy ?? () => const PinLockState(),
        removeLegacyState: cleanup ?? () async {},
      );
  Future<bool> verify(String pin, {bool count = true, bool character = false}) =>
      service.verify(pin, countFailure: count, character: character);
  void legacyPin() => storage.values[SecureStorageKeys.kVaultPin] = hashString('012345');
  final authError = throwsA(isA<PinAuthException>());

  setUp(() {
    storage = MemoryStorage();
    kdf = TestKdf();
    clock = DateTime.utc(2026, 10, 16);
    service = make();
  });

  test('new numeric PIN, leading zero, wrong PIN, change and fresh random salt', () async {
    await service.savePin('012345', false);
    final first = jsonDecode(storage.values[PinAuthService.verifierKey]!) as Map;
    expect(first, containsPair('algorithm', 'argon2id'));
    expect(first, containsPair('memory', 19456));
    expect(base64Decode(first['salt'] as String), hasLength(16));
    expect(await verify('012345'), true);
    expect(await verify('12345', count: false), false);
    expect(await verify('999999', count: false), false);
    await service.savePin('654321', false);
    final second = jsonDecode(storage.values[PinAuthService.verifierKey]!) as Map;
    expect(second['salt'], isNot(first['salt']));
    expect(await verify('012345', count: false), false);
    expect(await verify('654321'), true);
    await service.savePin('654321', false);
    expect((jsonDecode(storage.values[PinAuthService.verifierKey]!) as Map)['salt'], isNot(second['salt']));
  });

  test('existing character password policy and UTF-8 remain supported', () async {
    await service.savePin('테스트-only passphrase!', true);
    expect(await verify('테스트-only passphrase!', character: true), true);
    expect((await service.initialize())!['character'], true);
  });

  test('legacy wrong PIN and biometric-style state reset never migrate verifier', () async {
    legacyPin();
    expect(await verify('999999'), false);
    expect(kdf.calls, 0);
    await service.reset();
    expect(storage.values.containsKey(PinAuthService.verifierKey), false);
    expect(storage.values[SecureStorageKeys.kVaultPin], hashString('012345'));
    expect(service.state.attempts, 0);
  });

  test('successful legacy authentication writes and verifies before deleting SHA-256', () async {
    legacyPin();
    expect(await verify('012345'), true);
    expect(storage.values.containsKey(SecureStorageKeys.kVaultPin), false);
    final write = storage.events.indexOf('write:${PinAuthService.verifierKey}');
    final read = storage.events.indexOf('read:${PinAuthService.verifierKey}', write);
    final remove = storage.events.indexOf('delete:${SecureStorageKeys.kVaultPin}');
    expect(write, lessThan(read));
    expect(read, lessThan(remove));
    service = make();
    expect(await verify('012345'), true);
  });

  for (final corrupt in ['{', '{}', '{"version":999}', '{"version":1,"algorithm":"sha256"}']) {
    test('corrupt new verifier cannot fall back: $corrupt', () async {
      legacyPin();
      await service.initialize();
      storage.values[PinAuthService.verifierKey] = corrupt;
      await expectLater(verify('012345'), authError);
      expect(storage.values.containsKey(SecureStorageKeys.kVaultPin), true);
      expect(kdf.calls, 0);
    });
  }

  test('unknown KDF costs, salt length and algorithm are rejected before KDF', () async {
    await service.savePin('012345', false);
    final original = storage.values[PinAuthService.verifierKey]!;
    for (final field
        in <String, Object>{
          'memory': 99999999,
          'iterations': 0,
          'parallelism': 4,
          'argonVersion': 16,
          'version': 2,
          'algorithm': 'argon2i',
          'disabled': true,
          'salt': 'AA==',
          'verifier': 'AA==',
        }.entries) {
      final record = jsonDecode(original) as Map<String, dynamic>;
      record[field.key] = field.value;
      storage.values[PinAuthService.verifierKey] = jsonEncode(record);
      await expectLater(verify('012345'), authError);
    }
    expect(kdf.calls, 1);
  });

  for (final written in [false, true]) {
    test('migration write interruption recovers original PIN on restart (written=$written)', () async {
      legacyPin();
      storage.failWrite = PinAuthService.verifierKey;
      storage.writeThenThrow = written;
      await expectLater(verify('012345'), authError);
      expect(storage.values.containsKey(SecureStorageKeys.kVaultPin), true);
      storage.failWrite = null;
      service = make();
      expect(await verify('012345'), true);
      expect(storage.values.containsKey(SecureStorageKeys.kVaultPin), false);
    });
  }

  test('read-back failure retains legacy; restart uses committed Argon2 record', () async {
    legacyPin();
    // Arrange a read-back failure only after the KDF has started.
    kdf.gate = Completer<void>();
    final pending = verify('012345');
    await Future<void>.delayed(Duration.zero);
    storage.failRead = PinAuthService.verifierKey;
    kdf.gate!.complete();
    await expectLater(pending, authError);
    expect(storage.values.containsKey(SecureStorageKeys.kVaultPin), true);
    storage.failRead = null;
    service = make();
    kdf.gate = null;
    expect(await verify('012345'), true);
  });

  test('legacy deletion failure after migration is recoverable without fallback', () async {
    legacyPin();
    storage.failDelete = SecureStorageKeys.kVaultPin;
    await expectLater(verify('012345'), authError);
    expect(storage.values.containsKey(PinAuthService.verifierKey), true);
    storage.failDelete = null;
    service = make();
    expect(await verify('012345'), true);
  });

  test('legacy throttle imported with same absolute timestamp; secure state wins thereafter', () async {
    final at = clock.add(const Duration(minutes: 15)).toIso8601String();
    var cleaned = false;
    service = make(
      legacy: () => PinLockState(turn: 3, attempts: 2, unlockAt: at),
      cleanup: () async {
        cleaned = true;
      },
    );
    legacyPin();
    await service.initialize();
    expect(cleaned, true);
    expect(service.state.turn, 3);
    expect(service.state.attempts, 2);
    service = make(legacy: () => throw StateError('must not read old prefs'));
    await service.initialize();
    expect(service.state.unlockAt, at);
    expect(await verify('012345'), false);
    clock = clock.add(const Duration(minutes: 16));
    expect(await verify('012345'), true);
  });

  test('throttle import failure keeps old data; restart imports it', () async {
    var cleaned = false;
    storage.failWrite = PinAuthService.lockKey;
    service = make(
      legacy: () => const PinLockState(attempts: 2),
      cleanup: () async {
        cleaned = true;
      },
    );
    await expectLater(service.initialize(), authError);
    expect(cleaned, false);
    storage.failWrite = null;
    service = make(legacy: () => const PinLockState(attempts: 2));
    await service.initialize();
    expect(service.state.attempts, 2);
  });

  test('interrupted SharedPreferences removal leaves secure copy authoritative', () async {
    service = make(
      legacy: () => const PinLockState(attempts: 2),
      cleanup: () async {
        throw StateError('interrupted');
      },
    );
    await expectLater(service.initialize(), authError);
    service = make(legacy: () => throw StateError('stale preferences'));
    await service.initialize();
    expect(service.state.attempts, 2);
  });

  test('lock-state read/write errors cannot authenticate or reset limits', () async {
    legacyPin();
    await verify('999999');
    storage.failRead = PinAuthService.lockKey;
    await expectLater(verify('012345'), authError);
    await expectLater(service.reset(), authError);
    storage.failRead = null;
    storage.failWrite = PinAuthService.lockKey;
    await expectLater(verify('999999'), authError);
    expect(service.state.attempts, 1);
    await expectLater(verify('012345'), authError);
    storage.failWrite = null;
    service = make();
    await service.initialize();
    expect(service.state.attempts, 1);
  });

  test('missing/corrupt secure throttle with existing verifier never resets from preferences', () async {
    await service.savePin('012345', false);
    storage.values.remove(PinAuthService.lockKey);
    await expectLater(verify('012345'), authError);
    storage.values[PinAuthService.lockKey] = '{}';
    await expectLater(verify('012345'), authError);
  });

  test('concurrent verify, reset, change requests are rejected while KDF is running', () async {
    await service.savePin('012345', false);
    kdf.gate = Completer<void>();
    final pending = verify('999999');
    await Future<void>.delayed(Duration.zero);
    await expectLater(verify('999999'), authError);
    await expectLater(service.reset(), authError);
    await expectLater(service.savePin('654321', false), authError);
    kdf.gate!.complete();
    expect(await pending, false);
    expect(service.state.attempts, 1);
    service = make();
    await service.initialize();
    expect(service.state.attempts, 1);
  });

  test('production policy: 3 attempts per turn, original delays, 8th turn permanent', () async {
    expect(kMaxAttemptPerTurn, 3);
    expect(kMaxTurn, 8);
    expect(kLockoutDurationsPerTurn, [1, 5, 15, 30, 60, 180, 480, 600, -1]);
    legacyPin();
    for (var turn = 1; turn <= kMaxTurn; turn++) {
      for (var attempt = 1; attempt <= kMaxAttemptPerTurn; attempt++) {
        expect(await verify('999999'), false);
        expect(service.state.attempts, attempt % 3);
        expect(service.state.turn, attempt == 3 ? turn : turn - 1);
      }
      service = make();
      await service.initialize();
      if (turn < kMaxTurn) {
        final deadline = DateTime.parse(service.state.unlockAt);
        expect(deadline.difference(clock), Duration(minutes: kLockoutDurationsPerTurn[turn - 1]));
        expect(await verify('012345'), false);
        expect(service.state.turn, turn);
        clock = deadline.add(const Duration(milliseconds: 1));
      }
    }
    expect(service.state.unlockAt, '-1');
    clock = clock.add(const Duration(days: 365));
    expect(await verify('012345'), false);
    await service.disable(preservePermanentLock: true);
    service = make();
    await service.initialize();
    expect(service.state.turn, 8);
    expect(await service.hasPin(), false);
    await service.reset();
    expect(service.state.turn, 0);
  });

  test('debug policy stays seven seconds at each temporary turn', () async {
    service = make(debug: true);
    legacyPin();
    for (var turn = 1; turn < kMaxTurn; turn++) {
      for (var i = 0; i < 3; i++) {
        await verify('999999');
      }
      final deadline = DateTime.parse(service.state.unlockAt);
      expect(deadline.difference(clock), const Duration(seconds: 7));
      clock = deadline.add(const Duration(milliseconds: 1));
    }
  });

  test('non-launch failures do not count; successful PIN and biometric reset keep existing rules', () async {
    legacyPin();
    await verify('999999');
    for (var i = 0; i < 10; i++) {
      expect(await verify('999999', count: false), false);
    }
    expect(service.state.attempts, 1);
    expect(await verify('012345', count: false), true);
    expect(service.state.attempts, 0);
    await verify('999999');
    await service.reset();
    expect(service.state.attempts, 0);
  });

  test('owned PIN, salt and output buffers cleared on derive and verify completion', () async {
    await service.savePin('012345', false);
    expect(kdf.lastPin!.every((v) => v == 0), true);
    expect(kdf.lastSalt!.every((v) => v == 0), true);
    expect(kdf.lastOutput!.every((v) => v == 0), true);
    expect(await verify('012345'), true);
    expect(kdf.lastPin!.every((v) => v == 0), true);
  });

  test('storage exceptions expose only a fixed message', () async {
    storage.failRead = PinAuthService.lockKey;
    try {
      await service.initialize();
      fail('must reject');
    } catch (error) {
      expect(error.toString(), 'Authentication storage unavailable');
    }
  });

  test('actual Argon2id isolate uses wallet parameters and deterministic result', () async {
    const real = Argon2PinKdf();
    final salt = Uint8List.fromList(List.generate(16, (i) => i));
    final watch = Stopwatch()..start();
    final first = await real.derive(Uint8List.fromList(utf8.encode('012345')), salt, PinKdfParameters.current);
    final second = await real.derive(Uint8List.fromList(utf8.encode('012345')), salt, PinKdfParameters.current);
    expect(first, second);
    expect(first.length, 32);
    var uiTicked = false;
    final tick = Timer(Duration.zero, () => uiTicked = true);
    await real.derive(Uint8List.fromList(utf8.encode('012345')), salt, PinKdfParameters.current);
    expect(uiTicked, true);
    tick.cancel();
    debugPrint('Argon2id test host: three 19MiB derivations took ${watch.elapsedMilliseconds}ms');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('RFC 9106 Argon2id known-answer vector', () async {
    final result = await cryptography.Argon2id(memory: 32, iterations: 3, parallelism: 4, hashLength: 32).deriveKey(
      secretKey: cryptography.SecretKey(List.filled(32, 1)),
      nonce: List.filled(16, 2),
      optionalSecret: List.filled(8, 3),
      associatedData: List.filled(12, 4),
    );
    expect(
      (await result.extractBytes()).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
    );
    result.destroy();
  });

  test('Android barrier sends no authentication data and rejects failed/absent channel', () async {
    final calls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SecurePinAuthStorage.channel, (call) async {
      calls.add(call);
      return true;
    });
    await AndroidPinStorageBarrier.flush();
    expect(calls.single.method, 'flush');
    expect(calls.single.arguments, null);
    messenger.setMockMethodCallHandler(SecurePinAuthStorage.channel, (_) async => false);
    await expectLater(AndroidPinStorageBarrier.flush(), authError);
    messenger.setMockMethodCallHandler(
      SecurePinAuthStorage.channel,
      (_) async => throw PlatformException(code: 'test-only-secret'),
    );
    await expectLater(AndroidPinStorageBarrier.flush(), authError);
    messenger.setMockMethodCallHandler(SecurePinAuthStorage.channel, null);
    await expectLater(AndroidPinStorageBarrier.flush(), authError);
  });

  test('provider recovers secure PIN metadata before allowing authentication', () async {
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.hasShownStartGuide: true});
    await SharedPrefsRepository().init();
    await service.savePin('test-only-character-PIN', true);
    final provider = AuthProvider(pinAuth: service, initializeDeviceBiometrics: false);
    expect(provider.isUnlockAvailable, false);
    await provider.ready;
    expect(provider.authenticationUnavailable, false);
    expect(provider.isPinSet, true);
    expect(provider.isPinCharacter, true);
    expect(await provider.verifyPin('wrong', isAppLaunchScreen: false), false);
    expect(provider.currentAttemptInTurn, 0);
    expect(await provider.verifyPin('wrong', isAppLaunchScreen: true), false);
    expect(provider.currentAttemptInTurn, 1);
    provider.dispose();
  });
  test('actual SharedPreferences throttle is migrated and removed only after secure verification', () async {
    final deadline = clock.add(const Duration(hours: 1)).toIso8601String();
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.hasShownStartGuide: true,
      SharedPrefsKeys.kPinInputTurn: '5',
      SharedPrefsKeys.kPinInputCurrentAttemptCount: '2',
      SharedPrefsKeys.kUnlockAvailableAt: deadline,
    });
    await SharedPrefsRepository().init();
    service = PinAuthService(storage: storage, kdf: kdf, now: () => clock);
    await service.initialize();
    expect(service.state.turn, 5);
    expect(service.state.attempts, 2);
    expect(service.state.unlockAt, deadline);
    expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kPinInputTurn), false);
    expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kPinInputCurrentAttemptCount), false);
    expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kUnlockAvailableAt), false);
  });

  test('provider startup read failure never permits authentication', () async {
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.hasShownStartGuide: true});
    await SharedPrefsRepository().init();
    storage.failRead = PinAuthService.lockKey;
    final provider = AuthProvider(pinAuth: service, initializeDeviceBiometrics: false);
    await provider.ready;
    expect(provider.authenticationUnavailable, true);
    expect(provider.isUnlockAvailable, false);
    await expectLater(provider.verifyPin('012345'), authError);
    provider.dispose();
  });

  test('provider recovers committed disabled record over stale metadata', () async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.hasShownStartGuide: true,
      SharedPrefsKeys.isPinEnabled: true,
    });
    await SharedPrefsRepository().init();
    await service.savePin('012345', false);
    await service.disable();
    final provider = AuthProvider(pinAuth: service, initializeDeviceBiometrics: false);
    await provider.ready;
    expect(provider.isPinSet, false);
    expect(SharedPrefsRepository().getBool(SharedPrefsKeys.isPinEnabled), false);
    provider.dispose();
  });

  testWidgets('OS biometric success resets limits before callback without migrating legacy PIN', (tester) async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.hasShownStartGuide: true,
      SharedPrefsKeys.isPinEnabled: true,
      SharedPrefsKeys.isBiometricEnabled: true,
    });
    await SharedPrefsRepository().init();
    legacyPin();
    await verify('999999');
    final provider = AuthProvider(pinAuth: service, initializeDeviceBiometrics: false);
    await provider.ready;
    const channel = MethodChannel('plugins.flutter.io/local_auth');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'authenticate' ? true : false,
    );
    late BuildContext testContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    var callbackCount = 0;
    provider.onAuthenticationSuccess = () {
      expect(service.state.attempts, 0);
      expect(storage.values.containsKey(PinAuthService.verifierKey), false);
      callbackCount++;
    };
    await provider.verifyBiometric(testContext);
    expect(callbackCount, 1);
    expect(kdf.calls, 0);
    expect(storage.values.containsKey(SecureStorageKeys.kVaultPin), true);
    // Successful OS auth still cannot unlock if persisting the reset fails.
    storage.failWrite = PinAuthService.lockKey;
    await expectLater(provider.verifyBiometric(testContext), authError);
    expect(callbackCount, 1);
    AppLifecycleStateProvider().endAllOperations();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    provider.dispose();
  });
  test('full reset replaces corrupt lock and verifier without reading legacy state', () async {
    storage.values[PinAuthService.lockKey] = '{';
    storage.values[PinAuthService.verifierKey] = '{';
    legacyPin();
    service = make(legacy: () => throw StateError('damaged old preferences'));
    await expectLater(service.initialize(), authError);
    await expectLater(verify('012345'), authError);
    await expectLater(service.disable(), authError);
    await service.resetAfterWalletDeletion();
    expect(service.state.turn, 0);
    expect(service.state.attempts, 0);
    expect(await service.hasPin(), false);
    expect(storage.values.containsKey(SecureStorageKeys.kVaultPin), false);
    service = make();
    await service.initialize();
    expect(await service.hasPin(), false);
    await service.savePin('654321', false);
    expect(await verify('654321'), true);
  });

  test('full reset preserves permanent lock even when old lock record is corrupt', () async {
    storage.values[PinAuthService.lockKey] = '{}';
    await service.resetAfterWalletDeletion(preservePermanentLock: true);
    service = make();
    await service.initialize();
    expect(service.state.turn, kMaxTurn);
    expect(service.state.unlockAt, '-1');
    expect(await service.hasPin(), false);
  });

  test('failed full-reset write blocks authentication and permits explicit reset retry', () async {
    storage.values[PinAuthService.lockKey] = '{';
    storage.failWrite = PinAuthService.lockKey;
    await expectLater(service.resetAfterWalletDeletion(), authError);
    await expectLater(service.initialize(), authError);
    storage.failWrite = null;
    await service.resetAfterWalletDeletion();
    await service.initialize();
    expect(await service.hasPin(), false);
  });

  test('full reset cannot finish when replacement lock cannot be read back', () async {
    storage.failRead = PinAuthService.lockKey;
    await expectLater(service.resetAfterWalletDeletion(), authError);
    expect(storage.values.containsKey(PinAuthService.verifierKey), false);
    storage.failRead = null;
    await service.resetAfterWalletDeletion();
    await service.initialize();
    expect(service.state.turn, 0);
  });

  test('full reset stays exclusive with an in-flight PIN verification', () async {
    await service.savePin('012345', false);
    kdf.gate = Completer<void>();
    final pending = verify('999999');
    await Future<void>.delayed(Duration.zero);
    await expectLater(service.resetAfterWalletDeletion(), authError);
    kdf.gate!.complete();
    expect(await pending, false);
    expect(await service.hasPin(), true);
  });

  test('app resume Keychain check waits for PIN verification instead of reporting inaccessible storage', () async {
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.hasShownStartGuide: true});
    await SharedPrefsRepository().init();
    await service.savePin('012345', false);
    final provider = AuthProvider(pinAuth: service, initializeDeviceBiometrics: false);
    addTearDown(provider.dispose);
    await provider.ready;
    expect(provider.isPinSet, true);

    kdf.gate = Completer<void>();
    final verification = provider.verifyPin('012345', isAppLaunchScreen: true);
    await Future<void>.delayed(Duration.zero);
    // AppShell awaits ready again on resume, but it is already complete.
    await provider.ready;
    var checkCompleted = false;
    final check = SecureZoneManager().verifyIosKeychainValidity(pinAuth: service).then((valid) {
      checkCompleted = true;
      return valid;
    });
    await Future<void>.delayed(Duration.zero);
    expect(checkCompleted, false);
    kdf.gate!.complete();
    expect(await verification, true);
    expect(await check, true);
  });

  test('multiple PIN status reads wait without colliding with each other', () async {
    await service.savePin('012345', false);
    kdf.gate = Completer<void>();
    final verification = verify('999999');
    await Future<void>.delayed(Duration.zero);
    final reads = List.generate(3, (_) => service.hasPin());
    // Mutation requests still fail immediately; only status reads wait.
    await expectLater(verify('012345'), authError);
    kdf.gate!.complete();
    expect(await verification, false);
    expect(await Future.wait(reads), [true, true, true]);
  });

  test('waiting Keychain check still rejects uncertain state after a verification write failure', () async {
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.isPinEnabled: true});
    await SharedPrefsRepository().init();
    await service.savePin('012345', false);
    kdf.gate = Completer<void>();
    final verification = verify('012345');
    final failure = expectLater(verification, authError);
    await Future<void>.delayed(Duration.zero);
    final check = SecureZoneManager().verifyIosKeychainValidity(pinAuth: service);
    storage.failWrite = PinAuthService.lockKey;
    kdf.gate!.complete();
    await failure;
    expect(await check, false);
    await expectLater(service.hasPin(), authError);
  });

  test('waiting Keychain check still rejects actual verifier read failure', () async {
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.isPinEnabled: true});
    await SharedPrefsRepository().init();
    await service.savePin('012345', false);
    kdf.gate = Completer<void>();
    final verification = verify('012345');
    await Future<void>.delayed(Duration.zero);
    final check = SecureZoneManager().verifyIosKeychainValidity(pinAuth: service);
    storage.failRead = PinAuthService.verifierKey;
    kdf.gate!.complete();
    expect(await verification, true);
    expect(await check, false);
  });

  test('provider full reset recovers failed startup only after secure reset completes', () async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.hasShownStartGuide: true,
      SharedPrefsKeys.isPinEnabled: true,
      SharedPrefsKeys.isBiometricEnabled: true,
    });
    await SharedPrefsRepository().init();
    storage.values[PinAuthService.lockKey] = '{';
    final provider = AuthProvider(pinAuth: service, initializeDeviceBiometrics: false);
    await provider.ready;
    expect(provider.authenticationUnavailable, true);
    await expectLater(provider.resetCredentials(), authError);
    storage.failWrite = PinAuthService.verifierKey;
    await expectLater(provider.resetCredentials(afterWalletDeletion: true), authError);
    expect(provider.authenticationUnavailable, true);
    expect(provider.isPinSet, true);
    storage.failWrite = null;
    await provider.resetCredentials(afterWalletDeletion: true);
    expect(provider.authenticationUnavailable, false);
    expect(provider.isPinSet, false);
    expect(provider.isBiometricEnabled, false);
    expect(SharedPrefsRepository().getBool(SharedPrefsKeys.isPinEnabled), false);
    provider.dispose();
  });
}
