import 'dart:io';

import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:coconut_vault/utils/file_storage.dart';
import 'package:flutter/services.dart';

class SecurityPrechecker {
  static final SecurityPrechecker _instance = SecurityPrechecker._internal();
  static const MethodChannel _osChannel = MethodChannel(methodChannelOS);
  factory SecurityPrechecker() => _instance;
  SecurityPrechecker._internal();

  // 전체 보안 검사 수행 (1단계부터 시작)
  // Android: 탈옥/루팅 검사 -> 기기 비밀번호 설정 여부 검사
  // iOS: 탈옥/루팅 검사 -> 기기 비밀번호 설정 여부 검사 -> 기기 비밀번호 변경 여부 검사
  // ------------------------------------------------------------
  // FIXME: 매번 1단계부터 검사할 지, 아니면 아래 설명처럼 30분 이내 저장된 정보면 비밀번호 설정 여부부터 검사할 지 결정 필요
  // 탈옥/루팅 감지 화면에서 [그래도 계속하겠습니다] 선택 시,
  // jailbreakDetectionIgnored 상태와 저장 시간을 저장 후 performSecurityCheck 재호출함.
  // preformSecurityCheck 메서드에서 30분 이내 저장된 정보면, 비밀번호 설정 여부 검사해야함.
  Future<SecurityCheckResult> performSecurityCheck() async {
    final sharedPrefs = SharedPrefsRepository();
    final jailbreakDetectionIgnored = sharedPrefs.getBool(SharedPrefsKeys.jailbreakDetectionIgnored) ?? false;
    final jailbreakDetectionIgnoredTime = sharedPrefs.getInt(SharedPrefsKeys.jailbreakDetectionIgnoredTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (jailbreakDetectionIgnored && now - jailbreakDetectionIgnoredTime < 30 * 60 * 1000) {
      return await checkDevicePassword();
    }
    return await checkJailbreakRoot();
  }

  Future<SecurityCheckResult> checkJailbreakRoot() async {
    try {
      // 네이티브 메서드 채널을 통한 탈옥/루팅 검사
      final bool isJailbroken = await _osChannel.invokeMethod<bool>('isJailbroken') ?? false;

      if (isJailbroken) {
        return SecurityCheckResult(status: SecurityCheckStatus.jailbreakDetected, checkTime: DateTime.now());
      }

      // 탈옥/루팅이 감지되지 않으면 다음 단계로
      return await checkDevicePassword();
    } catch (e) {
      return SecurityCheckResult(status: SecurityCheckStatus.error, checkTime: DateTime.now());
    }
  }

  // 기기 비밀번호 설정 여부 검사
  Future<SecurityCheckResult> checkDevicePassword() async {
    try {
      final bool hasDevicePassword = await _osChannel.invokeMethod('isDeviceSecure');

      if (!hasDevicePassword) {
        return SecurityCheckResult(status: SecurityCheckStatus.devicePasswordRequired, checkTime: DateTime.now());
      }

      // INFO: 안드로이드도 생체 인증 추가하면 저장했던 데이터를 가져올 수 없음
      // if (Platform.isAndroid) {
      //   return SecurityCheckResult(status: SecurityCheckStatus.secure, checkTime: DateTime.now());
      // }

      // iOS는 기기 비밀번호 변경 여부 검사: 저장한 정보의 Keychain이 무효화됨
      return await checkDevicePasswordChanged();
    } catch (e) {
      return SecurityCheckResult(status: SecurityCheckStatus.error, checkTime: DateTime.now());
    }
  }

  // 기기 비밀번호 변경 여부 검사
  Future<SecurityCheckResult> checkDevicePasswordChanged() async {
    try {
      final isDevicePasswordChanged = await _isDevicePasswordChanged();

      if (isDevicePasswordChanged) {
        return SecurityCheckResult(status: SecurityCheckStatus.devicePasswordChanged, checkTime: DateTime.now());
      }

      // 모든 검사 통과
      return SecurityCheckResult(status: SecurityCheckStatus.secure, checkTime: DateTime.now());
    } catch (e) {
      return SecurityCheckResult(status: SecurityCheckStatus.error, checkTime: DateTime.now());
    }
  }

  Future<bool> _isDevicePasswordChanged() async {
    try {
      final sharedPrefs = SharedPrefsRepository();
      final isSecureStorageMode = sharedPrefs.getString(SharedPrefsKeys.kVaultMode) == VaultMode.secureStorage.name;

      if (!isSecureStorageMode) return false;

      //final walletCount = sharedPrefs.getInt(SharedPrefsKeys.vaultListLength) ?? 0;

      //if (walletCount <= 0) return false;

      final secureStorageRepository = SecureStorageRepository();
      final vaultPin = await secureStorageRepository.read(key: SecureStorageKeys.kVaultPin);

      if (vaultPin == null) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStoredData() async {
    try {
      final sharedPrefsRepository = SharedPrefsRepository();
      await sharedPrefsRepository.clearSharedPref();
      final secureStorageRepository = SecureStorageRepository();
      await secureStorageRepository.deleteAll();
      final files = await FileStorage.getFileList(subDirectory: UpdatePreparation.directory);
      for (final file in files) {
        await FileStorage.deleteFile(fileName: file, subDirectory: UpdatePreparation.directory);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

enum SecurityCheckStatus {
  secure, // 정상 구동 가능
  jailbreakDetected, // 탈옥/루팅 감지
  devicePasswordRequired, // 기기 비밀번호 필요
  devicePasswordChanged, // 기기 비밀번호 변경됨
  error, // 에러 발생
}

class SecurityCheckResult {
  final SecurityCheckStatus status;
  final DateTime checkTime;

  const SecurityCheckResult({required this.status, required this.checkTime});

  bool get isSecure => status == SecurityCheckStatus.secure;
  bool get isJailbreakDetected => status == SecurityCheckStatus.jailbreakDetected;
  bool get isDevicePasswordRequired => status == SecurityCheckStatus.devicePasswordRequired;
  bool get isDevicePasswordChanged => status == SecurityCheckStatus.devicePasswordChanged;
  bool get hasError => status == SecurityCheckStatus.error;
}
