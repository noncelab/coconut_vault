import 'dart:ui';

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
  late String _language;
  late bool _isBtcUnit;

  bool get hasSeenGuide => _hasSeenGuide;
  int get walletCount => _walletCount;
  bool get isPassphraseUseEnabled => _isPassphraseUseEnabled;
  String get language => _language;
  bool get isKorean => _language == 'kr';
  bool get isEnglish => _language == 'en';

  bool get isBtcUnit => _isBtcUnit;
  BitcoinUnit get currentUnit => _isBtcUnit ? BitcoinUnit.btc : BitcoinUnit.sats;

  VisibilityProvider({required bool isSigningOnlyMode}) {
    final prefs = SharedPrefsRepository();
    _hasSeenGuide = prefs.getBool(SharedPrefsKeys.hasShownStartGuide) == true;
    _walletCount = prefs.getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    _isSigningOnlyMode = isSigningOnlyMode;
    _isPassphraseUseEnabled =
        isSigningOnlyMode ? true : (prefs.getBool(SharedPrefsKeys.kPassphraseUseEnabled) ?? false);
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

  void reset() {
    _walletCount = 0;
    final prefs = SharedPrefsRepository();
    prefs.setInt(SharedPrefsKeys.vaultListLength, 0);
  }

  Future<void> setHasSeenGuide() async {
    _hasSeenGuide = true;
    SharedPrefsRepository().setBool(SharedPrefsKeys.hasShownStartGuide, true);
    notifyListeners();
  }

  Future<void> setAdvancedMode(bool value) async {
    _isPassphraseUseEnabled = value;
    SharedPrefsRepository().setBool(SharedPrefsKeys.kPassphraseUseEnabled, value);
    notifyListeners();
  }

  String _initializeLanguageFromOS(SharedPrefsRepository prefs) {
    // 이미 저장된 언어 설정이 있으면 사용
    if (prefs.isContainsKey(SharedPrefsKeys.kLanguage)) {
      return prefs.getString(SharedPrefsKeys.kLanguage);
    }

    // OS 언어 감지 (Flutter의 표준 방식 사용)
    try {
      final String languageCode = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      print('languageCode: $languageCode');
      // 지원하는 언어인지 확인
      if (languageCode == 'ko' || languageCode == 'kr') {
        return 'kr';
      } else if (languageCode == 'ja' || languageCode == 'jp') {
        return 'jp';
      } else if (languageCode == 'en') {
        return 'en';
      }
    } catch (e) {
      Logger.error('OS language detection failed: $e');
    }

    // 기본값은 영어
    return 'en';
  }

  void _initializeLanguage() {
    try {
      if (_language == 'kr') {
        LocaleSettings.setLocaleSync(AppLocale.kr);
      } else if (_language == 'jp') {
        // 일본어 로케일 설정 시 지연 로딩 문제를 방지하기 위해 비동기로 처리
        LocaleSettings.setLocale(AppLocale.jp).catchError((error) {
          Logger.error('Japanese locale initialization failed: $error');
          // 실패 시 영어로 폴백
          try {
            LocaleSettings.setLocaleSync(AppLocale.en);
            _language = 'en';
            return AppLocale.en;
          } catch (fallbackError) {
            Logger.error('Fallback to English locale failed: $fallbackError');
          }
          return AppLocale.en;
        });
      } else if (_language == 'en') {
        // 영어 로케일 설정 시 지연 로딩 문제를 방지하기 위해 비동기로 처리
        LocaleSettings.setLocale(AppLocale.en).catchError((error) {
          Logger.error('English locale initialization failed: $error');
          // 실패 시 한국어로 폴백 (영어가 실패하면 한국어가 기본)
          try {
            LocaleSettings.setLocaleSync(AppLocale.kr);
            _language = 'kr';
          } catch (fallbackError) {
            Logger.error('Fallback to Korean locale failed: $fallbackError');
            return AppLocale.kr;
          }
          return AppLocale.kr;
        });
      }
    } catch (e) {
      // 언어 초기화 실패 시 로그 출력 (선택사항)
      Logger.error('Language initialization failed: $e');
      // 실패 시 기본값으로 영어 설정
      try {
        LocaleSettings.setLocaleSync(AppLocale.en);
        _language = 'en';
      } catch (fallbackError) {
        Logger.error('Fallback language initialization failed: $fallbackError');
      }
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    final prefs = SharedPrefsRepository();

    // SharedPreferences에 먼저 저장
    await prefs.setString(SharedPrefsKeys.kLanguage, languageCode);

    // slang을 사용하여 동적으로 언어 변경
    try {
      if (languageCode == 'kr') {
        await LocaleSettings.setLocale(AppLocale.kr);
        _language = languageCode;
      } else if (languageCode == 'jp') {
        try {
          await LocaleSettings.setLocale(AppLocale.jp);
          _language = languageCode;
        } catch (japaneseError) {
          Logger.error('Japanese locale change failed: $japaneseError');
          // 일본어 로딩 실패 시 영어로 폴백
          await LocaleSettings.setLocale(AppLocale.en);
          _language = 'en';
          // SharedPreferences도 영어로 업데이트
          await prefs.setString(SharedPrefsKeys.kLanguage, 'en');
        }
      } else if (languageCode == 'en') {
        // 영어 로케일 설정 시 지연 로딩 문제를 방지하기 위해 더 안전한 처리
        try {
          await LocaleSettings.setLocale(AppLocale.en);
          _language = languageCode;
        } catch (englishError) {
          Logger.error('English locale change failed: $englishError');
          // 영어 로딩 실패 시 한국어로 폴백 (최종 폴백)
          await LocaleSettings.setLocale(AppLocale.kr);
          _language = 'kr';
          // SharedPreferences도 한국어로 업데이트
          await prefs.setString(SharedPrefsKeys.kLanguage, 'kr');
        }
      }

      // 언어 변경 완료 후 상태 업데이트 및 UI 강제 업데이트
      notifyListeners();

      // 추가적인 UI 업데이트를 위한 post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      Logger.error('Language change failed: $e');
      // 실패 시 기본 언어로 설정 시도
      try {
        await LocaleSettings.setLocale(AppLocale.en);
        _language = 'en';
        await prefs.setString(SharedPrefsKeys.kLanguage, 'en');
      } catch (fallbackError) {
        Logger.error('Fallback language change failed: $fallbackError');
        // 최종적으로 상태만 업데이트
        _language = languageCode;
      }
      notifyListeners();
    }
  }

  Future<void> changeIsBtcUnit(bool isBtcUnit) async {
    _isBtcUnit = isBtcUnit;
    SharedPrefsRepository().setBool(SharedPrefsKeys.kIsBtcUnit, isBtcUnit);
    notifyListeners();
  }

  void updateIsSigningOnlyMode(bool isSigningOnlyMode) {
    _isSigningOnlyMode = isSigningOnlyMode;
  }
}
