import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/wallet_persistence_strategy.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_payload_codec.dart';
import 'package:coconut_vault/utils/logger.dart';

/// Persistence behavior used in signing-only mode.
///
/// Public/privacy info is intentionally not persisted; the secret payload carries the passphrase
/// so that signing flows can recover it without user input.
class SigningOnlyStrategy implements WalletPersistenceStrategy {
  final SecureStorageRepositoryContract _storageService;
  final SecureZoneRepositoryContract _secureZoneRepository;

  SigningOnlyStrategy({
    SecureStorageRepositoryContract? storageService,
    SecureZoneRepositoryContract? secureZoneRepository,
  }) : _storageService = storageService ?? SecureStorageRepository(),
       _secureZoneRepository = secureZoneRepository ?? SecureZoneRepository();

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
  Future<T> mutate<T>({
    required Future<T> Function(WalletWriteOps ops) execute,
    required List<VaultListItemBase> Function() snapshot,
    bool ignorePublicListSaveFailure = false,
  }) async {
    final result = await execute(_SigningOnlyOps(this));
    await savePublicVaultList(snapshot()); // no-op, kept for API symmetry
    return result;
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

    await _deleteSecureZoneKeyWithRetry(keyString);
    await _deleteStorageWithRetry(keyString);
  }

  Future<void> _deleteSecureZoneKeyWithRetry(String alias) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _secureZoneRepository.deleteKey(alias: alias);
        return;
      } catch (e, stackTrace) {
        if (attempt == 3) {
          Error.throwWithStackTrace(e, stackTrace);
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _deleteStorageWithRetry(String key) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _storageService.delete(key: key);
        return;
      } catch (e) {
        if (attempt == 3) {
          Logger.log('Secure storage cleanup failed after $attempt attempts: key=$key, error=$e');
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _saveTaprootSecrets(int walletId, List<TaprootSeedInfoForSave> secrets) async {
    for (final seedInfo in secrets) {
      final keyString = WalletStorageKeys.taprootSeedKey(walletId, seedInfo.extendedPublicKey);
      await _saveTaprootSeed(walletId, keyString, seedInfo);
    }
  }

  Future<void> _saveTaprootSeed(int walletId, String keyString, TaprootSeedInfoForSave seedInfo) async {
    await _secureZoneRepository.generateKey(alias: keyString, userAuthRequired: true);
    final pair = seedInfo.secretPassphrasePair;
    final plainText = SecureZonePayloadCodec.buildPlaintext(secret: pair.secret, passphrase: pair.passphrase);
    final result = await _secureZoneRepository.encrypt(alias: keyString, plaintext: plainText);
    await _storageService.write(key: keyString, value: result.toCombinedBase64());
    await _appendTaprootSeedIndex(walletId, keyString);
  }

  Future<void> _deleteTaprootSecrets(int walletId) async {
    final seedKeys = await _readTaprootSeedIndex(walletId);
    for (var index = 0; index < seedKeys.length; index++) {
      await _deleteTaprootSeedByKey(seedKeys[index], rethrowOnSecureZoneDeleteFailure: index == 0);
    }
    await _deleteStorageWithRetry(WalletStorageKeys.taprootSeedIndexKey(walletId));
  }

  Future<void> _deleteTaprootSeeds(int walletId, List<String> seedKeys) async {
    for (final keyString in seedKeys) {
      await _deleteTaprootSeedByKey(keyString, rethrowOnSecureZoneDeleteFailure: false);
    }
    await _deleteStorageWithRetry(WalletStorageKeys.taprootSeedIndexKey(walletId));
  }

  Future<void> _deleteTaprootSeedByKey(String seedKey, {required bool rethrowOnSecureZoneDeleteFailure}) async {
    try {
      await _deleteSecureZoneKeyWithRetry(seedKey);
    } catch (e, stackTrace) {
      Logger.log('Taproot Secure Zone seed key cleanup failed: key=$seedKey, error=$e');
      if (rethrowOnSecureZoneDeleteFailure) {
        Error.throwWithStackTrace(e, stackTrace);
      }
    }
    await _deleteStorageWithRetry(seedKey);
  }

  Future<List<String>> _readTaprootSeedIndex(int walletId) async {
    final indexJson = await _storageService.read(key: WalletStorageKeys.taprootSeedIndexKey(walletId));
    if (indexJson == null) {
      return [];
    }
    return List<String>.from(jsonDecode(indexJson));
  }

  Future<void> _appendTaprootSeedIndex(int walletId, String seedKey) async {
    final seedKeys = await _readTaprootSeedIndex(walletId);
    if (!seedKeys.contains(seedKey)) {
      seedKeys.add(seedKey);
      await _storageService.write(key: WalletStorageKeys.taprootSeedIndexKey(walletId), value: jsonEncode(seedKeys));
    }
  }
}

/// Library-private write-ops impl bound to a [SigningOnlyStrategy].
class _SigningOnlyOps implements WalletWriteOps {
  final SigningOnlyStrategy _s;
  _SigningOnlyOps(this._s);

  @override
  Future<void> persistSinglesigAdd({
    required int id,
    required Uint8List secret,
    Uint8List? passphrase,
    required SingleSigVaultListItem item,
  }) async {
    // Privacy info is not persisted in signing-only mode; only the secret matters.
    await _s._saveSinglesigSecret(id, secret, passphrase);
  }

  @override
  Future<void> persistMultisigAdd({required int id, required MultisigVaultListItem item}) async {
    // No-op: privacy info is not persisted in signing-only mode.
  }

  @override
  Future<void> persistTaprootAdd({
    required int id,
    required List<TaprootSeedInfoForSave> seedInfosForAdd,
    required TaprootVaultListItem item,
  }) async {
    // Privacy info is not persisted in signing-only mode; only the secret matters.
    try {
      await _s._saveTaprootSecrets(id, seedInfosForAdd);
    } catch (_) {
      await _s._deleteTaprootSeeds(id, [
        for (final seedInfo in seedInfosForAdd) WalletStorageKeys.taprootSeedKey(id, seedInfo.extendedPublicKey),
      ]);
      rethrow;
    }
  }

  @override
  Future<void> deleteWalletData(int id, WalletType type) async {
    if (type == WalletType.singleSignature) {
      await _s._deleteSinglesigSecret(id);
    } else if (type == WalletType.taproot) {
      await _s._deleteTaprootSecrets(id);
    }
    // Privacy info was never persisted; nothing to delete.
  }
}
