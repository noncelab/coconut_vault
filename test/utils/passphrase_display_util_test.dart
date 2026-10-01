import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/utils/nfkd_util.dart';
import 'package:coconut_vault/utils/passphrase_display_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PassphraseDisplayUtil.displayCharacters', () {
    test('NFKD로 분해된 한글은 입력한 음절 모양대로 한 글자씩 나눈다', () {
      expect(PassphraseDisplayUtil.displayCharacters(NfkdUtil.encodeNfkd('코코넛2026')), [
        '코',
        '코',
        '넛',
        '2',
        '0',
        '2',
        '6',
      ]);
    });

    test('정규화하지 않은 바이트(이전 방식)도 같은 모양으로 나눈다', () {
      final legacy = Uint8List.fromList(utf8.encode('코코넛2026'));
      expect(PassphraseDisplayUtil.displayCharacters(legacy), ['코', '코', '넛', '2', '0', '2', '6']);
    });

    test('악센트 문자는 결합 문자와 함께 한 칸으로 나눈다', () {
      final characters = PassphraseDisplayUtil.displayCharacters(NfkdUtil.encodeNfkd('Café'));
      expect(characters, hasLength(4));
      expect(characters.last, 'e\u0301');
    });

    test('이모지는 한 칸으로 나눈다', () {
      expect(PassphraseDisplayUtil.displayCharacters(Uint8List.fromList(utf8.encode('a🥥b'))), ['a', '🥥', 'b']);
    });
  });

  group('PassphraseDisplayUtil.displayCharacters 입력 원문', () {
    test('원문이 NFKD 바이트를 만든 값이면 입력한 모양 그대로 나눈다 (일본어 탁음, 호환 문자)', () {
      const input = 'がｶ①é';
      expect(PassphraseDisplayUtil.displayCharacters(NfkdUtil.encodeNfkd(input), input: input), ['が', 'ｶ', '①', 'é']);
    });

    test('원문이 정규화하지 않은 UTF-8 바이트(이전 방식)를 만든 값이어도 원문을 쓴다', () {
      const input = 'がｶ①';
      expect(PassphraseDisplayUtil.displayCharacters(Uint8List.fromList(utf8.encode(input)), input: input), [
        'が',
        'ｶ',
        '①',
      ]);
    });

    test('원문이 바이트와 맞지 않으면 원문을 쓰지 않고 바이트를 바탕으로 나눈다', () {
      final characters = PassphraseDisplayUtil.displayCharacters(NfkdUtil.encodeNfkd('코코넛'), input: '다른값');
      expect(characters, ['코', '코', '넛']);
    });

    test('원문이 없으면 바이트를 바탕으로 나눈다', () {
      expect(PassphraseDisplayUtil.displayCharacters(NfkdUtil.encodeNfkd('①')), ['1']);
    });
  });

  group('PassphraseDisplayUtil.composeHangulJamo', () {
    test('받침 없는 음절과 받침 있는 음절을 합친다', () {
      expect(PassphraseDisplayUtil.composeHangulJamo('\u1100\u1161\u1100\u1161\u11A8'), '가각');
    });

    test('짝이 맞지 않는 자모와 다른 문자는 그대로 둔다', () {
      expect(PassphraseDisplayUtil.composeHangulJamo('\u1100abc\u1161'), '\u1100abc\u1161');
    });
  });
}
