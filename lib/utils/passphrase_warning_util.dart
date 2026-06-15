import 'package:coconut_vault/localization/strings.g.dart';
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

  static String warningMessage(String passphrase) {
    final messages = warningMessages([passphrase]);
    return messages.join('\n');
  }

  static List<String> warningMessages(Iterable<String> passphrases) {
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

    return [
      if (containsSpace) t.mnemonic_generate_screen.passphrase_warning_space,
      if (invalidChars.isNotEmpty) t.mnemonic_generate_screen.passphrase_warning(words: invalidChars.join(', ')),
    ];
  }
}
