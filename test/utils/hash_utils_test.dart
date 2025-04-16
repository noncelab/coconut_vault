import 'package:coconut_vault/utils/hash_util.dart';
import 'package:test/test.dart';

void main() {
  group('hashString', () {
    test('hashes a string correctly', () {
      const input = "hello";
      const expectedHash = "5d41402abc4b2a76b9719d911017c592"; // "hello"의 MD5 해시 값 (예시)

      // SHA-256 해시 결과
      const sha256ExpectedHash = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824";

      expect(hashString(input), equals(sha256ExpectedHash));
    });

    test('produces different hashes for different inputs', () {
      final hash1 = hashString("hello");
      final hash2 = hashString("world");

      expect(hash1, isNot(equals(hash2)));
    });

    test('produces consistent hash for the same input', () {
      const input = "testInput";
      final hash1 = hashString(input);
      final hash2 = hashString(input);

      expect(hash1, equals(hash2));
    });

    test('handles empty input', () {
      final hash = hashString("");
      const expectedHash =
          "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"; // SHA-256 해시 값

      expect(hash, equals(expectedHash));
    });
  });
}
