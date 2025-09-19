import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthProvider extends ChangeNotifier {
  static String unlockAvailableAtKey = SharedPrefsKeys.kUnlockAvailableAt;
  static String turnKey = SharedPrefsKeys.kPinInputTurn;
  static String currentAttemptKey = SharedPrefsKeys.kPinInputCurrentAttemptCount;

  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();
  final SecureStorageRepository _storageService = SecureStorageRepository();

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

  // 디바이스가 생체인증을 '지원'하는가
  bool _isBiometricSupportedByDevice = false;
  bool get isBiometricSupportedByDevice => _isBiometricSupportedByDevice;

  /// 등록된 생체인증 존재 여부
  bool _hasEnrolledBiometricsInDevice = false;
  bool get hasEnrolledBiometricsInDevice => _hasEnrolledBiometricsInDevice;

  /// 사용자 생체 인증 on/off 여부
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  /// 사용자 생체인증 권한 허용 여부
  bool _hasBiometricsPermission = false;
  bool get hasBiometricsPermission => _hasBiometricsPermission;

  /// 인증 활성화 여부
  bool get isAuthEnabled => _isPinSet;

  /// 생체인식 인증 활성화 여부
  bool get isBiometricsAuthEnabled => _hasEnrolledBiometricsInDevice && _isBiometricEnabled;

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
  bool get isPermanantlyLocked => _currentTurn == kMaxTurn;
  bool get isUnlockAvailable => unlockAvailableAt?.isBefore(DateTime.now()) ?? true;

  VoidCallback? onRequestShowAuthenticationFailedDialog;
  VoidCallback? onBiometricAuthFailed; // 현재 사용하는 곳 없음
  VoidCallback? onAuthenticationSuccess;

  AuthProvider() {
    updateDeviceBiometricAvailability();
    setInitState();
  }

  /// 생체인증 성공했는지 여부 반환
  Future<bool> isBiometricsAuthValid() async {
    return isBiometricsAuthEnabled && await authenticateWithBiometrics();
  }

  void setInitState() {
    if (_isDisposed) return;

    _isPinSet = _sharedPrefs.getBool(SharedPrefsKeys.isPinEnabled) == true;
    _isPinCharacter = _sharedPrefs.getBool(SharedPrefsKeys.isPinCharacter) == true;
    _loadBiometricState();
    _loadUnlockState();
    notifyListeners();
  }

  void _loadBiometricState() {
    _isBiometricEnabled = _sharedPrefs.getBool(SharedPrefsKeys.isBiometricEnabled) == true;
    _hasBiometricsPermission =
        _sharedPrefs.getBool(SharedPrefsKeys.hasBiometricsPermission) == true;
    _hasAlreadyRequestedBioPermission =
        _sharedPrefs.getBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission) == true;
  }

  void _loadUnlockState() {
    final pinInputAttemptCount = _sharedPrefs.getString(currentAttemptKey);
    final totalAttemptCount = _sharedPrefs.getString(turnKey);
    final lockoutEndDateTimeString = _sharedPrefs.getString(unlockAvailableAtKey);

    _currentAttemptInTurn = pinInputAttemptCount.isEmpty ? 0 : int.parse(pinInputAttemptCount);
    _currentTurn = totalAttemptCount.isEmpty ? 0 : int.parse(totalAttemptCount);
    _unlockAvailableAtInString = totalAttemptCount.isEmpty ? '' : lockoutEndDateTimeString;
  }

  /// 생체인증 진행 후 성공 여부 반환
  Future<bool> authenticateWithBiometrics(
      {BuildContext? context,
      bool showAuthenticationFailedDialog = true,
      bool isSaved = false}) async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: isSaved
            ? t.permission.biometric.ask_to_use
            : t.permission.biometric
                .proceed_biometric_auth, // 이 문구는 aos, iOS(touch ID)에서 사용됩니다. ios face ID는 info.plist string을 사용합니다.
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (Platform.isIOS && !authenticated) {
        if (context != null && context.mounted && onRequestShowAuthenticationFailedDialog != null) {
          onRequestShowAuthenticationFailedDialog!();
        }
      }

      if (isSaved) {
        saveIsBiometricEnabled(authenticated);
        _setHasAlreadyRequestedBioPermissionTrue();
      }

      return authenticated;
    } on PlatformException catch (e) {
      Logger.log(e);

      if (isSaved) {
        saveIsBiometricEnabled(false);
        if (Platform.isIOS &&
            !authenticated &&
            e.message == 'Biometry is not available.' &&
            showAuthenticationFailedDialog) {
          if (context != null &&
              context.mounted &&
              onRequestShowAuthenticationFailedDialog != null) {
            onRequestShowAuthenticationFailedDialog!();
          }
        }
        _setHasAlreadyRequestedBioPermissionTrue();
      }
    }
    return false;
  }

  Future<void> _setHasAlreadyRequestedBioPermissionTrue() async {
    if (_isDisposed || _hasAlreadyRequestedBioPermission) return;

    _hasAlreadyRequestedBioPermission = true;
    await _sharedPrefs.setBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission, true);
  }

  /// 기기의 생체인증 가능 여부 업데이트
  /// - isBiometricSupportedByDevice: 하드웨어/OS 지원 여부 (등록 여부와 무관)
  /// - canCheckBiometrics: 등록되어 현재 인증 시도 가능한지
  /// 또한 isBiometricEnabled(앱 설정) 조정 및 SharedPrefs 반영
  Future<void> updateDeviceBiometricAvailability() async {
    try {
      // 1) 장치 지원 여부 (등록과 무관)
      _isBiometricSupportedByDevice = await _auth.isDeviceSupported();
      if (!_isBiometricSupportedByDevice) {
        _hasEnrolledBiometricsInDevice = false;
        _isBiometricEnabled = false;
        return;
      }

      // 2) 등록된 생체정보가 있어 인증 시도 가능한가
      // getAvailableBiometrics까지  조회하는 이유는 일부 안드로이드 기기에서 canCheckBiometrics가 true인데 실제로는 등록 안된 경우도 있기 때문
      final hasBiometrics = await _auth.canCheckBiometrics;
      if (!hasBiometrics) {
        _hasEnrolledBiometricsInDevice = false;
        return;
      }
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      _hasEnrolledBiometricsInDevice = availableBiometrics.isNotEmpty;
      if (!_hasEnrolledBiometricsInDevice) {
        _isBiometricEnabled = false;
      }
    } catch (e) {
      // 생체 인식 기능 비활성화, 사용자가 권한 거부, 기기 하드웨어에 문제가 있는 경우, 기기 호환성 문제, 플랫폼 제한
      Logger.log(e);
      _isBiometricSupportedByDevice = false;
      _hasEnrolledBiometricsInDevice = false;
      _isBiometricEnabled = false;
    } finally {
      // dispose된 상태에서는 notifyListeners 호출하지 않음
      if (!_isDisposed) {
        _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, _isBiometricEnabled);
        notifyListeners();
      }
    }
  }

  /// 사용자 생체인증 활성화 여부 저장
  Future<void> saveIsBiometricEnabled(bool value) async {
    if (_isDisposed) return;

    _isBiometricEnabled = value;
    _hasBiometricsPermission = value;
    await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, value);
    await _sharedPrefs.setBool(SharedPrefsKeys.hasBiometricsPermission, value);
    notifyListeners();
  }

  void verifyBiometric(BuildContext context) async {
    bool isAuthenticated = await authenticateWithBiometrics(
      context: context,
      showAuthenticationFailedDialog: false,
    );
    if (isAuthenticated) {
      if (onAuthenticationSuccess != null) {
        onAuthenticationSuccess!();
      }
      resetAuthenticationState();
    }
  }

  // util: 비밀번호 입력 패드 생성
  List<String> getShuffledNumberList({isPinSettingContext = false}) {
    final random = Random();
    var randomNumberPad = List<String>.generate(10, (index) => index.toString());
    randomNumberPad.shuffle(random);
    randomNumberPad.insert(randomNumberPad.length - 1,
        !isPinSettingContext && _isBiometricEnabled ? kBiometricIdentifier : '');
    randomNumberPad.add(kDeleteBtnIdentifier);
    return randomNumberPad;
  }

  /// 비밀번호 검증
  Future<bool> verifyPin(String inputPin, {bool isAppLaunchScreen = false}) async {
    String hashedInput = hashString(inputPin);
    final savedPin = await _storageService.read(key: SecureStorageKeys.kVaultPin);

    if (savedPin == hashedInput) {
      resetAuthenticationState();
      return true;
    }

    if (isAppLaunchScreen) {
      await increaseCurrentAttemptAndTurn();
    }
    return false;
  }

  /// 비밀번호 및 유형 저장
  Future<void> savePin(String pin, bool isCharacter) async {
    if (_isDisposed) return;

    if (_isBiometricEnabled && _hasEnrolledBiometricsInDevice && !_isPinSet) {
      _isBiometricEnabled = true;
      _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, true);
    }

    String hashed = hashString(pin);
    await _storageService.write(key: SecureStorageKeys.kVaultPin, value: hashed);
    _isPinSet = true;
    _isPinCharacter = isCharacter;
    _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, true);
    _sharedPrefs.setBool(SharedPrefsKeys.isPinCharacter, isCharacter);
    notifyListeners();
  }

  /// 비밀번호 초기화
  Future<void> resetPin(PreferenceProvider preferenceProvider) async {
    if (_isDisposed) return;

    final WalletRepository walletRepository = WalletRepository();
    await walletRepository.resetAll();

    _isBiometricEnabled = false;
    _isPinSet = false;
    await _storageService.delete(key: SecureStorageKeys.kVaultPin);
    await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    await _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    await _sharedPrefs.setInt(SharedPrefsKeys.vaultListLength, 0);
    await _sharedPrefs.setString(SharedPrefsKeys.kAppVersion, '');
    await preferenceProvider.resetVaultOrderAndFavorites();

    resetAuthenticationState();
  }

  // TODO: 딜레이 발생 이유
  /// 총 비밀번호 입력 시도 횟수, 다음 입력 가능 시간 저장
  Future<void> _setTurn(int turn) async {
    if (_isDisposed) return;

    await _sharedPrefs.setString(turnKey, turn.toString());

    if (turn == kMaxTurn) {
      await _sharedPrefs.setString(unlockAvailableAtKey, kPinInputDelayInfinite.toString());
      return;
    }

    /// INFO: 디버그 모드일 때는 잠금 시도 실패 횟수 별 딜레이를 늘리지 않습니다.
    final unlockableDateTime = DateTime.now().add(kDebugMode
        ? const Duration(seconds: kDebugPinInputDelay)
        : Duration(minutes: kLockoutDurationsPerTurn[turn - 1]));

    _unlockAvailableAtInString = unlockableDateTime.toIso8601String();
    await _sharedPrefs.setString(unlockAvailableAtKey, _unlockAvailableAtInString);
  }

  /// 비밀번호 입력 시도 횟수 -> shared preference 저장할 필요가 없음.
  Future<void> _setCurrentAttempt(int attmept) async {
    if (_isDisposed) return;

    final attemptCount = attmept.toString();
    await _sharedPrefs.setString(currentAttemptKey, attemptCount);
  }

  /// 비밀번호 입력 시도 횟수 증가
  /// 최대 횟수 도달 시, 잠금 해제 시도 횟수, 다음 시도 시간 저장, 시도 횟수 초기화
  Future<void> increaseCurrentAttemptAndTurn() async {
    if (_isDisposed) return;

    _currentAttemptInTurn++;
    _setCurrentAttempt(_currentAttemptInTurn);

    if (_currentAttemptInTurn == kMaxAttemptPerTurn) {
      _currentTurn++;
      await _setTurn(_currentTurn);

      _currentAttemptInTurn = 0;
      await _setCurrentAttempt(_currentAttemptInTurn);
    }
  }

  void resetAuthenticationState() {
    if (_isDisposed) return;

    _currentAttemptInTurn = 0;
    _currentTurn = 0;
    _unlockAvailableAtInString = '';

    _sharedPrefs.deleteSharedPrefsWithKey(unlockAvailableAtKey);
    _sharedPrefs.deleteSharedPrefsWithKey(currentAttemptKey);
    _sharedPrefs.deleteSharedPrefsWithKey(turnKey);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
