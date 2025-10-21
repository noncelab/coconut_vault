import 'dart:io';

import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/services/security_prechecker.dart';
import 'package:flutter/foundation.dart';

class StartViewModel extends ChangeNotifier {
  late final bool _hasSeenGuide;
  late final ConnectivityProvider _connectivityProvider;
  late final AuthProvider _authProvider;
  late final bool _isVaultModeSelected;
  bool? _connectivityState;

  StartViewModel(this._connectivityProvider, this._authProvider, this._hasSeenGuide, this._isVaultModeSelected) {
    if (!_hasSeenGuide) {
      // iOS는 앱을 삭제해도 secure storage에 데이터가 남아있음
      SecureStorageRepository().deleteAll();
    }
  }

  bool? get connectivityState => _connectivityState;
  bool get hasSeenGuide => _hasSeenGuide;
  bool get isVaultModeSelected => _isVaultModeSelected;

  bool _isWalletExistent() {
    return (SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0) > 0;
  }

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

  Future<AppEntryFlow> getNextEntryFlow() async {
    /// 0. 보안 검사 수행
    /// JailbreakDetection은 이미 거친 상태, checkDevicePassword부터 실행

    final securityResult = await SecurityPrechecker().checkDevicePassword();
    if (securityResult.status == SecurityCheckStatus.devicePasswordRequired) {
      return AppEntryFlow.devicePasswordRequired;
    }
    if (securityResult.status == SecurityCheckStatus.devicePasswordChanged) {
      return AppEntryFlow.devicePasswordChanged;
    }

    /// 1. 영구 잠금 상태라면 PinCheck 화면으로보내
    /// '초기화' 버튼을 누르게 해야함.
    if (_authProvider.isPermanentlyLocked) {
      return AppEntryFlow.pinCheckAppLaunched;
    }

    /// 2. 지갑이 없거나 PIN 설정이 되지 않은 경우,
    /// vaultHome으로 이동
    final hasWallet = _isWalletExistent();
    final hasPin = _authProvider.isPinSet;

    if (!hasWallet || !hasPin) {
      return AppEntryFlow.vaultHome;
    }

    /// 3. 생체인증 상태가 유효하다면 vaultHome으로 이동
    final biometricsValid = await _authProvider.isBiometricsAuthValid();
    if (biometricsValid) {
      return AppEntryFlow.vaultHome;
    }

    /// 4. 그 외의 경우, PinCheck 화면으로 이동
    return AppEntryFlow.pinCheckAppLaunched;
  }
}
