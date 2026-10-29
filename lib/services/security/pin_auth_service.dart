import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pin_kdf.dart';
export 'pin_kdf.dart';

/// Implementations must not log authentication values or underlying exceptions.
abstract interface class PinAuthStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecurePinAuthStorage implements PinAuthStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: SecureStorageRepository.androidOptions,
    iOptions: SecureStorageRepository.iosOptions,
  );
  static const channel = MethodChannel('onl.coconut.vault/pin_auth_storage');
  Future<void> _flush() async {
    if (Platform.isAndroid) await AndroidPinStorageBarrier.flush();
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) async {
    // Never delete an existing authentication record to retry a write.
    await _storage.write(key: key, value: value);
    await _flush();
  }

  @override
  Future<void> delete(String key) async {
    await SecureStorageRepository().delete(key: key);
    await _flush();
  }
}

class AndroidPinStorageBarrier {
  static Future<void> flush() async {
    try {
      if (await SecurePinAuthStorage.channel.invokeMethod<bool>('flush') != true) {
        throw const PinAuthException();
      }
    } catch (_) {
      throw const PinAuthException();
    }
  }
}

class PinAuthException implements Exception {
  const PinAuthException();
  @override
  String toString() => 'Authentication storage unavailable';
}

class PinLockState {
  final int turn;
  final int attempts;
  final String unlockAt;
  const PinLockState({this.turn = 0, this.attempts = 0, this.unlockAt = ''});
  Map<String, dynamic> toJson() => {'version': 1, 'turn': turn, 'attempts': attempts, 'unlockAt': unlockAt};
  static PinLockState parse(Map<String, dynamic> value) {
    final turn = value['turn'];
    final attempts = value['attempts'];
    final at = value['unlockAt'];
    if (value['version'] != 1 ||
        turn is! int ||
        turn < 0 ||
        turn > kMaxTurn ||
        attempts is! int ||
        attempts < 0 ||
        attempts >= kMaxAttemptPerTurn ||
        at is! String ||
        (at.isNotEmpty && at != '-1' && DateTime.tryParse(at) == null) ||
        (turn > 0 && turn < kMaxTurn && at.isEmpty)) {
      throw const PinAuthException();
    }
    return PinLockState(turn: turn, attempts: attempts, unlockAt: at);
  }
}

/// One shared instance serializes all authentication mutations in the app isolate.
/// A present verifier record is authoritative, including malformed records.
class PinAuthService {
  static const verifierKey = 'vault_pin_verifier_v1';
  static const lockKey = 'vault_pin_lock_v1';
  static final instance = PinAuthService();
  final PinAuthStorage storage;
  final PinKdf kdf;
  final DateTime Function() now;
  final bool debugDelay;
  final PinLockState Function()? legacyState;
  final Future<void> Function() removeLegacyState;
  bool _busy = false;
  Completer<void>? _operationCompleted;
  bool _uncertain = false;
  PinLockState state = const PinLockState();

  PinAuthService({
    PinAuthStorage? storage,
    PinKdf? kdf,
    DateTime Function()? now,
    this.debugDelay = kDebugMode,
    this.legacyState,
    Future<void> Function()? removeLegacyState,
  }) : storage = storage ?? SecurePinAuthStorage(),
       kdf = kdf ?? const Argon2PinKdf(),
       now = now ?? DateTime.now,
       removeLegacyState = removeLegacyState ?? _removeLegacyState;

  PinLockState _readLegacyState() {
    final prefs = SharedPrefsRepository();
    // Older releases wrote these fields separately. Normalize only this legacy
    // input; committed secure records must still pass PinLockState.parse.
    String read(String key) => prefs.sharedPrefs.get(key)?.toString() ?? '';
    final rawTurn = read(SharedPrefsKeys.kPinInputTurn);
    final rawAttempts = read(SharedPrefsKeys.kPinInputCurrentAttemptCount);
    final rawAt = read(SharedPrefsKeys.kUnlockAvailableAt);
    final parsedTurn = int.tryParse(rawTurn);
    final parsedAttempts = int.tryParse(rawAttempts);
    var turn = (parsedTurn ?? 0).clamp(0, kMaxTurn);
    var attempts = max(0, parsedAttempts ?? 0);
    final overflow = attempts ~/ kMaxAttemptPerTurn;
    turn = min(kMaxTurn, turn + overflow);
    attempts %= kMaxAttemptPerTurn;

    // Preserve permanent locks even when their companion field was not saved.
    if (turn == kMaxTurn || rawAt == '-1') {
      return const PinLockState(turn: kMaxTurn, unlockAt: '-1');
    }
    final malformedCounter =
        (rawTurn.isNotEmpty && (parsedTurn == null || parsedTurn < 0)) ||
        (rawAttempts.isNotEmpty && (parsedAttempts == null || parsedAttempts < 0));
    final deadline = DateTime.tryParse(rawAt);
    final needsDeadline =
        overflow > 0 || malformedCounter || (turn > 0 && deadline == null) || (rawAt.isNotEmpty && deadline == null);
    if (needsDeadline) {
      turn = max(1, turn);
      final reconstructed = now().add(_lockoutDuration(turn));
      // Never shorten an already persisted future deadline.
      final at = deadline != null && deadline.isAfter(reconstructed) ? rawAt : reconstructed.toIso8601String();
      return PinLockState(turn: turn, attempts: attempts, unlockAt: at);
    }
    return PinLockState(turn: turn, attempts: attempts, unlockAt: rawAt);
  }

