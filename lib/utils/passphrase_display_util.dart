import 'dart:convert';

import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/utils/nfkd_util.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

/// 패스프레이즈 바이트를 화면에 한 글자씩 보여주기 위한 유틸리티
///
/// 지갑 파생에는 NFKD로 정규화한 바이트를 쓰므로, 한글 음절은 초성·중성·종성 자모로 분해되어 있다.
/// 화면에는 사용자가 입력한 모양대로 보여야 하므로, 입력 원문이 있으면 원문을 쓰고 없으면 분해된 한글 자모를
/// 음절로 다시 합친다. 사용자가 한 글자로 인식하는 단위(grapheme cluster)로 나누며, 바이트 자체는 바꾸지 않는다.
abstract final class PassphraseDisplayUtil {
  static const int _syllableBase = 0xAC00;
  static const int _leadingBase = 0x1100;
  static const int _vowelBase = 0x1161;
  static const int _trailingBase = 0x11A7;
  static const int _leadingCount = 19;
  static const int _vowelCount = 21;
  static const int _trailingCount = 28;

  /// [input]은 사용자가 입력한 원문이다. [input]이 실제로 [passphrase]를 만든 값(NFKD 또는
  /// 정규화하지 않은 UTF-8)이면 입력한 모양 그대로 나누고, 아니면 바이트를 바탕으로 나눈다.
  static List<String> displayCharacters(Uint8List passphrase, {String? input}) {
    if (input != null && _isInputOf(input, passphrase)) {
      return input.characters.toList();
    }
    return composeHangulJamo(utf8.decode(passphrase, allowMalformed: true)).characters.toList();
  }

  static bool _isInputOf(String input, Uint8List passphrase) {
    final nfkd = NfkdUtil.encodeNfkd(input);
    final legacy = Uint8List.fromList(utf8.encode(input));
    try {
      return listEquals(nfkd, passphrase) || listEquals(legacy, passphrase);
    } finally {
      nfkd.wipe();
      legacy.wipe();
    }
  }

  /// 초성+중성(+종성) 자모 시퀀스를 한글 음절로 합친다. 그 외 문자는 그대로 둔다.
  @visibleForTesting
  static String composeHangulJamo(String text) {
    final runes = text.runes.toList();
    final buffer = StringBuffer();
    var i = 0;
    while (i < runes.length) {
      final leading = runes[i] - _leadingBase;
      final vowel = i + 1 < runes.length ? runes[i + 1] - _vowelBase : -1;
      if (leading >= 0 && leading < _leadingCount && vowel >= 0 && vowel < _vowelCount) {
        var trailing = 0;
        if (i + 2 < runes.length) {
          final candidate = runes[i + 2] - _trailingBase;
          if (candidate > 0 && candidate < _trailingCount) trailing = candidate;
        }
        buffer.writeCharCode(_syllableBase + (leading * _vowelCount + vowel) * _trailingCount + trailing);
        i += trailing == 0 ? 2 : 3;
        continue;
      }
      buffer.writeCharCode(runes[i]);
      i++;
    }
    return buffer.toString();
  }
}
