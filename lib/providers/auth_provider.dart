import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/managers/wallet_list_manager.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthProvider extends ChangeNotifier {
  static String unlockAvailableAtKey = SharedPrefsKeys.kUnlockAvailableAt;
  static String turnKey = SharedPrefsKeys.kPinInputTurn;
  static String currentAttemptKey =
      SharedPrefsKeys.kPinInputCurrentAttemptCount;

  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();
  final SecureStorageRepository _storageService = SecureStorageRepository();

  final LocalAuthentication _auth = LocalAuthentication();

  /// 비밀번호 설정 여부
  bool _isPinSet = false;
  bool get isPinSet => _isPinSet;

  /// 리셋 여부
  bool _hasAlreadyRequestedBioPermission = false;
  bool get hasAlreadyRequestedBioPermission =>
      _hasAlreadyRequestedBioPermission;

  /// 디바이스 생체인증 활성화 여부
  bool _canCheckBiometrics = false;
  bool get canCheckBiometrics => _canCheckBiometrics;

  /// 사용자 생체 인증 on/off 여부
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  bool get isBiometricAuthRequired =>
      _isBiometricEnabled && _canCheckBiometrics;

  /// 사용자 생체인증 권한 허용 여부
  bool _hasBiometricsPermission = false;
  bool get hasBiometricsPermission => _hasBiometricsPermission;

  /// 잠금 해제 시도 정보
  int _currentTurn = 0;
  int get currentTurn => _currentTurn;
  int _currentAttemptInTurn = 0;
  int get currentAttemptInTurn => _currentAttemptInTurn;
  String _unlockAvailableAtInString = '';
  DateTime? get unlockAvailableAt => _getUnlockAvailableAt();

  int get remainingAttemptCount => kMaxAttemptPerTurn - _currentAttemptInTurn;
  bool get isPermanantlyLocked => _currentTurn == kMaxTurn;

  VoidCallback? onRequestShowAuthenticationFailedDialog;
  VoidCallback? onBiometricAuthFailed; // 현재 사용하는 곳 없음
  VoidCallback? onAuthenticationSuccess;

  AuthProvider() {
    updateBiometricAvailability();
    setInitState();
  }

  DateTime? _getUnlockAvailableAt() {
    if (_unlockAvailableAtInString.isEmpty) {
      if (_currentTurn == 0) {
        return DateTime.now();
      }
      return DateTime.now().add(Duration(minutes: kLockoutDurationsPerTurn[0]));
    } else {
      if (_unlockAvailableAtInString == '-1') {
        return null;
      }
      return DateTime.tryParse(_unlockAvailableAtInString);
    }
  }

  void setInitState() {
    _isPinSet = _sharedPrefs.getBool(SharedPrefsKeys.isPinEnabled) == true;
    _loadBiometricState();
    _loadUnlockState();
    notifyListeners();
  }

  void _loadBiometricState() {
    _isBiometricEnabled =
        _sharedPrefs.getBool(SharedPrefsKeys.isBiometricEnabled) == true;
    _hasBiometricsPermission =
        _sharedPrefs.getBool(SharedPrefsKeys.hasBiometricsPermission) == true;
    _hasAlreadyRequestedBioPermission = _sharedPrefs
            .getBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission) ==
        true;
  }

  void _loadUnlockState() {
    final pinInputAttemptCount = _sharedPrefs.getString(currentAttemptKey);
    final totalAttemptCount = _sharedPrefs.getString(turnKey);
    final lockoutEndDateTimeString =
        _sharedPrefs.getString(unlockAvailableAtKey);

    _currentAttemptInTurn =
        pinInputAttemptCount.isEmpty ? 0 : int.parse(pinInputAttemptCount);
    _currentTurn = totalAttemptCount.isEmpty ? 0 : int.parse(totalAttemptCount);
    _unlockAvailableAtInString =
        totalAttemptCount.isEmpty ? '' : lockoutEndDateTimeString;
  }

  bool isInLockoutPeriod() {
    return unlockAvailableAt?.isAfter(DateTime.now()) ?? false;
  }

  /// 생체인증 진행 후 성공 여부 반환
  Future<bool> authenticateWithBiometrics(BuildContext context,
      {bool showAuthenticationFailedDialog = true,
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
        if (context.mounted &&
            onRequestShowAuthenticationFailedDialog != null) {
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
          if (context.mounted &&
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
    if (_hasAlreadyRequestedBioPermission) return;

    _hasAlreadyRequestedBioPermission = true;
    await _sharedPrefs.setBool(
        SharedPrefsKeys.hasAlreadyRequestedBioPermission, true);
  }

  /// 기기의 생체인증 가능 여부 업데이트
  /// Shared Preference의 canCheckBiometrics, isBiometricEnabled를 업데이트함
  Future<void> updateBiometricAvailability() async {
    try {
      final hasBiometrics = await _auth.canCheckBiometrics;
      if (!hasBiometrics) {
        _canCheckBiometrics = false;
        return;
      }

      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();

      _canCheckBiometrics = availableBiometrics.isNotEmpty;

      if (!_canCheckBiometrics) {
        _isBiometricEnabled = false;
      }
    } on PlatformException catch (e) {
      // 생체 인식 기능 비활성화, 사용자가 권한 거부, 기기 하드웨어에 문제가 있는 경우, 기기 호환성 문제, 플랫폼 제한
      Logger.log(e);
      _canCheckBiometrics = false;
      _isBiometricEnabled = false;
    } finally {
      _sharedPrefs.setBool(
          SharedPrefsKeys.canCheckBiometrics, _canCheckBiometrics);
      _sharedPrefs.setBool(
          SharedPrefsKeys.isBiometricEnabled, _isBiometricEnabled);
      notifyListeners();
    }
  }

  /// 사용자 생체인증 활성화 여부 저장
  Future<void> saveIsBiometricEnabled(bool value) async {
    _isBiometricEnabled = value;
    _hasBiometricsPermission = value;
    await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, value);
    await _sharedPrefs.setBool(SharedPrefsKeys.hasBiometricsPermission, value);
    notifyListeners();
  }

  void verifyBiometric(BuildContext context) async {
    bool isAuthenticated = await authenticateWithBiometrics(
      context,
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
    var randomNumberPad =
        List<String>.generate(10, (index) => index.toString());
    randomNumberPad.shuffle(random);
    randomNumberPad.insert(
        randomNumberPad.length - 1,
        !isPinSettingContext && _isBiometricEnabled
            ? kBiometricIdentifier
            : '');
    randomNumberPad.add(kDeleteBtnIdentifier);
    return randomNumberPad;
  }

  /// 비밀번호 검증
  Future<bool> verifyPin(String inputPin) async {
    String hashedInput = hashString(inputPin);
    final savedPin =
        await _storageService.read(key: SecureStorageKeys.kVaultPin);

    if (savedPin == hashedInput) {
      resetAuthenticationState();
      return true;
    }

    await increaseCurrentAttemptAndTurn();
    return false;
  }

  /// 비밀번호 저장
  Future<void> savePin(String pin) async {
    if (_isBiometricEnabled && _canCheckBiometrics && !_isPinSet) {
      _isBiometricEnabled = true;
      _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, true);
    }

    String hashed = hashString(pin);
    await _storageService.write(
        key: SecureStorageKeys.kVaultPin, value: hashed);
    _isPinSet = true;
    _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, true);
    notifyListeners();
  }

  /// 비밀번호 초기화
  Future<void> resetPin() async {
    final WalletListManager walletListManager = WalletListManager();
    await walletListManager.resetAll();

    _isBiometricEnabled = false;
    _isPinSet = false;
    await _storageService.delete(key: SecureStorageKeys.kVaultPin);
    _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    _sharedPrefs.setInt(SharedPrefsKeys.vaultListLength, 0);
    _sharedPrefs.setString(SharedPrefsKeys.kAppVersion, '');
    _sharedPrefs.setString(SharedPrefsKeys.kVaultListField, '');

    resetAuthenticationState();
  }

  // TODO: 딜레이 발생 이유
  /// 총 비밀번호 입력 시도 횟수, 다음 입력 가능 시간 저장
  Future<void> _setTurn(int turn) async {
    await _sharedPrefs.setString(turnKey, turn.toString());

    if (turn == kMaxTurn) {
      await _sharedPrefs.setString(
          unlockAvailableAtKey, kPinInputDelayInfinite.toString());
      return;
    }

    final unlockableDateTime = DateTime.now()
        .add(Duration(minutes: kLockoutDurationsPerTurn[turn - 1]));

    _unlockAvailableAtInString = unlockableDateTime.toIso8601String();
    await _sharedPrefs.setString(
        unlockAvailableAtKey, _unlockAvailableAtInString);
  }

  /// 비밀번호 입력 시도 횟수 -> shared preference 저장할 필요가 없음.
  Future<void> _setCurrentAttempt(int attmept) async {
    final attemptCount = attmept.toString();
    await _sharedPrefs.setString(currentAttemptKey, attemptCount);
  }

  /// 비밀번호 입력 시도 횟수 증가
  /// 최대 횟수 도달 시, 잠금 해제 시도 횟수, 다음 시도 시간 저장, 시도 횟수 초기화
  Future<void> increaseCurrentAttemptAndTurn() async {
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
    _currentAttemptInTurn = 0;
    _currentTurn = 0;
    _unlockAvailableAtInString = '';

    _sharedPrefs.deleteSharedPrefsWithKey(unlockAvailableAtKey);
    _sharedPrefs.deleteSharedPrefsWithKey(currentAttemptKey);
    _sharedPrefs.deleteSharedPrefsWithKey(turnKey);
  }

  void printLog() {
    Logger.log(
        '_currentAttemptInTurn: $_currentAttemptInTurn, _currentTurn: $_currentTurn, _unlockAvailableAtInString: $_unlockAvailableAtInString');
  }
}
