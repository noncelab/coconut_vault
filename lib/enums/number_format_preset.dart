import 'package:intl/intl.dart';

/// 숫자 포맷 프리셋
///
/// 소수점 구분자와 천 단위 구분자 조합을 미리 정의합니다.
/// 향후 지역(locale)이 추가되면 해당 preset을 확장하면 됩니다.
enum NumberFormatPreset {
  /// 1,234.5678 9012 형식 (미국, 한국, 일본 등)
  dotDecimal(displayLabel: '1,234.5678 9012', decimalSeparator: '.', groupingSeparator: ','),

  /// 1.234,5678 9012 형식 (독일, 스페인 등)
  commaDecimal(displayLabel: '1.234,5678 9012', decimalSeparator: ',', groupingSeparator: '.'),

  /// 1'234.5678 9012 형식 (스위스)
  swiss(displayLabel: "1\u2019234.5678 9012", decimalSeparator: '.', groupingSeparator: '\u2019'),

  /// 1 234,5678 9012 형식 (프랑스 등)
  frenchSpace(displayLabel: '1 234,5678 9012', decimalSeparator: ',', groupingSeparator: ' ');

  /// 예시 문자열 (설정 화면 등에서 사용자에게 보여줄 때 사용)
  final String displayLabel;

  /// 소수점 구분자
  final String decimalSeparator;

  /// 천 단위 구분자
  final String groupingSeparator;

  const NumberFormatPreset({
    required this.displayLabel,
    required this.decimalSeparator,
    required this.groupingSeparator,
  });

  static NumberFormatPreset fromCode(String code) {
    return values.firstWhere((e) => e.name == code, orElse: () => dotDecimal);
  }

  /// locale tag(예: 'en_US', 'de_DE')를 기반으로 가장 근접한 preset을 반환합니다.
  /// exact match가 없으면 decimal separator 기준으로 fallback 합니다.
  static NumberFormatPreset fromLocale(String localeName) {
    try {
      final symbols = NumberFormat.decimalPattern(localeName).symbols;

      for (final preset in values) {
        if (preset.decimalSeparator == symbols.DECIMAL_SEP &&
            _normalizeGroupingSeparator(preset.groupingSeparator) == _normalizeGroupingSeparator(symbols.GROUP_SEP)) {
          return preset;
        }
      }

      return symbols.DECIMAL_SEP == ',' ? commaDecimal : dotDecimal;
    } catch (_) {
      return dotDecimal;
    }
  }

  /// intl에서 반환하는 NBSP(00A0), narrow NBSP(202F) 등을 일반 공백으로 통일합니다.
  static String _normalizeGroupingSeparator(String separator) {
    return separator.replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
  }
}
