import 'package:flutter/material.dart';

class VaultListRestorationViewModel extends ChangeNotifier {
  late bool _isVaultListRestored;

  VaultListRestorationViewModel() {
    _isVaultListRestored = false;
  }

  bool get isVaultListRestored => _isVaultListRestored;
  int get vaultListCount => 3;

  void restoreVaultList() {
    // 실제 복원 로직으로 변경
    Future.delayed(const Duration(milliseconds: 3000), () {
      _isVaultListRestored = true;
      notifyListeners();
    });
  }
}
