import 'dart:async';

import 'package:coconut_vault/config/number_format_config.dart';
import 'package:coconut_vault/constants/app_language.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/number_format_preset.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Test-only access to the store already installed with shared_preferences.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    binding.platformDispatcher.localeTestValue = const Locale('th', 'TH');
    await LocaleSettings.instance.loadAllLocales();
  });

  tearDown(() async {
    binding.platformDispatcher.clearLocaleTestValue();
    await LocaleSettings.setLocale(AppLocale.en);
    NumberFormatConfig.instance.applyPreset(NumberFormatPreset.dotDecimal);
  });

  Future<VisibilityProvider> initialize(
    bool signingOnly,
    Map<String, Object> values, {
    Future<AppLocale> Function(AppLocale) setLocale = LocaleSettings.setLocale,
  }) async {
    SharedPreferences.setMockInitialValues(values);
    await SharedPrefsRepository().init();
    final provider = VisibilityProvider(isSigningOnlyMode: signingOnly, setLocale: setLocale);
    // Deferred translations are already loaded; finish the constructor's async locale initialization.
    await Future<void>.delayed(Duration.zero);
    return provider;
  }

  test('Thai is selectable after Japanese and has its own locale and SVO order', () async {
    final thai = AppLanguage.fromCode('th');
    expect(thai.code, 'th');
    expect(AppLanguage.displayValues.map((language) => language.code), ['ko', 'en', 'ja', 'th']);
    expect(thai.appLocale.languageCode, 'th');
    expect(thai.hasEnglishWordOrder, isTrue);
    for (final locale in AppLocale.values) {
      await LocaleSettings.setLocale(locale);
      expect(thai.displayName, 'ไทย');
    }
    expect(AppLanguage.fromCode('unsupported'), AppLanguage.en);
    expect(AppLanguage.ko.hasEnglishWordOrder, isFalse);
    expect(AppLanguage.ja.hasEnglishWordOrder, isFalse);
  });

  test('Thai translations load asynchronously and keep Gregorian ASCII dates', () async {
    final locale = AppLocale.values.firstWhere((locale) => locale.languageCode == 'th');
    await LocaleSettings.setLocale(locale);
    expect(LocaleSettings.currentLocale, locale);
    expect(t.confirm, matches(RegExp(r'[\u0E00-\u0E7F]')));
    for (final date in [DateTime(2026, 6, 5, 0, 5), DateTime(2026, 6, 5, 12, 30)]) {
      final formatted = DateFormatUtil.formatLocalizedDateTime(date, AppLanguage.fromCode('th'));
      expect(formatted, contains('2026'));
      expect(formatted, isNot(contains('2569')));
      expect(formatted, contains(date.minute.toString().padLeft(2, '0')));
      expect(formatted, isNot(matches(RegExp(r'[\u0E50-\u0E59]'))));
    }
  });

  for (final signingOnly in [false, true]) {
    group(signingOnly ? 'Lite / signing-only' : 'Full / secure storage', () {
      test('new Thai installation requests its language write before number format', () async {
        final originalStore = SharedPreferencesStorePlatform.instance;
        addTearDown(() {
          SharedPreferences.resetStatic();
          SharedPreferencesStorePlatform.instance = originalStore;
        });
        SharedPreferences.setMockInitialValues({});
        final store = _RecordingPreferencesStore();
        SharedPreferencesStorePlatform.instance = store;
        await SharedPrefsRepository().init();
        final provider = VisibilityProvider(isSigningOnlyMode: signingOnly, setLocale: (locale) async => locale);
        addTearDown(provider.dispose);

        expect(store.writes, [
          'flutter.${SharedPrefsKeys.kLanguage}=th',
          'flutter.${SharedPrefsKeys.kNumberFormatPreset}=dotDecimal',
        ]);
      });

      test('new Thai installation persists Thai before locale loading completes', () async {
        SharedPreferences.setMockInitialValues({});
        await SharedPrefsRepository().init();
        final loading = Completer<AppLocale>();
        final requestedLocales = <AppLocale>[];
        final provider = VisibilityProvider(
          isSigningOnlyMode: signingOnly,
          setLocale: (locale) {
            requestedLocales.add(locale);
            return loading.future;
          },
        );
        addTearDown(() async {
          loading.complete(AppLocale.th);
          await Future<void>.delayed(Duration.zero);
          provider.dispose();
        });

        expect(loading.isCompleted, isFalse);
        expect(requestedLocales, [AppLocale.th]);
        expect(provider.appLanguage, AppLanguage.th);
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), 'th');
      });

      test('new Thai installation persists Thai across restart with the same preferences', () async {
        final provider = await initialize(signingOnly, {});
        expect(provider.appLanguage.code, 'th');
        expect(LocaleSettings.currentLocale.languageCode, 'th');
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), 'th');
        expect(provider.numberFormatPreset, NumberFormatPreset.dotDecimal);
        expect(provider.isBtcUnit, isTrue);
        provider.dispose();

        await LocaleSettings.setLocale(AppLocale.en);
        final restarted = VisibilityProvider(isSigningOnlyMode: signingOnly);
        await Future<void>.delayed(Duration.zero);
        expect(restarted.appLanguage, AppLanguage.th);
        expect(LocaleSettings.currentLocale, AppLocale.th);
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), 'th');
        restarted.dispose();
      });

      for (final saved in ['ko', 'en', 'ja', 'th']) {
        test('existing saved $saved wins over the Thai device locale', () async {
          final provider = await initialize(signingOnly, {
            SharedPrefsKeys.kLanguage: saved,
            SharedPrefsKeys.kNumberFormatPreset: 'swiss',
            SharedPrefsKeys.kIsBtcUnit: false,
          });
          expect(provider.appLanguage.code, saved);
          expect(LocaleSettings.currentLocale.languageCode, saved);
          expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), saved);
          expect(provider.numberFormatPreset, NumberFormatPreset.swiss);
          expect(provider.isBtcUnit, isFalse);
          provider.dispose();
        });
      }

      for (final oldValues in <Map<String, Object>>[
        {SharedPrefsKeys.kNumberFormatPreset: 'dotDecimal'},
        {SharedPrefsKeys.hasShownStartGuide: true},
        {SharedPrefsKeys.hasShownStartGuide: false},
      ]) {
        test('existing automatic English stays English with ${oldValues.keys.single}', () async {
          final provider = await initialize(signingOnly, oldValues);
          expect(provider.appLanguage, AppLanguage.en);
          expect(LocaleSettings.currentLocale, AppLocale.en);
          expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kLanguage), isFalse);
          provider.dispose();
        });
      }

      for (final code in ['ko', 'ja', 'en', 'de', 'es', 'fr']) {
        test('automatic $code is not persisted and follows the device language on restart', () async {
          binding.platformDispatcher.localeTestValue = Locale(code);
          final provider = await initialize(signingOnly, {});
          final expected = ['ko', 'ja'].contains(code) ? code : 'en';
          expect(provider.appLanguage.code, expected);
          expect(LocaleSettings.currentLocale.languageCode, expected);
          expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kLanguage), isFalse);
          provider.dispose();

          final nextCode = code == 'ja' ? 'ko' : 'ja';
          binding.platformDispatcher.localeTestValue = Locale(nextCode);
          final restarted = VisibilityProvider(isSigningOnlyMode: signingOnly);
          await Future<void>.delayed(Duration.zero);
          expect(restarted.appLanguage.code, nextCode);
          expect(LocaleSettings.currentLocale.languageCode, nextCode);
          expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kLanguage), isFalse);
          restarted.dispose();
        });
      }

      test('failed Thai locale initialization retains Thai for retry on restart', () async {
        final requestedLocales = <AppLocale>[];
        final provider = await initialize(
          signingOnly,
          {},
          setLocale: (locale) async {
            requestedLocales.add(locale);
            if (locale == AppLocale.th) throw StateError('Thai locale load failed');
            return LocaleSettings.setLocale(locale);
          },
        );
        expect(requestedLocales, [AppLocale.th, AppLocale.en]);
        expect(provider.appLanguage, AppLanguage.en);
        expect(LocaleSettings.currentLocale, AppLocale.en);
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), 'th');
        provider.dispose();

        final restarted = VisibilityProvider(
          isSigningOnlyMode: signingOnly,
          setLocale: (locale) {
            requestedLocales.add(locale);
            return LocaleSettings.setLocale(locale);
          },
        );
        await Future<void>.delayed(Duration.zero);
        expect(requestedLocales, [AppLocale.th, AppLocale.en, AppLocale.th]);
        expect(restarted.appLanguage, AppLanguage.th);
        expect(LocaleSettings.currentLocale, AppLocale.th);
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), 'th');
        restarted.dispose();
      });

      testWidgets('switching to Thai survives restart and preserves number format and unit', (tester) async {
        final provider = await tester.runAsync(
          () => initialize(signingOnly, {
            SharedPrefsKeys.kLanguage: 'en',
            SharedPrefsKeys.kNumberFormatPreset: 'commaDecimal',
            SharedPrefsKeys.kIsBtcUnit: false,
          }),
        );
        await provider!.changeLanguage(AppLanguage.fromCode('th'));
        tester.binding.scheduleFrame();
        await tester.pump();
        expect(provider.appLanguage.code, 'th');
        expect(provider.numberFormatPreset, NumberFormatPreset.commaDecimal);
        expect(provider.isBtcUnit, isFalse);
        provider.dispose();

        binding.platformDispatcher.localeTestValue = const Locale('ja', 'JP');
        final restarted = VisibilityProvider(isSigningOnlyMode: signingOnly);
        await tester.pump();
        expect(restarted.appLanguage.code, 'th');
        expect(restarted.numberFormatPreset, NumberFormatPreset.commaDecimal);
        expect(restarted.isBtcUnit, isFalse);
        restarted.dispose();
      });
    });
  }
}

class _RecordingPreferencesStore extends InMemorySharedPreferencesStore {
  _RecordingPreferencesStore() : super.empty();

  final writes = <String>[];

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    writes.add('$key=$value');
    return super.setValue(valueType, key, value);
  }
}
