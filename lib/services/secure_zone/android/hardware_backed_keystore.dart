import 'dart:io';

import 'package:coconut_vault/constants/method_channel.dart';
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
      autoAuth: isAutoAuthWhenNeeded,
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
    bool autoAuth = true,
  }) async {
    return await _executeWithAuth(
      operation: () => _decrypt(alias: alias, ciphertext: ciphertext, iv: iv),
      autoAuth: autoAuth,
    );
  }

  /// 인증이 필요한 작업을 실행하고, 필요 시 자동으로 인증 후 재시도
  Future<T> _executeWithAuth<T>({required Future<T> Function() operation, required bool autoAuth}) async {
    try {
      return await operation();
    } on PlatformException catch (e) {
      if (e.code != 'AUTH_NEEDED' || !autoAuth) {
        rethrow;
      }

      if (!await _authenticate()) {
        throw UserCanceledAuthException();
      }

      try {
        return await operation();
      } on PlatformException catch (e) {
        if (Platform.isIOS || e.code != 'AUTH_NEEDED' || !autoAuth) {
          rethrow;
        }

        // 삼성 휴대폰 One UI 8 (Android 16 / API level 36) 미만 기기에서
        // **보안 폴더 내부** 에서 앱 실행 시 앱에서 설정한 300초 유효시간 만료 후
        // "생체인증(Face/Fingerprint)"으로 인증 시 갱신 실패
        // 하지만 "PIN/Pattern/Password"으로 인증 시에는 갱신 성공
        // 따라서 "PIN/Pattern/Password"으로 인증을 한번 더 요청
        // 삼성에서 보안 폴더는 Android 13 (API level 33) 이상부터 제공
        if (!await _authenticateWithDeviceCredential()) {
          throw UserCanceledAuthException();
        }

        return await operation();
      }
    }
  }

  Future<bool> _authenticate() async {
    return await ch.invokeMethod<bool>('authenticateForKeystore', {
          'title': t.permission.secure_zone_authentication.title,
          'description': t.permission.secure_zone_authentication.description,
        }) ??
        false;
  }

  /// Authenticate using device credentials on Android.
  ///
  /// - API >= 30 (R): 30(API R) 이상에서는 `BiometricPrompt` `DEVICE_CREDENTIAL`옵션으로 사용 가능
  /// - API < 30: 30(API R) 미만에서는 기존의 `authenticateForKeystore` 사용하되 반드시 PIN/Pattern/Password로 인증하라고 안내 문구를 변경
  ///             (삼성 휴대폰 One UI 8 (Android 16 / API level 36) 미만 기기에서 "보안 폴더 내"에서 생체인증 시 인증 갱신이 안되기 때문)
  ///
  /// See `HardwareBackedKeystorePlugin.kt` for the native implementation details.
  Future<bool> _authenticateWithDeviceCredential() async {
    assert(Platform.isAndroid);

    return await ch.invokeMethod<bool>('authenticateWithDeviceCredential', {
          'title': t.permission.secure_zone_authentication.title,
          'descriptionAbove30': t.permission.secure_zone_authentication.description,
          'descriptionUnder30': t.permission.android_security_folder_auth.description,
        }) ??
        false;
  }
}
