import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/material.dart';

class VisibilityProvider extends ChangeNotifier {
  late bool _hasSeenGuide;
  late int _walletCount;
  late bool _isPassphraseUseEnabled;

  bool get hasSeenGuide => _hasSeenGuide;
  int get walletCount => _walletCount;
  bool get isPassphraseUseEnabled => _isPassphraseUseEnabled;

  /// TODO: 제거
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  VisibilityProvider() {
    final prefs = SharedPrefsRepository();
    _hasSeenGuide = !NetworkType.currentNetworkType.isTestnet ||
        prefs.getBool(SharedPrefsKeys.hasShownStartGuide) == true;
    _walletCount = prefs.getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    _isPassphraseUseEnabled = prefs.getBool(SharedPrefsKeys.kPassphraseUseEnabled) ?? false;
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
