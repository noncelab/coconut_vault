import 'dart:convert';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/repository/model/multisig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/single_sig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_payload_codec.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:flutter/foundation.dart';

/// Storage key derivation helpers shared by repository & strategies.
class WalletStorageKeys {
  static String walletKey(int id, WalletType type) => hashString("${id.toString()} - ${type.name}");
  static String passphraseEnabledKey(String walletKey) => hashString("$walletKey - passphraseEnabled");
  static String privacyInfoKey(String walletKey) => "privacy_${hashString(walletKey)}";
}

/// Persistence behavior that differs between secure-storage mode and signing-only mode.
///
/// Exposes ONLY wallet-level atomic operations (add/delete/updatePrivacy) to outside callers.
/// The granular secret/privacy writes are library-private so they cannot be invoked individually,
/// preventing the developer mistake of forgetting to keep the two storage backends in sync.
abstract class WalletPersistenceStrategy {
  bool get isSigningOnlyMode;

  /// Whether the singlesig secret payload carries the passphrase.
  bool get passphraseStoredWithSecret;

  Future<bool> hasPassphrase(int walletId);

  /// Atomically persist a new singlesig wallet (secret + privacy info).
  /// On a partial failure, rolls back internally before rethrowing.
  Future<void> persistSinglesigAdd({
    required int id,
    required Uint8List secret,
    Uint8List? passphrase,
    required SingleSigVaultListItem item,
  });

  /// Atomically persist a new multisig wallet (privacy info only).
  Future<void> persistMultisigAdd({required int id, required MultisigVaultListItem item});

  /// Remove all data for the wallet (secret if singlesig + privacy info). Idempotent.
  Future<void> deleteWalletData(int id, WalletType type);

  /// Update privacy info for an existing singlesig wallet (e.g., after account derivation change).
  Future<void> updateSinglesigPrivacy(int id, SingleSigVaultListItem item);

  /// Persist the public vault list snapshot. No-op in signing-only mode by policy.
  Future<void> savePublicVaultList(List<VaultListItemBase> items);
}

/// Persistence behavior used when the user runs in normal (secure-storage) mode.
class SecureStorageStrategy implements WalletPersistenceStrategy {
  final SecureStorageRepository _storageService = SecureStorageRepository();
  final SecureZoneRepository _secureZoneRepository = SecureZoneRepository();
  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();

  @override
  bool get isSigningOnlyMode => false;

  @override
  bool get passphraseStoredWithSecret => false;

  @override
  Future<bool> hasPassphrase(int walletId) async {
    final keyString = WalletStorageKeys.walletKey(walletId, WalletType.singleSignature);
    final flagKey = WalletStorageKeys.passphraseEnabledKey(keyString);
    return await _storageService.read(key: flagKey) == "true";
  }

  @override
  Future<void> persistSinglesigAdd({
    required int id,
    required Uint8List secret,
    Uint8List? passphrase,
    required SingleSigVaultListItem item,
  }) async {
    await _saveSinglesigSecret(id, secret, passphrase);
    try {
      await _saveSinglesigPrivacy(id, item);
    } catch (_) {
      await _deleteSinglesigSecret(id);
      rethrow;
    }
  }

  @override
  Future<void> persistMultisigAdd({required int id, required MultisigVaultListItem item}) async {
    await _saveMultisigPrivacy(id, item);
  }

  @override
  Future<void> deleteWalletData(int id, WalletType type) async {
    if (type == WalletType.singleSignature) {
      await _deleteSinglesigSecret(id);
    }
    await _deletePrivacyInfo(id, type);
  }

  @override
  Future<void> updateSinglesigPrivacy(int id, SingleSigVaultListItem item) async {
    await _saveSinglesigPrivacy(id, item);
  }

  @override
  Future<void> savePublicVaultList(List<VaultListItemBase> items) async {
    final jsonString = jsonEncode(items.map((item) => item.toPublicJson()).toList());
    printLongString("--> PublicInfo 저장: $jsonString");
    assert(
      !jsonString.contains(SingleSigVaultListItem.fieldDescriptor) &&
          !jsonString.contains(SingleSigVaultListItem.fieldSignerBsmsByAddressType) &&
          !jsonString.contains(MultisigVaultListItem.fieldCoordinatorBsms) &&
          !jsonString.contains(MultisigSigner.fieldSignerBsms) &&
          !jsonString.contains(MultisigSigner.fieldKeyStore),
    );
    await _sharedPrefs.setString(SharedPrefsKeys.kVaultListField, jsonString);
  }

  /// Raw privacy-info write used by the data-schema migration runner.
  /// Migration only runs in secure-storage mode (signing-only mode never persists a vault list to migrate).
  /// Exposed as public because it must be passed as a callback to the migration runner.
  Future<void> writePrivacyInfo(int id, WalletType type, WalletPrivacyInfo info) async {
    final walletKey = WalletStorageKeys.walletKey(id, type);
    await _storageService.write(key: WalletStorageKeys.privacyInfoKey(walletKey), value: jsonEncode(info.toJson()));
  }

  // --- library-private granular ops (called only by the bundled methods above) ---

