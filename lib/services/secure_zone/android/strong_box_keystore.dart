import 'dart:io';

import 'package:coconut_vault/services/secure_zone/secure_zone_keystore.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Android only
class StrongBoxKeystore extends SecureZoneKeystore {
  /// 단말이 StrongBox(하드웨어 SE)를 지원하는지
  Future<bool> isStrongBoxSupported() async {
    assert(Platform.isAndroid);
    final r = await ch.invokeMethod<bool>('isStrongBoxSupported');
    return r ?? false;
  }

  /// 키 생성 (이미 있으면 재생성 여부 옵션 등은 플랫폼에서 조정)
  /// [alias] 키 별칭, [userAuthRequired] 사용자 인증 요구 여부
  /// [perUseAuth] true면 매 사용마다 인증(ValidityDurationSeconds = -1)
  @override
  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false}) async {
    await ch.invokeMethod('generateKey', {
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
    try {
      return await _encrypt(alias: alias, plaintext: plaintext);
    } on PlatformException catch (e) {
      if (e.code == 'AUTH_NEEDED' && isAutoAuthWhenNeeded) {
        final authenticated = await LocalAuthentication().authenticate(
          // TODO: localizedReason
          localizedReason: '인증을 위해 휴대폰의 화면 잠금을 해제해주세요.',
          options: const AuthenticationOptions(stickyAuth: true),
        );

        if (authenticated) {
          return _encrypt(alias: alias, plaintext: plaintext);
        }
      } else if (e.code == 'KEY_INVALIDATED') {
        // TODO: UI/UX
      }

      rethrow;
    }
  }

  Future<Uint8List?> _decrypt({required String alias, required Uint8List ciphertext, required Uint8List iv}) async {
    final r = await ch.invokeMethod<Uint8List>('decrypt', {'alias': alias, 'ciphertext': ciphertext, 'iv': iv});

    if (r == null) return null;

    return r;
  }

  /// AES-GCM 복호화
  @override
  Future<Uint8List?> decrypt({
    required String alias,
    required Uint8List ciphertext,
    required Uint8List iv,
    bool isAutoAuthWhenNeeded = true,
  }) async {
    try {
      return await _decrypt(alias: alias, ciphertext: ciphertext, iv: iv);
    } on PlatformException catch (e) {
      // TODO: e.code == 'KEY_INVALIDATED'
      if (e.code == 'AUTH_NEEDED' && isAutoAuthWhenNeeded) {
        final authenticated = await LocalAuthentication().authenticate(
          // TODO: localizedReason
          localizedReason: '인증을 위해 휴대폰의 화면 잠금을 해제해주세요.',
          options: const AuthenticationOptions(stickyAuth: true),
        );

        if (authenticated) {
          return _decrypt(alias: alias, ciphertext: ciphertext, iv: iv);
        }
      } else if (e.code == 'KEY_INVALIDATED') {
        // TODO: UI/UX
      }

      rethrow;
    }
  }
}
