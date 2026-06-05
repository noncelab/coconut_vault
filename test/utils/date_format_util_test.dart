import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/date_format_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatUtil', () {
    final date = DateTime(2026, 6, 5, 9, 30);
    final afternoonDate = DateTime(2026, 6, 5, 15, 30);

    test('동기 포맷도 예외 없이 문자열을 반환한다', () {
      LocaleSettings.setLocaleSync(AppLocale.kr);

      expect(
        DateFormatUtil.formatLocalizedDateTime(date, 'kr'),
        '2026년 6월 5일 오전 9:30',
      );
    });

    test('언어별 yMMMMd 및 시간 형식으로 DateTime을 변환한다', () async {
      await LocaleSettings.setLocale(AppLocale.en);
      expect(
        DateFormatUtil.formatLocalizedDateTime(date, 'en'),
        '6/5/2026 9:30 AM',
      );

      LocaleSettings.setLocaleSync(AppLocale.kr);
      expect(
        DateFormatUtil.formatLocalizedDateTime(date, 'kr'),
        '2026년 6월 5일 오전 9:30',
      );
      expect(
        DateFormatUtil.formatLocalizedDateTime(afternoonDate, 'kr'),
        '2026년 6월 5일 오후 3:30',
      );

      await LocaleSettings.setLocale(AppLocale.jp);
      expect(
        DateFormatUtil.formatLocalizedDateTime(date, 'jp'),
        '2026年6月5日 午前 9:30',
      );
    });
  });
}