  Duration _lockoutDuration(int turn) =>
      debugDelay ? const Duration(seconds: kDebugPinInputDelay) : Duration(minutes: kLockoutDurationsPerTurn[turn - 1]);

  static Future<void> _removeLegacyState() async {
    for (final key in [
      SharedPrefsKeys.kPinInputTurn,
      SharedPrefsKeys.kPinInputCurrentAttemptCount,
      SharedPrefsKeys.kUnlockAvailableAt,
    ]) {
      final prefs = SharedPrefsRepository().sharedPrefs;
      if (prefs.containsKey(key) && !await prefs.remove(key)) throw const PinAuthException();
    }
  }

  Future<T> _exclusive<T>(
    Future<T> Function() action, {
    bool allowUncertain = false,
    bool waitForOperation = false,
  }) async {
    // Lifecycle status reads must observe the committed authentication state,
    // rather than mistake an in-flight verification for unavailable storage.
    // Recheck after waking: another operation may have acquired the lock first.
    while (waitForOperation && _busy) {
      await _operationCompleted!.future;
    }
    if (_busy || (_uncertain && !allowUncertain)) throw const PinAuthException();
    _busy = true;
    final completed = _operationCompleted = Completer<void>();
    try {
      return await action();
    } catch (_) {
      throw const PinAuthException();
    } finally {
      _busy = false;
      _operationCompleted = null;
      // Signal completion even on failure. Waiting reads check _uncertain and
      // perform their own storage validation after acquiring the lock.
      completed.complete();
    }
  }

  Future<void> _save(String key, Map<String, dynamic> value) async {
    final raw = jsonEncode(value);
    try {
      await storage.write(key, raw);
      if (await storage.read(key) != raw) throw const PinAuthException();
    } catch (_) {
      // The write may have reached disk. Require restart before further operations.
      _uncertain = true;
      throw const PinAuthException();
    }
  }

  Map<String, dynamic> _decode(String raw) {
    if (raw.length > 4096) throw const PinAuthException();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _loadState() async {
    final raw = await storage.read(lockKey);
    if (raw != null) {
      state = PinLockState.parse(_decode(raw));
    } else {
      if (await storage.read(verifierKey) != null) throw const PinAuthException();
      final imported = legacyState?.call() ?? _readLegacyState();
      await _save(lockKey, imported.toJson());
      state = imported;
      await removeLegacyState();
    }
  }

  Future<void> _setState(PinLockState next) async {
    await _save(lockKey, next.toJson());
    state = next;
  }

  /// Returns secure metadata; null means a legacy or unset PIN.
  Future<Map<String, dynamic>?> initialize() => _exclusive(() async {
    await _loadState();
    // Retry cleanup if the previous run stopped after saving the secure copy.
    await removeLegacyState();
    final record = await _verifier();
    return record;
  });
  Future<bool> hasPin() => _exclusive(() async {
    final record = await _verifier();
    return record == null ? await storage.read(SecureStorageKeys.kVaultPin) != null : record['disabled'] != true;
  }, waitForOperation: true);

  Future<Map<String, dynamic>?> _verifier() async {
    final raw = await storage.read(verifierKey);
    if (raw == null) return null;
    final v = _decode(raw);
    if (v['version'] != 1) throw const PinAuthException();
    if (v.containsKey('disabled')) {
      if (v['disabled'] == true && v.length == 2) return v;
      throw const PinAuthException();
    }
    if (v['algorithm'] != 'argon2id' ||
        v['argonVersion'] != 19 ||
        v['memory'] != 19456 ||
        v['iterations'] != 2 ||
        v['parallelism'] != 1 ||
        v['character'] is! bool ||
        v['salt'] is! String ||
        v['verifier'] is! String ||
        base64Decode(v['salt'] as String).length != 16 ||
        base64Decode(v['verifier'] as String).length != 32) {
      throw const PinAuthException();
    }
    return v;
  }

  Future<Map<String, dynamic>> _create(String pin, bool character) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    final bytes = Uint8List.fromList(utf8.encode(pin));
    Uint8List? hash;
    try {
      hash = await kdf.derive(bytes, salt, PinKdfParameters.current);
      return {
        'version': 1,
        'algorithm': 'argon2id',
        'argonVersion': 19,
        'memory': 19456,
        'iterations': 2,
        'parallelism': 1,
        'character': character,
        'salt': base64Encode(salt),
        'verifier': base64Encode(hash),
      };
    } finally {
      bytes.fillRange(0, bytes.length, 0);
      salt.fillRange(0, salt.length, 0);
      hash?.fillRange(0, hash.length, 0);
    }
  }

