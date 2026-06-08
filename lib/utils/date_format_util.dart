import 'package:coconut_vault/localization/strings.g.dart';

class DateFormatUtil {
  static const String defaultLanguageCode = 'en';
  static const Map<String, AppLocale> _appLocaleByLanguageCode = {
    'kr': AppLocale.kr,
    'ko': AppLocale.kr,
    'en': AppLocale.en,
    'jp': AppLocale.jp,
    'ja': AppLocale.jp,
  };

  static String formatLocalizedDateTime(DateTime dateTime, String languageCode) {
    final translations = _getTranslations(languageCode);
    final dayPeriod = dateTime.hour < 12 ? translations.am : translations.pm;
    final hourOfPeriod = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

    return translations.locale_datetime(
      year: dateTime.year,
      month: dateTime.month,
      day: dateTime.day,
      dayPeriod: dayPeriod,
      hour: hourOfPeriod.toString(),
      minute: dateTime.minute.toString().padLeft(2, '0'),
    );
  }

  static Translations _getTranslations(String languageCode) {
    final locale = _appLocaleByLanguageCode[languageCode] ?? _appLocaleByLanguageCode[defaultLanguageCode]!;
    return locale.translations;
  }
}
