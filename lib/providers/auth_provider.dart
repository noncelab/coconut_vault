import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:coconut_vault/services/security/first_launch_secure_storage_cleanup.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthProvider extends ChangeNotifier {
  final AppLifecycleStateProvider _lifecycleProvider = AppLifecycleStateProvider();

  static String unlockAvailableAtKey = SharedPrefsKeys.kUnlockAvailableAt;
  static String turnKey = SharedPrefsKeys.kPinInputTurn;
  static String currentAttemptKey = SharedPrefsKeys.kPinInputCurrentAttemptCount;

  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();
  final PinAuthService _pinAuth;
  late final Future<void> ready;
  bool _authenticationUnavailable = true;
  bool get authenticationUnavailable => _authenticationUnavailable;

  Future<void> _initializeAuthentication() async {
    try {
      await FirstLaunchSecureStorageCleanup.run();
      final metadata = await _pinAuth.initialize();
      final hasPin = await _pinAuth.hasPin();
      if (metadata != null || hasPin) {
        _isPinSet = hasPin;
        if (hasPin && metadata != null) _isPinCharacter = metadata['character'] as bool;
        await _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, _isPinSet);
        await _sharedPrefs.setBool(SharedPrefsKeys.isPinCharacter, _isPinCharacter);
      }
      _syncLockState();
      _authenticationUnavailable = false;
    } catch (_) {
      _authenticationUnavailable = true;
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _ensureReady() async {
    await ready;
    if (_authenticationUnavailable) throw const PinAuthException();
  }

  void _syncLockState() {
    _currentTurn = _pinAuth.state.turn;
    _currentAttemptInTurn = _pinAuth.state.attempts;
    _unlockAvailableAtInString = _pinAuth.state.unlockAt;
  }

  final LocalAuthentication _auth = LocalAuthentication();

  /// dispose 상태 추적
  bool _isDisposed = false;

  /// 비밀번호 설정 여부
  bool _isPinSet = false;
  bool get isPinSet => _isPinSet;

  /// 문자 패스워드 여부
  bool _isPinCharacter = false;
  bool get isPinCharacter => _isPinCharacter;

  /// 리셋 여부
  bool _hasAlreadyRequestedBioPermission = false;
  bool get hasAlreadyRequestedBioPermission => _hasAlreadyRequestedBioPermission;

  /// 생체인증 하드웨어가 있는지 확인 (등록 여부 무관)
  bool _isBiometricSupportedByDevice = false;
  bool get isBiometricSupportedByDevice => _isBiometricSupportedByDevice;

  List<BiometricType> _availableBiometrics = [];
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  /// 사용자 생체 인증 on/off 여부
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  /// 생체인식 인증 활성화 여부
  bool get isBiometricsAuthEnabled => _isBiometricSupportedByDevice && _isBiometricEnabled;

  /// 잠금 해제 시도 정보
  int _currentTurn = 0;
  int get currentTurn => _currentTurn;
  int _currentAttemptInTurn = 0;
  int get currentAttemptInTurn => _currentAttemptInTurn;
  String _unlockAvailableAtInString = '';
  DateTime? get unlockAvailableAt {
    if (_unlockAvailableAtInString.isNotEmpty) {
      return DateTime.tryParse(_unlockAvailableAtInString);
    }

    // 이전에 잠긴 이력 X
    if (_currentTurn == 0) {
      return null;
    }

    // 디버깅 딜레이: 7초
    if (kDebugMode) {
      return DateTime.now().add(const Duration(seconds: kDebugPinInputDelay));
    }

    // 잠금 시도 횟수(_currentTurn)의 인덱스에 해당하는 잠금 해제 대기 시간
    return DateTime.now().add(Duration(minutes: kLockoutDurationsPerTurn[_currentTurn - 1]));
  }

  int get remainingAttemptCount => kMaxAttemptPerTurn - _currentAttemptInTurn;

  bool get isPermanentlyLocked => _currentTurn == kMaxTurn;
  bool get isUnlockAvailable =>
      !_authenticationUnavailable && !isPermanentlyLocked && (unlockAvailableAt?.isBefore(DateTime.now()) ?? true);

  FutureOr<void> Function()? onAuthenticationSuccess;

  AuthProvider({PinAuthService? pinAuth, bool initializeDeviceBiometrics = true})
    : _pinAuth = pinAuth ?? PinAuthService.instance {
    if (initializeDeviceBiometrics) updateDeviceBiometricAvailability();
    setInitState();
    ready = _initializeAuthentication();
  }

  /// 생체인증 성공했는지 여부 반환
  Future<bool> isBiometricsAuthValid({bool isSaved = false}) async {
    if (!isBiometricEnabled) return false;
    return await authenticateWithBiometrics(isSaved: isSaved);
  }

  /// 주의: secure zone의 decrypt 직전 사용. 아이폰이거나 생체인증이 켜져 있는 경우 생체인증을 진행하지 않음.
  /// secure zone의 decrypt과정에서 생체인증하기 때문에 연달아 2번 인증 되는 것을 방지
  Future<bool> isBiometricsAuthValidToAvoidDoubleAuth({bool isSaved = false}) async {
    if (Platform.isIOS && isBiometricsAuthEnabled) return true;

    return await isBiometricsAuthValid(isSaved: isSaved);
  }

  void setInitState() {
    if (_isDisposed) return;

    _isPinSet = _sharedPrefs.getBool(SharedPrefsKeys.isPinEnabled) == true;
    _isPinCharacter = _sharedPrefs.getBool(SharedPrefsKeys.isPinCharacter) == true;
    _loadBiometricState();
    notifyListeners();
  }

  void _loadBiometricState() {
    _isBiometricEnabled = _sharedPrefs.getBool(SharedPrefsKeys.isBiometricEnabled) == true;
    _hasAlreadyRequestedBioPermission = _sharedPrefs.getBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission) == true;
  }

  /// 생체인증 진행 후 성공 여부 반환
  Future<bool> authenticateWithBiometrics({BuildContext? context, bool isSaved = false}) async {
    await _ensureReady();
    bool authenticated = false;
    _lifecycleProvider.startOperation(AppLifecycleOperations.biometricAuthentication);
    try {
      authenticated = await _auth.authenticate(
        localizedReason:
            isSaved
                ? t.permission.biometric.ask_to_use
                : t
                    .permission
                    .biometric
                    .proceed_biometric_auth, // 이 문구는 aos, iOS(touch ID)에서 사용됩니다. ios face ID는 info.plist string을 사용합니다.
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (isSaved) {
        await saveIsBiometricEnabled(authenticated);
        await _setHasAlreadyRequestedBioPermissionTrue();
      }
    } on PlatformException catch (e) {
      Logger.log('Biometric authentication unavailable');

      /// iOS는 생체인증 권한을 요청하기 때문에 사용자가 거절할 수 있음
      /// 거절하면 _auth.getAvailableBiometrics() 결과는 빈 배열이 반환되므로 직접 수정
      if (Platform.isIOS && !authenticated && e.code == 'NotAvailable' && !_hasAlreadyRequestedBioPermission) {
        _availableBiometrics = [];
        notifyListeners();
      }

      if (isSaved) {
        await saveIsBiometricEnabled(false);
        await _setHasAlreadyRequestedBioPermissionTrue();
      }
    } finally {
      _lifecycleProvider.endOperation(
        AppLifecycleOperations.biometricAuthentication,
        delay: const Duration(milliseconds: 3000),
      );
    }
    return authenticated;
  }

  Future<void> _setHasAlreadyRequestedBioPermissionTrue() async {
    if (_isDisposed || _hasAlreadyRequestedBioPermission) return;

    _hasAlreadyRequestedBioPermission = true;
    await _sharedPrefs.setBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission, true);
  }

  /// 기기의 생체인증 가능 여부 업데이트
  Future<void> updateDeviceBiometricAvailability() async {
    try {
      // 생체인증 지원 여부 (등록과 무관)
      final hasBiometrics = await _auth.canCheckBiometrics;
      if (!hasBiometrics) {
        _isBiometricSupportedByDevice = false;
        _isBiometricEnabled = false;
        return;
      }
      _isBiometricSupportedByDevice = true;

      // 빈 배열이면 앱 권한을 거부했거나 등록한 생체인증이 없는 경우
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      _availableBiometrics = availableBiometrics;
      if (_availableBiometrics.isEmpty) {
        _isBiometricEnabled = false;
      }
    } catch (e) {
      // 생체 인식 기능 비활성화, 사용자가 권한 거부, 기기 하드웨어에 문제가 있는 경우, 기기 호환성 문제, 플랫폼 제한
      Logger.error('Biometric availability check failed');
      _isBiometricSupportedByDevice = false;
      _isBiometricEnabled = false;
    } finally {
      // dispose된 상태에서는 notifyListeners 호출하지 않음
      if (!_isDisposed) {
        await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, _isBiometricEnabled);
        notifyListeners();
      }
    }
  }

  /// 사용자 생체인증 활성화 여부 저장
  Future<void> saveIsBiometricEnabled(bool value) async {
    if (_isDisposed) return;

    _isBiometricEnabled = value;
    await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, value);
    notifyListeners();
  }

  Future<void> verifyBiometric(BuildContext context) async {
    bool isAuthenticated = await authenticateWithBiometrics(context: context);
    if (isAuthenticated) {
      await resetAuthenticationState();
      if (onAuthenticationSuccess != null) {
        await onAuthenticationSuccess!();
      }
    }
  }

  // util: 비밀번호 입력 패드 생성
  List<String> getShuffledNumberList({isPinSettingContext = false}) {
    final random = Random();
    var randomNumberPad = List<String>.generate(10, (index) => index.toString());
    randomNumberPad.shuffle(random);
    randomNumberPad.insert(
      randomNumberPad.length - 1,
      !isPinSettingContext && _isBiometricEnabled ? kBiometricIdentifier : '',
    );
    randomNumberPad.add(kDeleteBtnIdentifier);
    return randomNumberPad;
  }

  /// 비밀번호 검증
  Future<bool> verifyPin(String inputPin, {bool isAppLaunchScreen = false}) async {
    await _ensureReady();
    try {
      return await _pinAuth.verify(inputPin, countFailure: isAppLaunchScreen, character: _isPinCharacter);
    } finally {
      _syncLockState();
    }
  }

  /// 비밀번호 및 유형 저장
  Future<void> savePin(String pin, bool isCharacter) async {
    if (_isDisposed) return;

    if (_isBiometricEnabled && _isBiometricSupportedByDevice && !_isPinSet) {
      _isBiometricEnabled = true;
      await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, true);
    }

    await _ensureReady();
    await _pinAuth.savePin(pin, isCharacter);
    _isPinSet = true;
    _isPinCharacter = isCharacter;
    await _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, true);
    await _sharedPrefs.setBool(SharedPrefsKeys.isPinCharacter, isCharacter);
    notifyListeners();
  }

  Future<void> setIsPinSet(bool value) async {
    _isPinSet = value;
    await _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, value);
    notifyListeners();
  }

  Future<void> resetCredentials({bool preservePermanentLock = false, bool afterWalletDeletion = false}) async {
    if (_isDisposed) return;

    await ready;
    if (afterWalletDeletion) {
      await _pinAuth.resetAfterWalletDeletion(preservePermanentLock: preservePermanentLock);
    } else {
      await _pinAuth.disable(preservePermanentLock: preservePermanentLock);
    }
    _syncLockState();
    _authenticationUnavailable = false;
    await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    _isBiometricEnabled = false;
    await _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    _isPinSet = false;
    notifyListeners();
  }

  Future<void> clearPermanentLock() async {
    if (_isDisposed) return;

    await _ensureReady();
    await _pinAuth.reset();
    _syncLockState();
    notifyListeners();
  }

  Future<void> resetPinData() async {
    await _ensureReady();
    await _pinAuth.disable();
    _syncLockState();
    _isPinSet = false;
    await _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    notifyListeners();
  }

  Future<void> increaseCurrentAttemptAndTurn() async {
    if (_isDisposed) return;
    await _ensureReady();
    await _pinAuth.increase();
    _syncLockState();
  }

  Future<void> resetAuthenticationState({bool preservePermanentLock = false}) async {
    if (_isDisposed) return;
    await _ensureReady();
    await _pinAuth.reset(preservePermanentLock: preservePermanentLock);
    _syncLockState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
