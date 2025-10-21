import 'dart:convert';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/material.dart';

class PreferenceProvider extends ChangeNotifier {
  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();

  /// 지갑 순서
  late List<int> _vaultOrder;
  List<int> get vaultOrder => _vaultOrder;

  /// 지갑 즐겨찾기 목록
  late List<int> _favoriteVaultIds;
  List<int> get favoriteVaultIds => _favoriteVaultIds;

  bool get isSigningOnlyMode => getVaultMode() == VaultMode.signingOnly;

  late (double?, double?) _signingModeEdgePanelPos;
  (double?, double?) get signingModeEdgePanelPos => _signingModeEdgePanelPos;

  PreferenceProvider() {
    _vaultOrder = _getVaultOrder();
    _favoriteVaultIds = _getFavoriteVaultIds();
    _signingModeEdgePanelPos = getSigningModeEdgePanelPos();
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
    if (!isSigningOnlyMode) {
      await _sharedPrefs.setString(SharedPrefsKeys.kVaultOrder, jsonEncode(vaultOrder));
    }
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
    if (!isSigningOnlyMode) {
      await _sharedPrefs.setString(SharedPrefsKeys.kFavoriteVaultIds, jsonEncode(favoriteVaultIds));
    }
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
    if (!isSigningOnlyMode) {
      await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultOrder);
      await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kFavoriteVaultIds);
    }
    notifyListeners();
  }

  Future<void> setVaultMode(VaultMode vaultMode) async {
    if (isSigningOnlyMode && vaultMode == VaultMode.secureStorage) {
      await _sharedPrefs.setString(SharedPrefsKeys.kVaultOrder, jsonEncode(vaultOrder));
      await _sharedPrefs.setString(SharedPrefsKeys.kFavoriteVaultIds, jsonEncode(favoriteVaultIds));
    }
    if (!isSigningOnlyMode && vaultMode == VaultMode.signingOnly) {
      await resetVaultOrderAndFavorites();
    }
    await _sharedPrefs.setString(SharedPrefsKeys.kVaultMode, vaultMode.name);
    notifyListeners();
  }

  VaultMode? getVaultMode() {
    final vaultMode = _sharedPrefs.getString(SharedPrefsKeys.kVaultMode);
    if (vaultMode.isEmpty) return null;
    return VaultMode.values.firstWhere((e) => e.name == vaultMode);
  }

  Future<void> setSigningModeEdgePanelPos(double posX, double posY) async {
    _signingModeEdgePanelPos = (posX, posY);
    await _sharedPrefs.setDouble(SharedPrefsKeys.kSigningModeEdgePanelPosX, _signingModeEdgePanelPos.$1!);
    await _sharedPrefs.setDouble(SharedPrefsKeys.kSigningModeEdgePanelPosY, _signingModeEdgePanelPos.$2!);
    notifyListeners();
  }

  // TODO: 호출 시 null인데 확인하기
  (double?, double?) getSigningModeEdgePanelPos() {
    final posX = _sharedPrefs.getDouble(SharedPrefsKeys.kSigningModeEdgePanelPosX);
    final posY = _sharedPrefs.getDouble(SharedPrefsKeys.kSigningModeEdgePanelPosY);
    _signingModeEdgePanelPos = (posX, posY);
    return _signingModeEdgePanelPos;
  }

  Future<void> resetSigningModeEdgePanelPos() async {
    await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kSigningModeEdgePanelPosX);
    await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kSigningModeEdgePanelPosY);
    _signingModeEdgePanelPos = (null, null);
    notifyListeners();
  }
}
