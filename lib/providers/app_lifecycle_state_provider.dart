// lib/providers/app_lifecycle_provider.dart

import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/logger.dart';

class AppLifecycleOperations {
  // 생체인증 관련
  static const String biometricAuthentication = 'biometric_auth';

  // 보안 영역 접근 관련 (TEE / StrongBox / Secure Enclave)
  static const String hwBasedEncryption = 'hw_based_encryption';
  static const String hwBasedDecryption = 'hw_based_decryption';

  // 보안 관련
  static const String cameraAuthRequest = 'camera_auth_request';
  static const String pastAuthRequest = 'past_auth_request';
}

class AppLifecycleStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  static final AppLifecycleStateProvider _instance = AppLifecycleStateProvider._internal();
  factory AppLifecycleStateProvider() => _instance;
  AppLifecycleStateProvider._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  // 콜백 함수들
  VoidCallback? _onAppGoBackground;
  VoidCallback? _onAppGoInactive;
  VoidCallback? _onAppGoActive;

  bool _isDisposed = false;

  // 현재 앱 라이프사이클 상태
  AppLifecycleState _currentState = AppLifecycleState.resumed;
  AppLifecycleState get currentState => _currentState;

  // inactive 상태 전환을 무시해야 하는 작업들
  final Set<String> _ignoredOperations = <String>{};
  Set<String> get ignoredOperations => Set.unmodifiable(_ignoredOperations);

  // 특정 작업이 진행 중인지 확인
  bool isOperationInProgress(String operationId) => _ignoredOperations.contains(operationId);

  // 전체적으로 무시해야 하는 작업이 있는지 확인
  bool get shouldIgnoreLifecycleEvent => _ignoredOperations.isNotEmpty;

  // 작업 시작 (inactive 상태 전환 무시)
  void startOperation(String operationId, {bool ignoreNotify = false}) {
    _ignoredOperations.add(operationId);
    Logger.log('AppLifecycle: 작업 시작 - $operationId (총 ${_ignoredOperations.length}개)');
    if (ignoreNotify) return;
    notifyListeners();
  }

  // 작업 완료
  Future<void> endOperation(String operationId) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _ignoredOperations.remove(operationId);
    Logger.log('AppLifecycle: 작업 완료 - $operationId (총 ${_ignoredOperations.length}개)');
    notifyListeners();
  }

  // 모든 작업 완료
  void endAllOperations() {
    _ignoredOperations.clear();
    Logger.log('AppLifecycle: 모든 작업 완료');
    notifyListeners();
  }

  void registerCallbacks({
    VoidCallback? onAppGoBackground,
    VoidCallback? onAppGoInactive,
    VoidCallback? onAppGoActive,
  }) {
    _onAppGoBackground = onAppGoBackground;
    _onAppGoInactive = onAppGoInactive;
    _onAppGoActive = onAppGoActive;
  }

  void unregisterAllCallbacks() {
    _onAppGoBackground = null;
    _onAppGoInactive = null;
    _onAppGoActive = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    _currentState = state;

    switch (state) {
      case AppLifecycleState.paused:
        Logger.log('-->AppLifecycle: Paused');
        _onAppGoBackground?.call();
        break;

      case AppLifecycleState.inactive:
        Logger.log('-->AppLifecycle: Inactive');

        // 무시해야 하는 작업이 진행 중인 경우 inactive 콜백 호출하지 않음
        if (shouldIgnoreLifecycleEvent) {
          Logger.log('--> ㄴAppLifecycle: Inactive 무시 (진행 중인 작업: ${_ignoredOperations.join(", ")})');
          return;
        }

        _onAppGoInactive?.call();
        break;

      case AppLifecycleState.resumed:
        Logger.log('-->AppLifecycle: Resumed');
        // 무시해야 하는 작업이 진행 중인 경우 inactive 콜백 호출하지 않음
        if (shouldIgnoreLifecycleEvent) {
          Logger.log('--> ㄴAppLifecycle: Resumed 무시 (진행 중인 작업: ${_ignoredOperations.join(", ")})');
          return;
        }

        _onAppGoActive?.call();
        break;

      case AppLifecycleState.detached:
        Logger.log('-->AppLifecycle: Detached');
        break;

      case AppLifecycleState.hidden:
        Logger.log('-->AppLifecycle: Hidden');
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void disposeWhenVaultReset() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }
}
