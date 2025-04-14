import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:coconut_vault/utils/secure_key_generator.dart';

void main() {
  group('SecureKeyGenerator Tests', () {
    test('Generated key should have correct length and be Base64 encoded', () {
      final key = SecureKeyGenerator.generateSecureKeyWithEntropy();

      // Base64로 디코딩했을 때 32바이트(256비트)여야 함
      final decoded = base64.decode(key);
      expect(decoded.length, equals(32),
          reason: 'Decoded key should be 32 bytes');

      // 원본 문자열이 올바른 Base64 형식이어야 함
      expect(() => base64.decode(key), returnsNormally);
    });

    test('Generated keys should be unique', () {
      const iterations = 1000;
      final Set<String> keys = {};

      // 1000개의 키를 생성하고 모두 유니크한지 확인
      for (var i = 0; i < iterations; i++) {
        final key = SecureKeyGenerator.generateSecureKeyWithEntropy();
        expect(keys.contains(key), isFalse,
            reason: 'Generated key should be unique');
        keys.add(key);
      }

      expect(keys.length, equals(iterations),
          reason: 'All generated keys should be unique');
    });

    test('Generated keys should have sufficient entropy', () {
      const iterations = 100;
      final List<List<int>> keyBytes = [];

      // 100개의 키를 생성하고 바이트 분포 확인
      for (var i = 0; i < iterations; i++) {
        final key = SecureKeyGenerator.generateSecureKeyWithEntropy();
        final decoded = base64.decode(key);
        keyBytes.add(decoded);
      }

      // 각 바이트 위치에서의 값들이 충분히 다양한지 확인
      for (var pos = 0; pos < 32; pos++) {
        final Set<int> uniqueValues = {};
        for (var key in keyBytes) {
          uniqueValues.add(key[pos]);
        }

        // 각 위치에서 최소 20개 이상의 서로 다른 값이 나와야 함
        // (완벽한 랜덤이라면 더 많이 나와야 하지만, 테스트의 안정성을 위해 낮게 설정)
        expect(uniqueValues.length, greaterThan(20),
            reason: 'Byte at position $pos should have sufficient variation');
      }
    });

    test('Generated keys should be valid for AES-256', () {
      final key = SecureKeyGenerator.generateSecureKeyWithEntropy();
      final decoded = base64.decode(key);

      // AES-256에 사용되는 키는 32바이트여야 함
      expect(decoded.length, equals(32));

      // 모든 바이트가 0이 아니어야 함
      expect(decoded.every((byte) => byte == 0), isFalse,
          reason: 'Key should not be all zeros');

      // 모든 바이트가 같은 값이 아니어야 함
      expect(decoded.toSet().length, greaterThan(1),
          reason: 'Key should not have all same values');
    });
  });
}