  bool _equals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    for (var i = 0; i < min(a.length, b.length); i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<bool> verify(String pin, {required bool countFailure, required bool character}) => _exclusive(() async {
    await _loadState();
    if (countFailure &&
        (state.turn == kMaxTurn ||
            (state.unlockAt.isNotEmpty && !(DateTime.tryParse(state.unlockAt)?.isBefore(now()) ?? false)))) {
      return false;
    }
    final record = await _verifier();
    bool valid;
    if (record == null) {
      final legacy = await storage.read(SecureStorageKeys.kVaultPin);
      if (legacy == null) return false;
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(legacy)) throw const PinAuthException();
      valid = _equals(utf8.encode(hashString(pin)), utf8.encode(legacy));
    } else if (record['disabled'] == true) {
      return false;
    } else {
      final bytes = Uint8List.fromList(utf8.encode(pin));
      final salt = base64Decode(record['salt'] as String);
      Uint8List? actual;
      try {
        actual = await kdf.derive(bytes, salt, PinKdfParameters.current);
        valid = _equals(actual, base64Decode(record['verifier'] as String));
      } finally {
        bytes.fillRange(0, bytes.length, 0);
        salt.fillRange(0, salt.length, 0);
        actual?.fillRange(0, actual.length, 0);
      }
    }
    if (valid) {
      if (record == null) await _save(verifierKey, await _create(pin, character));
      // Only remove SHA-256 after a new record has been saved and read back.
      await storage.delete(SecureStorageKeys.kVaultPin);
      await _setState(const PinLockState());
    } else if (countFailure) {
      await _increase();
    }
    return valid;
  });

  Future<void> savePin(String pin, bool character) => _exclusive(() async {
    await _loadState();
    await _verifier(); // Never overwrite a corrupt record through normal PIN setup.
    await _save(verifierKey, await _create(pin, character));
    await storage.delete(SecureStorageKeys.kVaultPin);
  });
  Future<void> _increase() async {
    if (state.turn == kMaxTurn) return;
    var attempts = state.attempts + 1;
    var turn = state.turn;
    var at = state.unlockAt;
    if (attempts == kMaxAttemptPerTurn) {
      attempts = 0;
      turn++;
      at = turn == kMaxTurn ? '-1' : now().add(_lockoutDuration(turn)).toIso8601String();
    }
    await _setState(PinLockState(turn: turn, attempts: attempts, unlockAt: at));
  }

  Future<void> increase() => _exclusive(() async {
    await _loadState();
    await _increase();
  });
  Future<void> reset({bool preservePermanentLock = false}) => _exclusive(() async {
    await _loadState();
    await _verifier();
    await _setState(
      preservePermanentLock && state.turn == kMaxTurn
          ? const PinLockState(turn: kMaxTurn, unlockAt: '-1')
          : const PinLockState(),
    );
  });

  /// Only after the explicit full-reset flow has deleted wallet data. Never
  /// restore authentication from a damaged old record to complete this reset.
  Future<void> resetAfterWalletDeletion({bool preservePermanentLock = false}) => _exclusive(() async {
    await storage.delete(SecureStorageKeys.kVaultPin);
    if (await storage.read(SecureStorageKeys.kVaultPin) != null) throw const PinAuthException();
    await _setState(preservePermanentLock ? const PinLockState(turn: kMaxTurn, unlockAt: '-1') : const PinLockState());
    await _save(verifierKey, {'version': 1, 'disabled': true});
    await removeLegacyState();
    // A failed reset can be retried, but normal authentication remains blocked
    // until every replacement record has been persisted and checked.
    _uncertain = false;
  }, allowUncertain: true);

  Future<void> disable({bool preservePermanentLock = false}) => _exclusive(() async {
    await _loadState();
    await storage.delete(SecureStorageKeys.kVaultPin);
    await _save(verifierKey, {'version': 1, 'disabled': true});
    await _setState(
      preservePermanentLock && state.turn == kMaxTurn
          ? const PinLockState(turn: kMaxTurn, unlockAt: '-1')
          : const PinLockState(),
    );
  });
}
