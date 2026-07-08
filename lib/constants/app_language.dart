/// 앱 내부에서 사용하는 언어 코드
///
import 'package:coconut_vault/localization/strings.g.dart';

/// ISO 639-1 표준 언어 코드를 사용합니다.
enum AppLanguage {
  ko,
  en,
  ja,
  es,
  de;

  /// 앱 내부 언어 코드 (예: ko, en, ja, es, de)
  String get code => name;

  /// slang 라이브러리에서 사용하는 AppLocale 객체로 변환합니다.
  AppLocale get appLocale => AppLocale.values.firstWhere((e) => e.name == name, orElse: () => AppLocale.en);

  static AppLanguage fromCode(String code) => values.firstWhere((e) => e.code == code, orElse: () => en);

  /// 영어와 같은 어순(SVO)을 사용하는 언어인지 여부
  bool get hasEnglishWordOrder => this == AppLanguage.en || this == AppLanguage.es || this == AppLanguage.de;

  /// 언어별 이미지 파일 접미사
  String get imageSuffix {
    switch (this) {
      case AppLanguage.ko:
        return 'ko';
      default:
        return 'en';
    }
  }
}
