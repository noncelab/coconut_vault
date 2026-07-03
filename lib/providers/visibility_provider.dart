import 'dart:ui';

import 'package:coconut_vault/constants/app_language.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/material.dart';

class VisibilityProvider extends ChangeNotifier {
  late bool _isSigningOnlyMode;
  late bool _hasSeenGuide;
  late int _walletCount;
  late bool _isPassphraseUseEnabled;
  late bool _isAccountEditEnabled;
  late AppLanguage _language;
  late bool _isBtcUnit;

  bool get hasSeenGuide => _hasSeenGuide;
  bool get isPassphraseUseEnabled => _isPassphraseUseEnabled;
  bool get isAccountEditEnabled => _isAccountEditEnabled;
  String get language => _language.code;
  AppLanguage get appLanguage => _language;
  bool get isEnglishWordOrder => _language.hasEnglishWordOrder;

  bool get isBtcUnit => _isBtcUnit;
  BitcoinUnit get currentUnit => _isBtcUnit ? BitcoinUnit.btc : BitcoinUnit.sats;

  VisibilityProvider({required bool isSigningOnlyMode}) {
    final prefs = SharedPrefsRepository();
    _isSigningOnlyMode = isSigningOnlyMode;
    if (_isSigningOnlyMode) {
      SharedPrefsRepository().setInt(SharedPrefsKeys.vaultListLength, 0);
      _walletCount = 0;
    } else {
      _walletCount = prefs.getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    }
    _hasSeenGuide = prefs.getBool(SharedPrefsKeys.hasShownStartGuide) == true;

    _isPassphraseUseEnabled =
        isSigningOnlyMode ? true : (prefs.getBool(SharedPrefsKeys.kPassphraseUseEnabled) ?? false);

    _isAccountEditEnabled = isSigningOnlyMode ? true : (prefs.getBool(SharedPrefsKeys.kChangeAccountEnabled) ?? false);

    _language = _initializeLanguageFromOS(prefs);
    _isBtcUnit = prefs.getBool(SharedPrefsKeys.kIsBtcUnit) ?? true;
    _initializeLanguage();
  }

  Future<void> saveWalletCount(int count) async {
    _walletCount = count;
    if (!_isSigningOnlyMode) {
      await SharedPrefsRepository().setInt(SharedPrefsKeys.vaultListLength, count);
    }
    notifyListeners();
  }

  Future<void> setHasSeenGuide() async {
    _hasSeenGuide = true;
    await SharedPrefsRepository().setBool(SharedPrefsKeys.hasShownStartGuide, true);
    notifyListeners();
  }

  Future<void> setPassphraseUseEnabled(bool value) async {
    _isPassphraseUseEnabled = value;
    await SharedPrefsRepository().setBool(SharedPrefsKeys.kPassphraseUseEnabled, value);
    notifyListeners();
  }

  Future<void> setChangeAccountEnabled(bool value) async {
    _isAccountEditEnabled = value;
    await SharedPrefsRepository().setBool(SharedPrefsKeys.kChangeAccountEnabled, value);
    notifyListeners();
  }

  AppLanguage _initializeLanguageFromOS(SharedPrefsRepository prefs) {
    // 이미 저장된 언어 설정이 있으면 사용
    if (prefs.isContainsKey(SharedPrefsKeys.kLanguage)) {
      final savedLanguageCode = prefs.getString(SharedPrefsKeys.kLanguage);
      return AppLanguage.fromCode(savedLanguageCode);
    }

    // OS 언어 감지 (Flutter의 표준 방식 사용)
    try {
      final String languageCode = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      // 지원하는 언어인지 확인
      return AppLanguage.fromCode(languageCode);
    } catch (e) {
      Logger.error('OS language detection failed: $e');
    }

    // 기본값은 영어
    return AppLanguage.en;
  }

  void _initializeLanguage() {
    // Set locale asynchronously to avoid blocking UI, with error handling.
    LocaleSettings.setLocale(_language.appLocale).catchError((error) {
      Logger.error('Locale initialization for ${_language.code} failed: $error');
      // Fallback to English if the initial locale setting fails.
      try {
        LocaleSettings.setLocaleSync(AppLocale.en);
        _language = AppLanguage.en;
        // The onError handler must return a value of the future's type.
        return AppLocale.en;
      } catch (fallbackError) {
        Logger.error('Fallback to English locale failed: $fallbackError');
        // Re-throw if even the fallback fails, to be caught by the framework.
        rethrow;
      }
    });
  }

  Future<void> changeLanguage(AppLanguage language) async {
    final prefs = SharedPrefsRepository();

    // SharedPreferences에 먼저 저장
    await prefs.setString(SharedPrefsKeys.kLanguage, language.code);

    // slang을 사용하여 동적으로 언어 변경
    try {
      await LocaleSettings.setLocale(language.appLocale);
      _language = language;

      // 언어 변경 완료 후 상태 업데이트 및 UI 강제 업데이트
      notifyListeners();

      // 추가적인 UI 업데이트를 위한 post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      Logger.error('Language change failed: $e');
      // 실패 시 기본 언어(영어)로 설정 시도
      try {
        await LocaleSettings.setLocale(AppLocale.en);
        _language = AppLanguage.en;
        await prefs.setString(SharedPrefsKeys.kLanguage, AppLanguage.en.code);
      } catch (fallbackError) {
        Logger.error('Fallback language change failed: $fallbackError');
      }
      notifyListeners();
    }
  }

  Future<void> changeIsBtcUnit(bool isBtcUnit) async {
    _isBtcUnit = isBtcUnit;
    await SharedPrefsRepository().setBool(SharedPrefsKeys.kIsBtcUnit, isBtcUnit);
    notifyListeners();
  }

  Future<void> updateIsSigningOnlyMode(bool isSigningOnlyMode) async {
    if (_isSigningOnlyMode == isSigningOnlyMode) return;
    if (isSigningOnlyMode) {
      await setPassphraseUseEnabled(true);
      await setChangeAccountEnabled(true);
      await SharedPrefsRepository().deleteSharedPrefsWithKey(SharedPrefsKeys.vaultListLength);
    } else {
      await setPassphraseUseEnabled(false);
      await setChangeAccountEnabled(false);
      await SharedPrefsRepository().setInt(SharedPrefsKeys.vaultListLength, _walletCount);
    }
    _isSigningOnlyMode = isSigningOnlyMode;
  }

  void reloadRelatedToVault() {
    _walletCount = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
  }
}
