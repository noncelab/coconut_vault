import 'dart:async';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsRepository {
  late SharedPreferences _sharedPrefs;
  SharedPreferences get sharedPrefs => _sharedPrefs;

  static final SharedPrefsRepository _instance = SharedPrefsRepository._internal();

  factory SharedPrefsRepository() => _instance;

  SharedPrefsRepository._internal();

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

  Future<void> deleteSharedPrefsWithKey(String key) async {
    await _sharedPrefs.remove(key);
  }

  bool? getBool(String key) {
    return _sharedPrefs.getBool(key);
  }

  Future setBool(String key, bool value) async {
    await _sharedPrefs.setBool(key, value);
  }

  int? getInt(String key) {
    return _sharedPrefs.getInt(key);
  }

  Future setInt(String key, int value) async {
    await _sharedPrefs.setInt(key, value);
  }

  String getString(String key) {
    return _sharedPrefs.getString(key) ?? '';
  }

  Future<bool> setString(String key, String value) async {
    return _sharedPrefs.setString(key, value);
  }

  double? getDouble(String key) {
    return _sharedPrefs.getDouble(key);
  }

  Future setDouble(String key, double value) async {
    await _sharedPrefs.setDouble(key, value);
  }

  /// Taproot `older` → `after` backup 정보 업데이트 안내를 아직 확인하지 않은 지갑 ID를 관리합니다.
  Set<int> getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate() {
    final ids =
        _sharedPrefs.getStringList(SharedPrefsKeys.kWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate) ??
        const <String>[];
    return ids.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> addWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate(Iterable<int> walletIds) async {
    final ids = getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate()..addAll(walletIds);
    await _sharedPrefs.setStringList(
      SharedPrefsKeys.kWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate,
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<void> addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate(int walletId) async {
    await addWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate([walletId]);
  }

  Future<void> removeWalletIdWithUnacknowledgedOlderToAfterBackupUpdate(int walletId) async {
    final ids = getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate()..remove(walletId);
    await _sharedPrefs.setStringList(
      SharedPrefsKeys.kWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate,
      ids.map((id) => id.toString()).toList(),
    );
  }

  bool hasUnacknowledgedOlderToAfterBackupUpdate(int walletId) {
    return getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate().contains(walletId);
  }
}
