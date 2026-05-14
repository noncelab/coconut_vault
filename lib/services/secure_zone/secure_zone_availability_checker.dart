import 'dart:io';

import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/exception/seed_invalidated_exception.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:collection/collection.dart';
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

    final singleSig = walletProvider.vaultList.firstWhereOrNull(
      (vault) => vault.vaultType == WalletType.singleSignature,
    );
    List<TaprootVaultListItem> taproots = [];
    if (singleSig == null) {
      taproots.addAll(walletProvider.vaultList.whereType<TaprootVaultListItem>());
    }
    try {
      if (singleSig != null) {
        await walletProvider.getSecret(singleSig.id, autoAuth: false);
      } else if (taproots.isNotEmpty) {
        for (final taprootVault in taproots) {
          if (taprootVault.keyPathSeedInfos.isEmpty &&
              (taprootVault.scriptPathSeedInfos == null || taprootVault.scriptPathSeedInfos!.isEmpty)) {
            continue;
          }

          final seedStoredParticipant =
              taprootVault.owners.firstWhereOrNull((owner) => owner.isSeedStored) ??
              taprootVault.beneficiaries.firstWhereOrNull((beneficiary) => beneficiary.isSeedStored);

          if (seedStoredParticipant != null) {
            await walletProvider.getTaprootSecret(
              taprootVault.id,
              seedStoredParticipant.seedKeyIdentifier,
              autoAuth: false,
            );
            return true;
          }
        }
      }
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
}
