import 'package:coconut_vault/enums/number_format_preset.dart';

/// 앱 전역 숫자 포맷 설정 (싱글톤)
///
/// [VisibilityProvider]에서 초기화하며, 앱 어디서든 [NumberFormatConfig.instance]로 접근합니다.
class NumberFormatConfig {
  NumberFormatConfig._();

  static final NumberFormatConfig instance = NumberFormatConfig._();

  NumberFormatPreset _preset = NumberFormatPreset.dotDecimal;

  NumberFormatPreset get preset => _preset;

  String get decimalSeparator => _preset.decimalSeparator;

  String get groupingSeparator => _preset.groupingSeparator;

  /// [preset]을 기반으로 소수점/천 단위 구분자를 갱신합니다.
  void applyPreset(NumberFormatPreset preset) {
    _preset = preset;
  }
}
