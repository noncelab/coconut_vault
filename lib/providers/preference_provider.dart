import 'dart:convert';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/material.dart';

class PreferenceProvider extends ChangeNotifier {
  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();

  /// 언어 설정
  late String _language;
  String get language => _language;

  /// 지갑 순서
  late List<int> _vaultOrder;
  List<int> get vaultOrder => _vaultOrder;

  /// 지갑 즐겨찾기 목록
  late List<int> _favoriteVaultIds;
  List<int> get favoriteVaultIds => _favoriteVaultIds;

  PreferenceProvider() {
    _vaultOrder = _getVaultOrder();
    _favoriteVaultIds = _getFavoriteVaultIds();
  }

  /// 지갑 순서 불러오기
  List<int> _getVaultOrder() {
    final encoded = _sharedPrefs.getString(SharedPrefsKeys.kVaultOrder);
    if (encoded.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.cast<int>();
  }

  /// 지갑 순서 설정
  Future<void> setVaultOrder(List<int> vaultOrder) async {
    _vaultOrder = vaultOrder;
    await _sharedPrefs.setString(SharedPrefsKeys.kVaultOrder, jsonEncode(vaultOrder));
    notifyListeners();
  }

  /// 지갑 순서 단일 제거
  Future<void> removeVaultOrder(int vaultId) async {
    _vaultOrder.remove(vaultId);
    await setVaultOrder(_vaultOrder);
    notifyListeners();
  }

  /// 지갑 즐겨찾기 목록 불러오기
  List<int> _getFavoriteVaultIds() {
    final encoded = _sharedPrefs.getString(SharedPrefsKeys.kFavoriteVaultIds);
    if (encoded.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.cast<int>();
  }

  /// 지갑 즐겨찾기 목록 설정
  Future<void> setFavoriteVaultIds(List<int> favoriteVaultIds) async {
    _favoriteVaultIds = favoriteVaultIds;
    await _sharedPrefs.setString(SharedPrefsKeys.kFavoriteVaultIds, jsonEncode(favoriteVaultIds));
    notifyListeners();
  }

  /// 지갑 즐겨찾기 단일 제거
  Future<void> removeFavoriteVaultId(int vaultId) async {
    _favoriteVaultIds.remove(vaultId);
    await setFavoriteVaultIds(_favoriteVaultIds);
    notifyListeners();
  }

  Future<void> resetVaultOrderAndFavorites() async {
    _vaultOrder = [];
    _favoriteVaultIds = [];
    await _sharedPrefs.setString(SharedPrefsKeys.kVaultOrder, '');
    await _sharedPrefs.setString(SharedPrefsKeys.kFavoriteVaultIds, '');
    notifyListeners();
  }
}
