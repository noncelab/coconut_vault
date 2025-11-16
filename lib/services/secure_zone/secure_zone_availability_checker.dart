import 'dart:io';

import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/exception/seed_invalidated_exception.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/services.dart';

class SecureZoneManager {
  static final SecureZoneManager _instance = SecureZoneManager._internal();
  factory SecureZoneManager() => _instance;
  SecureZoneManager._internal();

  Future<bool> verifyIosKeychainValidity() async {
    assert(Platform.isIOS);
    try {
      final sharedPrefs = SharedPrefsRepository();

      final isPinEnabled = sharedPrefs.getBool(SharedPrefsKeys.isPinEnabled) ?? false;
      if (!isPinEnabled) return true;

      final secureStorageRepository = SecureStorageRepository();
      final vaultPin = await secureStorageRepository.read(key: SecureStorageKeys.kVaultPin);
      if (vaultPin == null) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAndroidSecureZoneAccessible(WalletProvider walletProvider) async {
    assert(Platform.isAndroid && walletProvider.vaultList.isNotEmpty);

    final firstSingleSignatureWalletId =
        walletProvider.vaultList.firstWhere((vault) => vault.vaultType == WalletType.singleSignature).id;
    try {
      await walletProvider.getSecret(firstSingleSignatureWalletId, autoAuth: false);
      return true;
    } on SeedInvalidatedException catch (_) {
      return false;
    } on PlatformException catch (e) {
      if (e.code == 'AUTH_NEEDED') {
        // AUTH_NEEDED는 키는 유효하지만 기기인증이 필요한 상황
        return true;
      }
      rethrow;
    }
  }

  /// 보안 영역 접근 불가 시 저장된 데이터 초기화
  Future<bool> deleteStoredData(AuthProvider authProvider) async {
    try {
      final sharedPrefsRepository = SharedPrefsRepository();
      final hasSeenGuide = SharedPrefsRepository().getBool(SharedPrefsKeys.hasShownStartGuide) == true;
      final selectedVaultMode = SharedPrefsRepository().getString(SharedPrefsKeys.kVaultMode);
      await sharedPrefsRepository.clearSharedPref();
      final secureStorageRepository = SecureStorageRepository();
      await secureStorageRepository.deleteAll();
      await authProvider.resetPinData();

      if (hasSeenGuide) {
        await SharedPrefsRepository().setBool(SharedPrefsKeys.hasShownStartGuide, true);
      }
      if (selectedVaultMode != '') {
        await SharedPrefsRepository().setString(SharedPrefsKeys.kVaultMode, selectedVaultMode);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
