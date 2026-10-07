import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/passphrase_warning_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ko));

  String normalizationWarning() => t.mnemonic_generate_screen.passphrase_warning_normalization;

  group('PassphraseWarningUtil.warningMessages', () {
    test('warnNormalization이 켜져 있으면 NFKD로 바뀌는 패스프레이즈에 강화 경고를 맨 앞에 붙인다', () {
      final messages = PassphraseWarningUtil.warningMessages(['코코넛'], warnNormalization: true);

      expect(messages.first, normalizationWarning());
      expect(messages, hasLength(2));
    });

    test('warnNormalization이 꺼져 있으면 강화 경고를 붙이지 않는다', () {
      final messages = PassphraseWarningUtil.warningMessages(['코코넛']);

      expect(messages, isNot(contains(normalizationWarning())));
      expect(messages, hasLength(1));
    });

    test('NFKD로 바뀌지 않는 패스프레이즈에는 강화 경고를 붙이지 않는다', () {
      expect(PassphraseWarningUtil.warningMessages(['coconut-123!'], warnNormalization: true), isEmpty);
      // 이미 분해된 자모는 정규화해도 바뀌지 않는다.
      expect(
        PassphraseWarningUtil.warningMessages(['\u1100\u1161'], warnNormalization: true),
        isNot(contains(normalizationWarning())),
      );
    });

    test('여러 입력 중 하나라도 NFKD로 바뀌면 강화 경고를 한 번만 붙인다', () {
      final messages = PassphraseWarningUtil.warningMessages(['coconut', 'Café', '①'], warnNormalization: true);

      expect(messages.where((message) => message == normalizationWarning()), hasLength(1));
    });
  });
}
