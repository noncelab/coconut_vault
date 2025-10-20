// lib/providers/app_lifecycle_provider.dart

import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/logger.dart';

class AppLifecycleOperations {
  // 생체인증 관련
  static const String biometricAuthentication = 'biometric_auth';
  static const String biometricSetup = 'biometric_setup';

  // TEE 관련
  static const String teeKeyGeneration = 'tee_key_generation';
  static const String teeEncryption = 'tee_encryption';
  static const String teeDecryption = 'tee_decryption';

  // 보안 관련
  static const String secureStorage = 'secure_storage';
  static const String keychainAccess = 'keychain_access';
}

class AppLifecycleStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  static final AppLifecycleStateProvider _instance = AppLifecycleStateProvider._internal();
  factory AppLifecycleStateProvider() => _instance;
  AppLifecycleStateProvider._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  // 현재 앱 라이프사이클 상태
  AppLifecycleState _currentState = AppLifecycleState.resumed;
  AppLifecycleState get currentState => _currentState;

  // inactive 상태 전환을 무시해야 하는 작업들
  final Set<String> _ignoredOperations = <String>{};

  // 특정 작업이 진행 중인지 확인
  bool isOperationInProgress(String operationId) => _ignoredOperations.contains(operationId);

  // 전체적으로 무시해야 하는 작업이 있는지 확인
  bool get shouldIgnoreInactiveTransition => _ignoredOperations.isNotEmpty;

  // 작업 시작 (inactive 상태 전환 무시)
  void startOperation(String operationId) {
    _ignoredOperations.add(operationId);
    Logger.log('AppLifecycle: 작업 시작 - $operationId (총 ${_ignoredOperations.length}개)');
    notifyListeners();
  }

  // 작업 완료
  void endOperation(String operationId) {
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

  // 콜백 함수들
  VoidCallback? onAppGoBackground;
  VoidCallback? onAppGoInactive;
  VoidCallback? onAppGoActive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;

    switch (state) {
      case AppLifecycleState.paused:
        Logger.log('-->AppLifecycle: Paused');
        onAppGoBackground?.call();
        break;

      case AppLifecycleState.inactive:
        Logger.log('-->AppLifecycle: Inactive');

        // 무시해야 하는 작업이 진행 중인 경우 inactive 콜백 호출하지 않음
        if (shouldIgnoreInactiveTransition) {
          Logger.log('-->AppLifecycle: Inactive 무시 (진행 중인 작업: ${_ignoredOperations.join(", ")})');
          return;
        }

        onAppGoInactive?.call();
        break;

      case AppLifecycleState.resumed:
        Logger.log('-->AppLifecycle: Resumed');
        onAppGoActive?.call();
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
