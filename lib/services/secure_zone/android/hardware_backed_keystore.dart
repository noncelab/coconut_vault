import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_keystore.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/services.dart';

/// Android only
class HardwareBackedKeystore extends SecureZoneKeystore {
  /// 키 생성 (이미 있으면 재생성 여부 옵션 등은 플랫폼에서 조정)
  /// [alias] 키 별칭, [userAuthRequired] 사용자 인증 요구 여부
  /// [perUseAuth] true면 매 사용마다 인증(ValidityDurationSeconds = -1)
  @override
  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false}) async {
    await ch.invokeMethod<Map>('generateKey', {
      'alias': alias,
      'userAuthRequired': userAuthRequired,
      'perUseAuth': perUseAuth,
    });
  }

  @override
  Future<void> deleteKey({required String alias}) async {
    await ch.invokeMethod('deleteKey', {'alias': alias});
  }

  @override
  Future<void> deleteKeys({required List<String> aliasList}) async {
    await ch.invokeMethod<void>('deleteKeys', {'aliasList': aliasList});
  }

  Future<Map<String, dynamic>> _encrypt({required String alias, required Uint8List plaintext}) async {
    final r = await ch.invokeMethod<Map>('encrypt', {'alias': alias, 'plaintext': plaintext});
    if (r == null) throw "Failed to encrypt";

    return {
      'ciphertext': r['ciphertext'] as Uint8List,
      'iv': r['iv'] as Uint8List,
      'usedStrongBox': r['usedStrongBox'] == true,
    };
  }

  /// AES-GCM 암호화 (플랫폼에서 IV 생성 후 함께 반환)
  @override
  Future<Map<String, dynamic>> encrypt({
    required String alias,
    required Uint8List plaintext,
    bool isAutoAuthWhenNeeded = true,
  }) async {
    return await _executeWithAuth(
      operation: () => _encrypt(alias: alias, plaintext: plaintext),
      isAutoAuthWhenNeeded: isAutoAuthWhenNeeded,
    );
  }

  Future<Uint8List?> _decrypt({required String alias, required Uint8List ciphertext, required Uint8List iv}) async {
    try {
      final r = await ch.invokeMethod<Uint8List>('decrypt', {'alias': alias, 'ciphertext': ciphertext, 'iv': iv});

      if (r == null) return null;

      return r;
    } catch (e) {
      Logger.error(e);
      rethrow;
    }
  }

  /// AES-GCM 복호화
  @override
  Future<Uint8List?> decrypt({
    required String alias,
    required Uint8List ciphertext,
    required Uint8List iv,
    bool isAutoAuthWhenNeeded = true,
  }) async {
    return await _executeWithAuth(
      operation: () => _decrypt(alias: alias, ciphertext: ciphertext, iv: iv),
      isAutoAuthWhenNeeded: isAutoAuthWhenNeeded,
    );
  }

  /// 인증이 필요한 작업을 실행하고, 필요 시 자동으로 인증 후 재시도
  Future<T> _executeWithAuth<T>({required Future<T> Function() operation, required bool isAutoAuthWhenNeeded}) async {
    try {
      return await operation();
    } on PlatformException catch (e) {
      if (e.code != 'AUTH_NEEDED' || !isAutoAuthWhenNeeded) {
        rethrow;
      }

      // 첫 번째 인증 시도
      if (!await _authenticate()) {
        throw UserCanceledAuthException();
      }

      return await operation();
    }
  }

  Future<bool> _authenticate() async {
    return await ch.invokeMethod<bool>('authenticateForKeystore', {
          'title': t.permission.secure_zone_authentication.title,
          'description': t.permission.secure_zone_authentication.description,
        }) ??
        false;
  }
}
