import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';

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
    return base64.encode(bytes);
  }

  /// 추가 엔트로피를 포함한 키 생성
  static String generateSecureKeyWithEntropy({
    int lengthInBytes = 32,
    String? additionalData,
  }) {
    final randomBytes = generateSecureRandomBytes(lengthInBytes);
    final entropy = randomBytes + (additionalData != null ? utf8.encode(additionalData) : []);

    // PBKDF2 사용하여 키 스트레칭
    final salt = generateSecureRandomBytes(16); // 랜덤 솔트
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 10000, lengthInBytes));

    final key = pbkdf2.process(Uint8List.fromList(entropy));
    return base64.encode(key);
  }
}
