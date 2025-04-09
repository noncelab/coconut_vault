import 'package:flutter/material.dart';

class VaultListRestorationViewModel extends ChangeNotifier {
  late bool _isVaultListRestored;
  late List<DummyVault> _dummyVaultList;

  VaultListRestorationViewModel() {
    _isVaultListRestored = false;
    _dummyVaultList = [
      DummyVault(
          walletName: 'wallet 1',
          iconIndex: 0,
          colorIndex: 0,
          masterFingerPrint: "00000"),
      DummyVault(
          walletName: 'wallet 2',
          iconIndex: 1,
          colorIndex: 1,
          masterFingerPrint: "00000"),
      DummyVault(
          walletName: 'wallet 3',
          iconIndex: 2,
          colorIndex: 2,
          masterFingerPrint: "00000"),
      DummyVault(
          walletName: 'wallet 4',
          iconIndex: 3,
          colorIndex: 3,
          masterFingerPrint: "00000"),
      DummyVault(
          walletName: 'wallet 5',
          iconIndex: 4,
          colorIndex: 4,
          masterFingerPrint: "00000"),
      DummyVault(
          walletName: 'wallet 6',
          iconIndex: 5,
          colorIndex: 5,
          masterFingerPrint: "00000"),
      DummyVault(
          walletName: 'wallet 7',
          iconIndex: 6,
          colorIndex: 6,
          masterFingerPrint: "00000"),
      DummyVault(
          walletName: 'wallet 8',
          iconIndex: 7,
          colorIndex: 7,
          masterFingerPrint: "00000"),
    ];
  }

  bool get isVaultListRestored => _isVaultListRestored;
  List<DummyVault> get vaultList => _dummyVaultList;
  int get vaultListCount => _dummyVaultList.length;

  void restoreVaultList() {
    // 실제 복원 로직으로 변경
    Future.delayed(const Duration(milliseconds: 3000), () {
      _isVaultListRestored = true;
      notifyListeners();
    });
  }
}

class DummyVault {
  final String walletName;
  final int iconIndex;
  final int colorIndex;
  final String masterFingerPrint;

  DummyVault(
      {required this.walletName,
      required this.iconIndex,
      required this.colorIndex,
      required this.masterFingerPrint});
}
