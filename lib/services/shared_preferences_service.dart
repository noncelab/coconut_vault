import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String kHasShownStartGuide = "HAS_SHOWN_START_GUIDE";
  static const String kIsPinEnabled = "IS_PIN_ENABLED";
  static const String kIsNotEmptyVaultList = "IS_NOT_EMPTY_VAULT_LIST";

  late SharedPreferences _sharedPrefs;
  SharedPreferences get sharedPrefs => _sharedPrefs;

  static final SharedPrefsService _instance = SharedPrefsService._internal();

  factory SharedPrefsService() => _instance;

  SharedPrefsService._internal();

  Future<void> init() async {
    // init in main.dart
    _sharedPrefs = await SharedPreferences.getInstance();
  }

  /// Common--------------------------------------------------------------------
  Future clearSharedPref() async {
    await _sharedPrefs.clear();
  }

  bool isContainsKey(String key) {
    return _sharedPrefs.containsKey(key);
  }

  Future deleteSharedPrefsWithKey(String key) async {
    await _sharedPrefs.remove(key);
  }

  bool getBool(String key) {
    return _sharedPrefs.getBool(key) ?? false;
  }

  Future setBool(String key, bool value) async {
    await _sharedPrefs.setBool(key, value);
  }

  int getInt(String key) {
    return _sharedPrefs.getInt(key) ?? 0;
  }

  Future setInt(String key, int value) async {
    await _sharedPrefs.setInt(key, value);
  }

  String getString(String key) {
    return _sharedPrefs.getString(key) ?? '';
  }

  Future setString(String key, String value) async {
    await _sharedPrefs.setString(key, value);
  }
}
