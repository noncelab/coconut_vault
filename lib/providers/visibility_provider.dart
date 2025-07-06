import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/localization/strings.g.dart';

class VisibilityProvider extends ChangeNotifier {
  late bool _hasSeenGuide;
  late int _walletCount;
  late bool _isPassphraseUseEnabled;
  late String _language;

  bool get hasSeenGuide => _hasSeenGuide;
  int get walletCount => _walletCount;
  bool get isPassphraseUseEnabled => _isPassphraseUseEnabled;
  String get language => _language;

  /// TODO: 제거
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  VisibilityProvider() {
    final prefs = SharedPrefsRepository();
    _hasSeenGuide = prefs.getBool(SharedPrefsKeys.hasShownStartGuide) == true;
    _walletCount = prefs.getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    _isPassphraseUseEnabled = prefs.getBool(SharedPrefsKeys.kPassphraseUseEnabled) ?? false;

    // 언어 설정 초기화
    _language = _initializeLanguageFromOS(prefs);

    // 앱 시작 시 저장된 언어 설정 적용
    _initializeLanguage();
  }

  String _initializeLanguageFromOS(SharedPrefsRepository prefs) {
    // 이미 저장된 언어 설정이 있으면 사용
    if (prefs.isContainsKey(SharedPrefsKeys.kLanguage)) {
      return prefs.getString(SharedPrefsKeys.kLanguage);
    }

    // OS 언어 감지 (Flutter의 표준 방식 사용)
    try {
      final String languageCode = WidgetsBinding.instance.window.locale.languageCode.toLowerCase();

      // 지원하는 언어인지 확인
      if (languageCode == 'ko' || languageCode == 'kr') {
        return 'kr';
      } else if (languageCode == 'en') {
        return 'en';
      }
    } catch (e) {
      print('OS language detection failed: $e');
    }

    // 기본값은 영어
    return 'en';
  }

  void _initializeLanguage() {
    try {
      if (_language == 'kr') {
        LocaleSettings.setLocaleSync(AppLocale.kr);
      } else if (_language == 'en') {
        LocaleSettings.setLocaleSync(AppLocale.en);
      }
    } catch (e) {
      // 언어 초기화 실패 시 로그 출력 (선택사항)
      print('Language initialization failed: $e');
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
      } else if (languageCode == 'en') {
        await LocaleSettings.setLocale(AppLocale.en);
      }

      // 언어 변경 완료 후 상태 업데이트 및 UI 강제 업데이트
      _language = languageCode;
      notifyListeners();

      // 추가적인 UI 업데이트를 위한 post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      // 언어 변경 실패 시 로그 출력 (선택사항)
      print('Language change failed: $e');
      // 실패 시에도 상태는 업데이트
      _language = languageCode;
      notifyListeners();
    }
  }

  void showIndicator() {
    _isLoading = true;
    notifyListeners();
  }

  void hideIndicator() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveWalletCount(int count) async {
    _walletCount = count;
    await SharedPrefsRepository().setInt(SharedPrefsKeys.vaultListLength, count);
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
}
