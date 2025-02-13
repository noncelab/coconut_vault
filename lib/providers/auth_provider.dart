import 'dart:io';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthProvider extends ChangeNotifier {
  final SecureStorageRepository _storageService = SecureStorageRepository();
  final LocalAuthentication _auth = LocalAuthentication();

  /// 비밀번호 설정 여부
  bool _isPinEnabled = false;
  bool get isPinEnabled => _isPinEnabled;

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

  AuthProvider() {
    final prefs = SharedPrefsRepository();
    _isPinEnabled = prefs.getBool(SharedPrefsKeys.isPinEnabled) == true;
    _isBiometricEnabled =
        prefs.getBool(SharedPrefsKeys.isBiometricEnabled) == true;
    _hasBiometricsPermission =
        prefs.getBool(SharedPrefsKeys.hasBiometricsPermission) == true;
    _hasAlreadyRequestedBioPermission =
        prefs.getBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission) == true;
  }

  /// 기기의 생체인증 가능 여부 업데이트
  Future<void> checkDeviceBiometrics() async {
    final prefs = SharedPrefsRepository();
    List<BiometricType> availableBiometrics = [];

    try {
      final isEnabledBiometrics = await _auth.canCheckBiometrics;
      availableBiometrics = await _auth.getAvailableBiometrics();

      _canCheckBiometrics =
          isEnabledBiometrics && availableBiometrics.isNotEmpty;

      prefs.setBool(SharedPrefsKeys.canCheckBiometrics, _canCheckBiometrics);

      if (!_canCheckBiometrics) {
        _isBiometricEnabled = false;
        prefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
      }

      notifyListeners();
    } on PlatformException catch (e) {
      // 생체 인식 기능 비활성화, 사용자가 권한 거부, 기기 하드웨어에 문제가 있는 경우, 기기 호환성 문제, 플랫폼 제한
      Logger.log(e);
      _canCheckBiometrics = false;
      prefs.setBool(SharedPrefsKeys.canCheckBiometrics, false);
      _isBiometricEnabled = false;
      prefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
      notifyListeners();
    }
  }

  /// 생체인증 진행 후 성공 여부 반환
  Future<bool> authenticateWithBiometrics(BuildContext context,
      {bool showAuthenticationFailedDialog = true, bool isSave = false}) async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: isSave
            ? '잠금 해제 시 생체 인증을 사용하시겠습니까?'
            : '생체 인증을 진행해 주세요.', // 이 문구는 aos, iOS(touch ID)에서 사용됩니다. ios face ID는 info.plist string을 사용합니다.
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (Platform.isIOS && !authenticated) {
        if (context.mounted) {
          await _showAuthenticationFailedDialog(context);
        }
      }

      if (isSave) {
        saveIsBiometricEnabled(authenticated);
        _setBioRequestedInSharedPrefs();
      }

      return authenticated;
    } on PlatformException catch (e) {
      Logger.log(e);

      if (isSave) {
        saveIsBiometricEnabled(false);
        if (Platform.isIOS &&
            !authenticated &&
            e.message == 'Biometry is not available.' &&
            showAuthenticationFailedDialog) {
          if (context.mounted) {
            await _showAuthenticationFailedDialog(context);
          }
        }
        _setBioRequestedInSharedPrefs();
      }
    }
    return false;
  }

  /// 사용자 생체인증 활성화 여부 저장
  Future<void> saveIsBiometricEnabled(bool value) async {
    _isBiometricEnabled = value;
    _hasBiometricsPermission = value;
    final prefs = SharedPrefsRepository();
    await prefs.setBool(SharedPrefsKeys.isBiometricEnabled, value);
    await prefs.setBool(SharedPrefsKeys.hasBiometricsPermission, value);
    // TODO: shuffleNumbers();
  }

  Future<void> _setBioRequestedInSharedPrefs() async {
    _hasAlreadyRequestedBioPermission = true;
    await SharedPrefsRepository()
        .setBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission, true);
  }

  /// 비밀번호 저장
  Future<void> savePin(String pin) async {
    final prefs = SharedPrefsRepository();

    if (_isBiometricEnabled && _canCheckBiometrics && !_isPinEnabled) {
      _isBiometricEnabled = true;
      prefs.setBool(SharedPrefsKeys.isBiometricEnabled, true);
    }

    String hashed = hashString(pin);
    await _storageService.write(key: VAULT_PIN, value: hashed);
    _isPinEnabled = true;
    prefs.setBool(SharedPrefsKeys.isPinEnabled, true);
    // TODO: shuffleNumbers();
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
    _isPinEnabled = false;
    // TODO: _vaultListLength = 0;

    await _storageService.delete(key: VAULT_PIN);
    final prefs = SharedPrefsRepository();
    prefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    prefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    prefs.setInt(SharedPrefsKeys.vaultListLength, 0);
  }

  Future<void> _showAuthenticationFailedDialog(BuildContext context) async {
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            _hasAlreadyRequestedBioPermission == true
                ? '생체 인증 권한이 필요합니다'
                : '생체 인증 권한이 거부되었습니다',
            style: const TextStyle(
              color: MyColors.black,
            ),
          ),
          content: const Text(
            '생체 인증을 통한 잠금 해제를 하시려면\n설정 > 코코넛 볼트에서 생체 인증 권한을 허용해 주세요.',
            style: TextStyle(
              color: MyColors.black,
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
                '닫기',
                style: Styles.label.merge(
                  const TextStyle(
                    color: MyColors.black,
                  ),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                '설정화면으로 이동',
                style: Styles.label.merge(
                  const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAppSettings() async {
    const url = 'app-settings:';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
