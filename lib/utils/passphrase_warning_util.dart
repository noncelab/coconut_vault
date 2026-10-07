import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/nfkd_util.dart';
import 'package:flutter/material.dart';

class PassphraseWarningUtil {
  PassphraseWarningUtil._();

  static final Set<String> allowedChars = {
    ...List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i)),
    ...List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i)),
    ...List.generate(10, (i) => i.toString()),
    '[',
    ']',
    '{',
    '}',
    '#',
    '%',
    '^',
    '*',
    '+',
    '=',
    '_',
    '\\',
    '|',
    '~',
    '<',
    '>',
    '-',
    '/',
    ':',
    ';',
    '(',
    ')',
    r'$',
    '&',
    '"',
    '`',
    '.',
    ',',
    '?',
    '!',
    '\'',
    '@',
  };

  static String warningMessage(String passphrase, {bool warnNormalization = false}) {
    final messages = warningMessages([passphrase], warnNormalization: warnNormalization);
    return messages.join('\n');
  }

  /// [warnNormalization]은 지갑 생성처럼 패스프레이즈를 NFKD로 정규화해 쓰는 문맥에서 켠다.
  /// 정규화로 값이 바뀌는 패스프레이즈는 앱에 따라 다른 지갑으로 복원될 수 있어 경고를 강화한다.
  static List<String> warningMessages(Iterable<String> passphrases, {bool warnNormalization = false}) {
    final inputs = passphrases.where((input) => input.isNotEmpty).toList();
    if (inputs.isEmpty) {
      return const [];
    }

    final containsSpace = inputs.any((input) => input.contains(' '));
    final invalidChars =
        inputs
            .expand((input) => input.characters)
            .where((char) => char != ' ' && !allowedChars.contains(char))
            .toSet()
            .toList();

    final changedByNormalization = warnNormalization && inputs.any((input) => !NfkdUtil.isNfkdNormalized(input));

    return [
      if (changedByNormalization) t.mnemonic_generate_screen.passphrase_warning_normalization,
      if (containsSpace) t.mnemonic_generate_screen.passphrase_warning_space,
      if (invalidChars.isNotEmpty) t.mnemonic_generate_screen.passphrase_warning(words: invalidChars.join(', ')),
    ];
  }
}
