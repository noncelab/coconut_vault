import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/repository/model/multisig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/single_sig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/wallet_persistence_strategy.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_payload_codec.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/print_util.dart';

/// Persistence behavior used when the user runs in normal (secure-storage) mode.
class SecureStorageStrategy implements WalletPersistenceStrategy {
  final SecureStorageRepositoryContract _storageService;
  final SecureZoneRepositoryContract _secureZoneRepository;
  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();

  SecureStorageStrategy({
    SecureStorageRepositoryContract? storageService,
    SecureZoneRepositoryContract? secureZoneRepository,
  }) : _storageService = storageService ?? SecureStorageRepository(),
       _secureZoneRepository = secureZoneRepository ?? SecureZoneRepository();

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
  Future<T> mutate<T>({
    required Future<T> Function(WalletWriteOps ops) execute,
    required List<VaultListItemBase> Function() snapshot,
  }) async {
    final result = await execute(_SecureStorageOps(this));
    await savePublicVaultList(snapshot());
    return result;
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

  Future<void> _saveSinglesigSecret(
    int walletId,
    Uint8List secret,
    Uint8List? passphrase, {
    bool regenerateKey = true,
  }) async {
    final keyString = WalletStorageKeys.walletKey(walletId, WalletType.singleSignature);
    if (regenerateKey) {
      await _secureZoneRepository.generateKey(alias: keyString, userAuthRequired: true);
    }
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

  Future<void> _saveTaprootSecrets(
    int walletId,
    List<TaprootSeedInfoForSave> secrets, {
    bool regenerateKey = true,
  }) async {
    for (final seedInfo in secrets) {
      final keyString = WalletStorageKeys.taprootSeedKey(walletId, seedInfo.extendedPublicKey);
      await _saveTaprootSeed(walletId, keyString, seedInfo, regenerateKey: regenerateKey);
    }
  }

  Future<void> _saveTaprootSeed(
    int walletId,
    String keyString,
    TaprootSeedInfoForSave seedInfo, {
    bool regenerateKey = true,
  }) async {
    Logger.log('--> taproot seed key: $keyString');
    if (regenerateKey) {
      await _secureZoneRepository.generateKey(alias: keyString, userAuthRequired: true);
    }
    final pair = seedInfo.secretPassphrasePair;
    final plainText = SecureZonePayloadCodec.buildPlaintext(secret: pair.secret, passphrase: null);
    final result = await _secureZoneRepository.encrypt(alias: keyString, plaintext: plainText);
    await _storageService.write(key: keyString, value: result.toCombinedBase64());

    await _appendTaprootSeedIndex(walletId, keyString);
  }

  Future<void> _deleteTaprootSecrets(int walletId) async {
    final seedKeys = await _readTaprootSeedIndex(walletId);
    for (final seedKey in seedKeys) {
      await _deleteTaprootSeedByKey(seedKey);
    }
    await _storageService.delete(key: WalletStorageKeys.taprootSeedIndexKey(walletId));
  }

  Future<void> _deleteTaprootSeeds(int walletId, List<String> seedKeys) async {
    for (final keyString in seedKeys) {
      await _deleteTaprootSeedByKey(keyString);
    }
    await _storageService.delete(key: WalletStorageKeys.taprootSeedIndexKey(walletId));
  }

  Future<void> _deleteTaprootSeedByKey(String seedKey) async {
    await _storageService.delete(key: seedKey);
    await _secureZoneRepository.deleteKey(alias: seedKey);
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

  Future<void> _saveTaprootPrivacy(int id, TaprootVaultListItem item) async {
    // TODO: 확인 필요
    final info = TaprootWalletPrivacyInfo(
      descriptor: item.descriptor,
      keyPathSeedInfos: item.keyPathSeedInfos,
      scriptPathSeedInfos: item.scriptPathSeedInfos,
    );
    await writePrivacyInfo(id, WalletType.taproot, info);
  }

  Future<void> _deletePrivacyInfo(int id, WalletType type) async {
    final walletKey = WalletStorageKeys.walletKey(id, type);
    await _storageService.delete(key: WalletStorageKeys.privacyInfoKey(walletKey));
  }

  // --- mode transition helpers (signing-only -> secure-storage) ---

  /// 기존 SecureZone 키를 재생성하지 않고 서명전용모드 형태의 암호문을
  /// 보안저장모드 형태로 덮어씁니다. 롤백 시 원본 암호문을 복호화할 수 있도록
  /// 키를 그대로 유지합니다.
  Future<void> convertSinglesigForModeTransition({
    required int id,
    required Uint8List secret,
    Uint8List? passphrase,
    required SingleSigVaultListItem item,
  }) async {
    await _saveSinglesigSecret(id, secret, passphrase, regenerateKey: false);
    await _saveSinglesigPrivacy(id, item);
  }

  Future<void> convertTaprootForModeTransition({
    required int id,
    required List<TaprootSeedInfoForSave> seedInfosForAdd,
    required TaprootVaultListItem item,
  }) async {
    await _saveTaprootSecrets(id, seedInfosForAdd, regenerateKey: false);
    await _saveTaprootPrivacy(id, item);
  }

  Future<void> convertMultisigForModeTransition({required int id, required MultisigVaultListItem item}) async {
    await _saveMultisigPrivacy(id, item);
  }

  /// 보안저장모드 전환 중 생성된 항목을 제거하고 원본 서명전용모드 암호문을
  /// 복원합니다.
  Future<void> revertSinglesigModeTransition({required int id, required String secretCiphertext}) async {
    final keyString = WalletStorageKeys.walletKey(id, WalletType.singleSignature);
    await _storageService.write(key: keyString, value: secretCiphertext);
    await _storageService.delete(key: WalletStorageKeys.passphraseEnabledKey(keyString));
    await _storageService.delete(key: WalletStorageKeys.privacyInfoKey(keyString));
  }

  Future<void> revertTaprootModeTransition({
    required int id,
    required Map<String, String> seedCiphertexts,
    required String seedIndexJson,
  }) async {
    for (final entry in seedCiphertexts.entries) {
      await _storageService.write(key: entry.key, value: entry.value);
    }
    await _storageService.write(key: WalletStorageKeys.taprootSeedIndexKey(id), value: seedIndexJson);
    final walletKey = WalletStorageKeys.walletKey(id, WalletType.taproot);
    await _storageService.delete(key: WalletStorageKeys.privacyInfoKey(walletKey));
  }

  Future<void> revertMultisigModeTransition({required int id}) async {
    final walletKey = WalletStorageKeys.walletKey(id, WalletType.multiSignature);
    await _storageService.delete(key: WalletStorageKeys.privacyInfoKey(walletKey));
  }
}

/// Library-private write-ops impl bound to a [SecureStorageStrategy].
class _SecureStorageOps implements WalletWriteOps {
  final SecureStorageStrategy _s;
  _SecureStorageOps(this._s);

  @override
  Future<void> persistSinglesigAdd({
    required int id,
    required Uint8List secret,
    Uint8List? passphrase,
    required SingleSigVaultListItem item,
  }) async {
    await _s._saveSinglesigSecret(id, secret, passphrase);
    try {
      await _s._saveSinglesigPrivacy(id, item);
    } catch (_) {
      await _s._deleteSinglesigSecret(id);
      rethrow;
    }
  }

  @override
  Future<void> persistMultisigAdd({required int id, required MultisigVaultListItem item}) async {
    await _s._saveMultisigPrivacy(id, item);
  }

  @override
  Future<void> persistTaprootAdd({
    required int id,
    required List<TaprootSeedInfoForSave> seedInfosForAdd,
    required TaprootVaultListItem item,
  }) async {
    try {
      await _s._saveTaprootSecrets(id, seedInfosForAdd);
      await _s._saveTaprootPrivacy(id, item);
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
    await _s._deletePrivacyInfo(id, type);
  }
}
