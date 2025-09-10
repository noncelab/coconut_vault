import 'package:flutter_test/flutter_test.dart';
import 'package:encrypt/encrypt.dart';
import 'package:coconut_vault/utils/aes_crypto.dart';
import 'package:coconut_vault/utils/secure_key_generator.dart';

void main() {
  group('AesCrypto Tests', () {
    test('암호화 후 복호화 테스트 - 한글 포함', () {
      // 테스트할 데이터
      const originalData = '안녕하세요! Hello, World! 12345 !@#\$%^&*()';

      // 랜덤 키 생성 (32바이트)
      final randomString = SecureKeyGenerator.generateSecureKeyWithEntropy(additionalData: 'test');
      final key = Key.fromBase64(randomString);

      // 랜덤 IV 생성 및 암호화
      final iv = Aes256Crypto.generateIv();
      final encrypted = Aes256Crypto.encryptCbc(
        data: originalData,
        key: key,
        iv: iv,
      );

      // IV와 암호문 결합 (IV + 암호문)
      final combinedData = String.fromCharCodes(iv.bytes) + encrypted;

      // 결합된 데이터 복호화
      final decrypted = Aes256Crypto.decryptWithCombinedIv(
        combinedData: combinedData,
        key: key,
      );

      // 원본 데이터와 복호화된 데이터 비교
      expect(decrypted, equals(originalData));
    });

    test('암호화 후 복호화 테스트 - 긴 문자열', () {
      // 긴 테스트 데이터 생성
      final originalData = List.generate(1000, (index) => 'Test데이터$index').join();

      // 랜덤 키 생성 (32바이트)
      final randomString = SecureKeyGenerator.generateSecureKeyWithEntropy(additionalData: 'test');
      final key = Key.fromBase64(randomString);

      // 암호화
      final iv = Aes256Crypto.generateIv();
      final encrypted = Aes256Crypto.encryptCbc(
        data: originalData,
        key: key,
        iv: iv,
      );

      // IV와 암호문 결합
      final combinedData = String.fromCharCodes(iv.bytes) + encrypted;

      // 복호화
      final decrypted = Aes256Crypto.decryptWithCombinedIv(
        combinedData: combinedData,
        key: key,
      );

      // 검증
      expect(decrypted, equals(originalData));
    });

    test('다른 키로 복호화 시도 시 실패 테스트', () {
      const originalData = 'Secret Message';

      // 첫 번째 키로 암호화
      // 랜덤 키 생성 (32바이트)
      final randomString = SecureKeyGenerator.generateSecureKeyWithEntropy(additionalData: 'test');
      final key1 = Key.fromBase64(randomString);
      final iv = Aes256Crypto.generateIv();
      final encrypted = Aes256Crypto.encryptCbc(
        data: originalData,
        key: key1,
        iv: iv,
      );

      // IV와 암호문 결합
      final combinedData = String.fromCharCodes(iv.bytes) + encrypted;

      // 다른 키로 복호화 시도
      final key2 = Key.fromSecureRandom(32);

      // 다른 키로 복호화 시도 시 패딩 오류가 발생해야 함
      expect(
        () => Aes256Crypto.decryptWithCombinedIv(
          combinedData: combinedData,
          key: key2,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Invalid or corrupted pad block',
          ),
        ),
      );
    });
  });
}
