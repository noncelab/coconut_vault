import 'package:coconut_vault/config/number_format_config.dart';
import 'package:coconut_vault/enums/number_format_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumberFormatPreset', () {
    test('dotDecimal has . and ,', () {
      expect(NumberFormatPreset.dotDecimal.decimalSeparator, '.');
      expect(NumberFormatPreset.dotDecimal.groupingSeparator, ',');
    });

    test('commaDecimal has , and .', () {
      expect(NumberFormatPreset.commaDecimal.decimalSeparator, ',');
      expect(NumberFormatPreset.commaDecimal.groupingSeparator, '.');
    });

    test('swiss has . and \u2019', () {
      expect(NumberFormatPreset.swiss.decimalSeparator, '.');
      expect(NumberFormatPreset.swiss.groupingSeparator, '\u2019');
    });

    test('frenchSpace has , and space', () {
      expect(NumberFormatPreset.frenchSpace.decimalSeparator, ',');
      expect(NumberFormatPreset.frenchSpace.groupingSeparator, ' ');
    });

    test('fromCode returns matching preset', () {
      expect(NumberFormatPreset.fromCode('dotDecimal'), NumberFormatPreset.dotDecimal);
      expect(NumberFormatPreset.fromCode('commaDecimal'), NumberFormatPreset.commaDecimal);
      expect(NumberFormatPreset.fromCode('swiss'), NumberFormatPreset.swiss);
      expect(NumberFormatPreset.fromCode('frenchSpace'), NumberFormatPreset.frenchSpace);
    });

    test('fromCode falls back to dotDecimal for unknown code', () {
      expect(NumberFormatPreset.fromCode('unknown'), NumberFormatPreset.dotDecimal);
    });

    test('fromLocale en_US -> dotDecimal', () {
      expect(NumberFormatPreset.fromLocale('en_US'), NumberFormatPreset.dotDecimal);
    });

    test('fromLocale ko_KR -> dotDecimal', () {
      expect(NumberFormatPreset.fromLocale('ko_KR'), NumberFormatPreset.dotDecimal);
    });

    test('fromLocale de_DE -> commaDecimal', () {
      expect(NumberFormatPreset.fromLocale('de_DE'), NumberFormatPreset.commaDecimal);
    });

    test('fromLocale es_ES -> commaDecimal', () {
      expect(NumberFormatPreset.fromLocale('es_ES'), NumberFormatPreset.commaDecimal);
    });

    test('fromLocale es_MX -> dotDecimal', () {
      expect(NumberFormatPreset.fromLocale('es_MX'), NumberFormatPreset.dotDecimal);
    });

    test('fromLocale de_CH -> swiss', () {
      expect(NumberFormatPreset.fromLocale('de_CH'), NumberFormatPreset.swiss);
    });

    test('fromLocale fr_FR -> frenchSpace', () {
      expect(NumberFormatPreset.fromLocale('fr_FR'), NumberFormatPreset.frenchSpace);
    });

    test('fromLocale falls back to dotDecimal on invalid locale', () {
      expect(NumberFormatPreset.fromLocale('invalid_locale'), NumberFormatPreset.dotDecimal);
    });
  });

  group('NumberFormatConfig', () {
    test('default preset is dotDecimal', () {
      expect(NumberFormatConfig.instance.preset, NumberFormatPreset.dotDecimal);
      expect(NumberFormatConfig.instance.decimalSeparator, '.');
      expect(NumberFormatConfig.instance.groupingSeparator, ',');
    });

    test('applyPreset commaDecimal updates separators', () {
      NumberFormatConfig.instance.applyPreset(NumberFormatPreset.commaDecimal);
      expect(NumberFormatConfig.instance.preset, NumberFormatPreset.commaDecimal);
      expect(NumberFormatConfig.instance.decimalSeparator, ',');
      expect(NumberFormatConfig.instance.groupingSeparator, '.');
    });

    test('applyPreset dotDecimal updates separators', () {
      NumberFormatConfig.instance.applyPreset(NumberFormatPreset.dotDecimal);
      expect(NumberFormatConfig.instance.preset, NumberFormatPreset.dotDecimal);
      expect(NumberFormatConfig.instance.decimalSeparator, '.');
      expect(NumberFormatConfig.instance.groupingSeparator, ',');
    });
  });
}
