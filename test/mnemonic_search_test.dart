import 'package:flutter_test/flutter_test.dart';
import 'package:coconut_vault/screens/settings/mnemonic_word_list_screen.dart';
void main() {
  group('mnemonic search', () {
    group('십진법 검색', () {
      final numericTests = {
        '0': 'abandon',
        '1': 'ability',
        '10': 'access',
        '616': 'escape',
      };

      numericTests.forEach((input, expected) {
        test('$input 검색 → $expected', () {
          final result = MnemonicWordListScreenState.queryWord(input);
          expect(result.first['item'], expected);
          expect(result.first['type'], 'numeric');
        });
      });
    });

    group('영문 검색', () {
      final alphaTests = {
        'test': 'test',
        'royal': 'royal',
      };

      alphaTests.forEach((input, expected) {
        test('$input 검색 → $expected', () {
          final result = MnemonicWordListScreenState.queryWord(input);
          expect(result.first['item'], expected);
          expect(result.first['type'], 'alphabetic');
        });
      });
    });

    group('이진법 검색', () {
      final binaryTests = {
        '01010101010': 'fetch',
        '01001101000': 'escape',
      };

      binaryTests.forEach((input, expected) {
        test('$input 검색 → $expected', () {
          final result = MnemonicWordListScreenState.queryWord(input);
          expect(result.first['item'], expected);
          expect(result.first['type'], 'binary');
        });
      });
    });
  });
}