  Future<void> _saveSinglesigSecret(int walletId, Uint8List secret, Uint8List? passphrase) async {
    final keyString = WalletStorageKeys.walletKey(walletId, WalletType.singleSignature);
    await _secureZoneRepository.generateKey(alias: keyString, userAuthRequired: true);
    final plainText = SecureZonePayloadCodec.buildPlaintext(secret: secret, passphrase: null);
    final result = await _secureZoneRepository.encrypt(alias: keyString, plaintext: plainText);
    await _storageService.write(key: keyString, value: result.toCombinedBase64());

    final flagKey = WalletStorageKeys.passphraseEnabledKey(keyString);
    final hasPassphrase = passphrase != null && passphrase.isNotEmpty;
    await _storageService.write(key: flagKey, value: hasPassphrase ? "true" : "false");
  }

  Future<void> _deleteSinglesigSecret(int walletId) async {
    final keyString = WalletStorageKeys.walletKey(walletId, WalletType.singleSignature);
    await _storageService.delete(key: keyString);
    await _secureZoneRepository.deleteKey(alias: keyString);
    await _storageService.delete(key: WalletStorageKeys.passphraseEnabledKey(keyString));
  }

  Future<void> _saveSinglesigPrivacy(int id, SingleSigVaultListItem item) async {
    final info = SingleSigWalletPrivacyInfo.fromAddressTypeMap(
      descriptor: item.descriptor,
      signerBsmsByAddressType: item.signerBsmsByAddressType,
    );
    await writePrivacyInfo(id, WalletType.singleSignature, info);
  }

  Future<void> _saveMultisigPrivacy(int id, MultisigVaultListItem item) async {
    final signersPrivacyInfo =
        item.signers
            .map(
              (signer) => SignerPrivacyInfo(signerBsms: signer.signerBsms!, keyStoreToJson: signer.keyStore.toJson()),
            )
            .toList();
    final info = MultisigWalletPrivacyInfo(
      coordinatorBsms: item.coordinatorBsms,
      signersPrivacyInfo: signersPrivacyInfo,
    );
    await writePrivacyInfo(id, WalletType.multiSignature, info);
  }

  Future<void> _deletePrivacyInfo(int id, WalletType type) async {
    final walletKey = WalletStorageKeys.walletKey(id, type);
    await _storageService.delete(key: WalletStorageKeys.privacyInfoKey(walletKey));
  }
}

/// Persistence behavior used in signing-only mode.
///
/// Public/privacy info is intentionally not persisted; the secret payload carries the passphrase
/// so that signing flows can recover it without user input.
class SigningOnlyStrategy implements WalletPersistenceStrategy {
  final SecureStorageRepository _storageService = SecureStorageRepository();
  final SecureZoneRepository _secureZoneRepository = SecureZoneRepository();

  @override
  bool get isSigningOnlyMode => true;

  @override
  bool get passphraseStoredWithSecret => true;

  @override
  Future<bool> hasPassphrase(int walletId) async {
    // Not used in signing-only mode (call sites guard with isSigningOnlyMode).
    assert(false, 'hasPassphrase must not be called in signing-only mode');
    return false;
  }

  @override
  Future<void> persistSinglesigAdd({
    required int id,
    required Uint8List secret,
    Uint8List? passphrase,
    required SingleSigVaultListItem item,
  }) async {
    // Privacy info is not persisted in signing-only mode; only the secret matters.
    await _saveSinglesigSecret(id, secret, passphrase);
  }

  @override
  Future<void> persistMultisigAdd({required int id, required MultisigVaultListItem item}) async {
    // No-op: privacy info is not persisted in signing-only mode.
  }

  @override
  Future<void> deleteWalletData(int id, WalletType type) async {
    if (type == WalletType.singleSignature) {
      await _deleteSinglesigSecret(id);
    }
    // Privacy info was never persisted; nothing to delete.
  }

  @override
  Future<void> updateSinglesigPrivacy(int id, SingleSigVaultListItem item) async {
    // No-op: privacy info is not persisted in signing-only mode.
  }

  @override
  Future<void> savePublicVaultList(List<VaultListItemBase> items) async {
    // No-op: signing-only mode does not persist the public vault list to disk.
  }

  // --- library-private granular ops ---

  Future<void> _saveSinglesigSecret(int walletId, Uint8List secret, Uint8List? passphrase) async {
    final keyString = WalletStorageKeys.walletKey(walletId, WalletType.singleSignature);
    await _secureZoneRepository.generateKey(alias: keyString, userAuthRequired: true);
    final plainText = SecureZonePayloadCodec.buildPlaintext(secret: secret, passphrase: passphrase);
    final result = await _secureZoneRepository.encrypt(alias: keyString, plaintext: plainText);
    await _storageService.write(key: keyString, value: result.toCombinedBase64());
  }

  Future<void> _deleteSinglesigSecret(int walletId) async {
    final keyString = WalletStorageKeys.walletKey(walletId, WalletType.singleSignature);
    await _storageService.delete(key: keyString);
    await _secureZoneRepository.deleteKey(alias: keyString);
  }
}
