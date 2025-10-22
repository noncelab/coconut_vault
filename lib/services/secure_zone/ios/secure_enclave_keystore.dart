import 'package:coconut_vault/services/secure_zone/secure_zone_keystore.dart';
import 'package:flutter/services.dart';

/// iOS only
class SecureEnclaveKeystore extends SecureZoneKeystore {
  /// 키 생성 (이미 있으면 재생성 여부 옵션 등은 플랫폼에서 조정)
  /// [alias] 키 별칭, [userAuthRequired] 사용자 인증 요구 여부
  @override
  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false}) async {
    if (perUseAuth) {
      throw 'perUseAuth is not supported on iOS';
    }

    await ch.invokeMethod('generateKey', {'alias': alias, 'userAuthRequired': userAuthRequired});
  }

  @override
  Future<void> deleteKey({required String alias}) async {
    await ch.invokeMethod<void>('deleteKey', {'alias': alias});
  }

  @override
  Future<void> deleteKeys({required List<String> aliasList}) async {
    await ch.invokeMethod<void>('deleteKeys', {'aliasList': aliasList});
  }

  Future<Map<String, dynamic>> _encrypt({required String alias, required Uint8List plaintext}) async {
    final r = await ch.invokeMethod<Map>('encrypt', {'alias': alias, 'plaintext': plaintext});
    if (r == null) throw "Failed to encrypt";

    return {'ciphertext': r['ciphertext'] as Uint8List, 'iv': Uint8List(0)};
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
    } on PlatformException catch (_) {
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
    } on PlatformException catch (_) {
      rethrow;
    }
  }
}
