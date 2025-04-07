import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecureKeyGenerator {
  /// 암호학적으로 안전한 랜덤 바이트 생성
  static Uint8List generateSecureRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256); // 0 ~ 255 사이의 랜덤 값 저장
    }
    return bytes;
  }

  /// 안전한 키 생성 (Base64 인코딩)
  static String generateSecureKey({int lengthInBytes = 32}) {
    final bytes = generateSecureRandomBytes(lengthInBytes);
    return base64Url.encode(bytes);
  }

  /// 추가 엔트로피를 포함한 키 생성
  static String generateSecureKeyWithEntropy({
    int lengthInBytes = 32,
    String? additionalData,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomBytes = generateSecureRandomBytes(lengthInBytes);

    // 추가 엔트로피 소스들을 결합
    final entropy = utf8.encode(timestamp) +
        randomBytes +
        (additionalData != null ? utf8.encode(additionalData) : []);

    // SHA-256을 사용하여 해시
    final hash = sha256.convert(entropy);

    return base64.encode(hash.bytes);
  }
}
