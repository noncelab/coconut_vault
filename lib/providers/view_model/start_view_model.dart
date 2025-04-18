import 'dart:io';

import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/app_version_util.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:flutter/foundation.dart';

class StartViewModel extends ChangeNotifier {
  late final bool _hasSeenGuide;
  late final ConnectivityProvider _connectivityProvider;
  bool? _connectivityState;

  StartViewModel(this._connectivityProvider, this._hasSeenGuide) {
    if (!_hasSeenGuide) {
      // iOS는 앱을 삭제해도 secure storage에 데이터가 남아있음
      SecureStorageRepository().deleteAll();
    }
  }

  bool? get connectivityState => _connectivityState;
  bool get hasSeenGuide => _hasSeenGuide;

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
    final isRestorationPrepared = await UpdatePreparation.isRestorationPrepared();
    // 복원파일 유무를 확인합니다.
    if (isRestorationPrepared) {
      // 복원파일 있음
      if (await AppVersionUtil.isAppVersionUpdated()) {
        // 업데이트 완료
        return AppEntryFlow.pinCheckForRestoration;
      } else {
        // 업데이트 하지 않음
        return AppEntryFlow.foundBackupFile;
      }
    }

    /// 비밀번호 등록 되어 있더라도, 추가한 볼트가 없는 경우는 볼트 리스트 화면으로 이동합니다.
    if (_isWalletExistent()) {
      return AppEntryFlow.pinCheck;
    }
    // 복원파일 없음 - 일반적인 최초 진입 흐름
    return AppEntryFlow.vaultList;
  }
}
