import 'dart:io';

import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:flutter/foundation.dart';

class SplashViewModel extends ChangeNotifier {
  late final bool _hasSeenGuide;
  late final ConnectivityProvider _connectivityProvider;
  //late final bool _isVaultModeSelected;
  bool? _connectivityState;

  // SplashViewModel(this._connectivityProvider, this._hasSeenGuide, this._isVaultModeSelected) {
  //   if (!_hasSeenGuide) {
  //     // iOS는 앱을 삭제해도 secure storage에 데이터가 남아있음
  //     SecureStorageRepository().deleteAll();
  //   }
  // }

  SplashViewModel(this._connectivityProvider, this._hasSeenGuide) {
    if (!_hasSeenGuide) {
      // iOS는 앱을 삭제해도 secure storage에 데이터가 남아있음
      SecureStorageRepository().deleteAll();
    }

    updateConnectivityState();
  }

  bool? get connectivityState => _connectivityState;
  bool get hasSeenGuide => _hasSeenGuide;
  //bool get isVaultModeSelected => _isVaultModeSelected;

  void updateConnectivityState() {
    var connectivityState = _getConnectivityState();
    if (_connectivityState == connectivityState) return;

    _connectivityState = connectivityState;
    notifyListeners();
  }

  bool? _getConnectivityState() {
    final isNetworkOn = _connectivityProvider.isNetworkOn;
    final isBluetoothOn = _connectivityProvider.isBluetoothOn;
    final isDeveloperModeOn = _connectivityProvider.isDeveloperModeOn;

    if (isNetworkOn == null || isBluetoothOn == null || isDeveloperModeOn == null) return null;

    if (Platform.isAndroid) {
      return isNetworkOn || isBluetoothOn || isDeveloperModeOn;
    }

    return isNetworkOn || isBluetoothOn;
  }
}
