import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppVersionUtil {
  /// 앱 업데이트 완료 여부를 확인하는 메서드
  static Future<bool> isAppVersionUpdated() async {
    final currentVersion = await _getAppVersion();
    final savedVersion = await _getAppVersionFromPrefs();
    debugPrint('currentVersion: $currentVersion, savedVersion: $savedVersion');

    if (savedVersion.isEmpty) {
      return false;
    }

    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    List<int> latestParts = savedVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false; // 동일한 경우
  }

  /// 앱 버전 정보를 SharedPreferences에 저장하는 메서드
  static Future<void> saveAppVersionToPrefs() async {
    final version = await _getAppVersion();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPrefsKeys.kAppVersion, version);
  }

  /// PackageInfo를 사용하여 앱 버전 정보를 가져오는 메서드
  static Future<String> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version.split('-').first;
  }

  /// SharedPreferences에서 앱 버전 정보를 가져오는 메서드
  static Future<String> _getAppVersionFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SharedPrefsKeys.kAppVersion) ?? '';
  }
}
