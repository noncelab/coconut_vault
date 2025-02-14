import 'dart:io';
import 'dart:math';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthProvider extends ChangeNotifier {
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

  /// 사용자 생체인증 권한 허용 여부
  bool _hasBiometricsPermission = false;
  bool get hasBiometricsPermission => _hasBiometricsPermission;

  VoidCallback? onRequestShowDialog;

  AuthProvider() {
    setInitState();
  }

  Future setInitState() async {
    await checkDeviceBiometrics();
    _isPinSet = _sharedPrefs.getBool(SharedPrefsKeys.isPinEnabled) == true;
    _isBiometricEnabled =
        _sharedPrefs.getBool(SharedPrefsKeys.isBiometricEnabled) == true;
    _hasBiometricsPermission =
        _sharedPrefs.getBool(SharedPrefsKeys.hasBiometricsPermission) == true;
    _hasAlreadyRequestedBioPermission = _sharedPrefs
            .getBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission) ==
        true;
  }

  /// 기기의 생체인증 가능 여부 업데이트
  Future<void> checkDeviceBiometrics() async {
    List<BiometricType> availableBiometrics = [];

    try {
      final isBiometricsEnabled = await _auth.canCheckBiometrics;
      availableBiometrics = await _auth.getAvailableBiometrics();

      _canCheckBiometrics =
          isBiometricsEnabled && availableBiometrics.isNotEmpty;

      _sharedPrefs.setBool(
          SharedPrefsKeys.canCheckBiometrics, _canCheckBiometrics);

      if (!_canCheckBiometrics) {
        _isBiometricEnabled = false;
        _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
      }

      notifyListeners();
    } on PlatformException catch (e) {
      // 생체 인식 기능 비활성화, 사용자가 권한 거부, 기기 하드웨어에 문제가 있는 경우, 기기 호환성 문제, 플랫폼 제한
      Logger.log(e);
      _canCheckBiometrics = false;
      _sharedPrefs.setBool(SharedPrefsKeys.canCheckBiometrics, false);
      _isBiometricEnabled = false;
      _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    } finally {
      notifyListeners();
    }
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
        if (context.mounted) {
          onRequestShowDialog!();
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
          if (context.mounted) {
            onRequestShowDialog!();
          }
        }
        _setHasAlreadyRequestedBioPermissionTrue();
      }
    }
    return false;
  }

  /// 사용자 생체인증 활성화 여부 저장
  Future<void> saveIsBiometricEnabled(bool value) async {
    _isBiometricEnabled = value;
    _hasBiometricsPermission = value;
    await _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, value);
    await _sharedPrefs.setBool(SharedPrefsKeys.hasBiometricsPermission, value);
  }

  Future<void> _setHasAlreadyRequestedBioPermissionTrue() async {
    _hasAlreadyRequestedBioPermission = true;
    await _sharedPrefs.setBool(
        SharedPrefsKeys.hasAlreadyRequestedBioPermission, true);
  }

  /// 비밀번호 저장
  Future<void> savePin(String pin) async {
    if (_isBiometricEnabled && _canCheckBiometrics && !_isPinSet) {
      _isBiometricEnabled = true;
      _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, true);
    }

    String hashed = hashString(pin);
    await _storageService.write(key: VAULT_PIN, value: hashed);
    _isPinSet = true;
    _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, true);
  }

  /// 비밀번호 검증
  Future<bool> verifyPin(String inputPin) async {
    String hashedInput = hashString(inputPin);
    final savedPin = await _storageService.read(key: VAULT_PIN);
    return savedPin == hashedInput;
  }

  /// 비밀번호 초기화
  Future<void> resetPassword() async {
    // TODO: _isResetVault = true;
    _isBiometricEnabled = false;
    _isPinSet = false;
    // TODO: _vaultListLength = 0;

    await _storageService.delete(key: VAULT_PIN);
    _sharedPrefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    _sharedPrefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    _sharedPrefs.setInt(SharedPrefsKeys.vaultListLength, 0);
  }

  // util: 비밀번호 입력 패드 생성
  List<String> getShuffledNumberList({isSettings = false}) {
    final random = Random();
    var randomNumberPad =
        List<String>.generate(10, (index) => index.toString());
    randomNumberPad.shuffle(random);
    randomNumberPad.insert(randomNumberPad.length - 1,
        !isSettings && _isBiometricEnabled ? kBiometricIdentifier : '');
    randomNumberPad.add(kDeleteBtnIdentifier);
    return randomNumberPad;
  }
}
