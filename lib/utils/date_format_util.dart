import 'package:coconut_vault/constants/app_language.dart';

class DateFormatUtil {
  static String formatLocalizedDateTime(DateTime dateTime, AppLanguage language) {
    final translations = language.appLocale.translations;
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
}
