import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/exception/seed_invalidated_exception.dart';
import 'package:coconut_vault/model/exception/wallet_data_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_key_identifier.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/repository/migration/data_schema_migration_runner.dart';
import 'package:coconut_vault/repository/model/multisig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/single_sig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_linker.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/secure_storage_strategy.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/signing_only_strategy.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/wallet_persistence_strategy.dart';
import 'package:coconut_vault/repository/wallet_storage_cleaner.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_payload_codec.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class _ModeTransitionBackupEntry {
  final int walletId;
  final String originalKey;
  final String backupKey;

  const _ModeTransitionBackupEntry({required this.walletId, required this.originalKey, required this.backupKey});
}

/// 지갑의 public 정보는 shared prefs, 비밀 정보는 secure storage에 저장하는 역할을 하는 클래스입니다.
class WalletRepository {
  static const int currentDataSchemeVersion = 2;
  static String vaultTypeField = VaultListItemBase.vaultTypeField;

  final SecureStorageRepositoryContract _storageService;
  final SharedPrefsRepository _sharedPrefs;
  final SecureZoneRepositoryContract _secureZoneRepository;

  List<VaultListItemBase>? _vaultList;
  late bool _isSigningOnlyMode;
  late WalletPersistenceStrategy _strategy;
  get vaultList => _vaultList;

  Completer<void>? _walletLoadCancelToken;

  WalletRepository({
    bool isSigningOnlyMode = false,
    SecureStorageRepositoryContract? storageService,
    SharedPrefsRepository? sharedPrefs,
    SecureZoneRepositoryContract? secureZoneRepository,
  }) : _storageService = storageService ?? SecureStorageRepository(),
       _sharedPrefs = sharedPrefs ?? SharedPrefsRepository(),
       _secureZoneRepository = secureZoneRepository ?? SecureZoneRepository() {
    _isSigningOnlyMode = isSigningOnlyMode;
    _strategy =
        isSigningOnlyMode
            ? SigningOnlyStrategy(storageService: _storageService, secureZoneRepository: _secureZoneRepository)
            : SecureStorageStrategy(storageService: _storageService, secureZoneRepository: _secureZoneRepository);
  }

  int? _getSavedDataSchemeVersion() {
    return _sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion);
  }

  Future<void> updateDataSchemeVersion(int version) async {
    await _sharedPrefs.setInt(SharedPrefsKeys.kDataSchemeVersion, version);
  }

  Future<List<dynamic>?> loadVaultListJsonArrayString() async {
    String? jsonArrayString;

    jsonArrayString = _sharedPrefs.getString(SharedPrefsKeys.kVaultListField);
    int? savedDataSchemeVersion = _getSavedDataSchemeVersion();

    printLongString('--> $jsonArrayString');
    if (jsonArrayString.isEmpty || jsonArrayString == '[]') {
      _vaultList = [];

      if (savedDataSchemeVersion == null || currentDataSchemeVersion > savedDataSchemeVersion) {
        await updateDataSchemeVersion(currentDataSchemeVersion);
      }
      return null;
    }

    int previousDataSchemeVersion = savedDataSchemeVersion ?? 1;
    if (previousDataSchemeVersion < currentDataSchemeVersion) {
      // Invariant: signing-only mode never persists a vault list, so we can't reach here in that mode.
      assert(!_isSigningOnlyMode, 'migration must not run in signing-only mode');
      Logger.log('✅ 마이그레이션 시작: $savedDataSchemeVersion to $currentDataSchemeVersion');
      printLongString('--> jsonArrayString: $jsonArrayString');
      final migrationStrategy = SecureStorageStrategy();
      await DataSchemaMigrationRunner.runDataSchemaMigrations(
        previousDataSchemeVersion,
        currentDataSchemeVersion,
        _decodeWalletListJson(jsonArrayString),
        _sharedPrefs,
        migrationStrategy.writePrivacyInfo,
        _walletLoadCancelToken,
      );
      await updateDataSchemeVersion(currentDataSchemeVersion);
      jsonArrayString = _sharedPrefs.getString(SharedPrefsKeys.kVaultListField);
    }

    final jsonList = _decodeWalletListJson(jsonArrayString);

    return _repairPublicVaultList(jsonList);
  }

  List<dynamic> _decodeWalletListJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List<dynamic>) {
        throw const FormatException('Wallet list must be a JSON array.');
      }
      return decoded;
    } on FormatException catch (e) {
      throw InvalidWalletDataException('Invalid wallet list JSON.', cause: e);
    } on TypeError catch (e) {
      throw InvalidWalletDataException('Invalid wallet list structure.', cause: e);
    }
  }

  /// public list의 각 지갑에 대응하는 privacy info를 확인합니다.
  /// privacy info가 없는 항목만 orphan으로 판단해 public list에서 제거하고 저장합니다.
  /// 저장소 접근 오류와 잘못된 데이터는 orphan으로 처리하지 않고 호출자에게 전파합니다.
  Future<List<dynamic>> _repairPublicVaultList(List<dynamic> jsonList) async {
    final cleanedList = <dynamic>[];
    var hasOrphan = false;

    for (final raw in jsonList) {
      if (raw is! Map<String, dynamic>) {
        throw InvalidWalletDataException('Wallet entry must be a JSON object.');
      }

      final map = raw;
      final vaultTypeName = map[VaultListItemBase.vaultTypeField];
      final walletId = map['id'];
      if (vaultTypeName is! String || walletId is! int) {
        throw InvalidWalletDataException('Wallet entry has invalid id or vault type.');
      }

      WalletType? walletType;
      for (final type in WalletType.values) {
        if (type.name == vaultTypeName) {
          walletType = type;
          break;
        }
      }
      if (walletType == null) {
        throw InvalidWalletDataException('Unknown wallet type: $vaultTypeName');
      }

      try {
        await _getPrivacyInfo(walletId, walletType);
        cleanedList.add(raw);
      } on PrivacyInfoNotFoundException catch (e) {
        hasOrphan = true;
        Logger.log('Orphan wallet found in public list, removing: id=$walletId, reason=$e');
      }
    }

    if (hasOrphan) {
      final cleanedJsonString = jsonEncode(cleanedList);
      await _sharedPrefs.setString(SharedPrefsKeys.kVaultListField, cleanedJsonString);
    }

    return cleanedList;
  }

  Future<void> loadAndEmitEachWallet(List<dynamic> jsonList, Function(VaultListItemBase wallet) emitOneItem) async {
    _walletLoadCancelToken = Completer<void>();

    final vaultList = <VaultListItemBase>[];

    for (final raw in jsonList) {
      final enrichedJson = await _enrichVaultJsonWithPrivacy(raw as Map<String, dynamic>);

      VaultListItemBase item = await compute<Map<String, dynamic>, VaultListItemBase>(
        WalletIsolates.initializeWallet,
        enrichedJson,
      );

      // 지갑 로드 중 앱 백그라운드 이동 시 로드 중단
      if (_walletLoadCancelToken?.isCompleted == true) {
        return;
      }

      emitOneItem(item);
      vaultList.add(item);
    }

    _vaultList = vaultList;
  }

  Future<Map<String, dynamic>> _enrichVaultJsonWithPrivacy(Map<String, dynamic> json) async {
    final vaultTypeName = json[VaultListItemBase.vaultTypeField] as String;
    final walletType = WalletType.values.firstWhere((e) => e.name == vaultTypeName);
    final walletId = json['id'] as int;

    final privacyInfo = await _getPrivacyInfo(walletId, walletType);

    switch (walletType) {
      case WalletType.singleSignature:
        _applySingleSigPrivacyToJson(json, privacyInfo as SingleSigWalletPrivacyInfo);
        break;
      case WalletType.multiSignature:
        _applyMultisigPrivacyToJson(json, privacyInfo as MultisigWalletPrivacyInfo);
        break;
      case WalletType.taproot:
        _applyTaprootPrivacyToJson(json, privacyInfo as TaprootWalletPrivacyInfo);
        break;
    }

    return json;
  }

  void _applySingleSigPrivacyToJson(Map<String, dynamic> json, SingleSigWalletPrivacyInfo privacyInfo) {
    json[SingleSigVaultListItem.fieldDescriptor] = privacyInfo.descriptor;
    json[SingleSigVaultListItem.fieldSignerBsmsByAddressType] = privacyInfo.signerBsmsByAddressTypeName;
  }

  void _applyMultisigPrivacyToJson(Map<String, dynamic> json, MultisigWalletPrivacyInfo privacyInfo) {
    json[MultisigVaultListItem.fieldCoordinatorBsms] = privacyInfo.coordinatorBsms;

    // signers 리스트 요소들의 signerBsms, keyStore 비어있는 상태
    final List<dynamic> signersToPublicJson = json[MultisigVaultListItem.fieldSigners];
    for (int signerIndex = 0; signerIndex < signersToPublicJson.length; signerIndex++) {
      signersToPublicJson[signerIndex][MultisigSigner.fieldSignerBsms] =
          privacyInfo.signersPrivacyInfo[signerIndex].signerBsms;
      signersToPublicJson[signerIndex][MultisigSigner.fieldKeyStore] =
          privacyInfo.signersPrivacyInfo[signerIndex].keyStoreToJson;
    }
  }

  void _applyTaprootPrivacyToJson(Map<String, dynamic> json, TaprootWalletPrivacyInfo privacyInfo) {
    json[TaprootVaultListItem.fieldDescriptor] = privacyInfo.descriptor;
    json[TaprootVaultListItem.fieldKeyPathSeedInfos] =
        privacyInfo.keyPathSeedInfos.map((seedInfo) => seedInfo.toJson()).toList();
    json[TaprootVaultListItem.fieldScriptPathSeedInfos] =
        privacyInfo.scriptPathSeedInfos.map((seedInfo) => seedInfo.toJson()).toList();
  }

  Future<void> _loadVaultList() async {
    final jsonList = await loadVaultListJsonArrayString() ?? [];
    await loadAndEmitEachWallet(jsonList, (VaultListItemBase wallet) {});
  }

  Future<SingleSigVaultListItem> addSinglesigWallet(SingleSigWalletCreateDto wallet) async {
    final vaults = await _ensureLoaded();
    final linker = WalletLinker(vaults);

    final int nextId = _getNextWalletId();
    wallet.id = nextId;
    final Map<String, dynamic> vaultData = wallet.toJson();
    List<SingleSigVaultListItem> vaultListResult = await compute(WalletIsolates.createSingleSigVault, vaultData);

    linker.linkNewSinglesigWallet(vaultListResult.first);
    vaults.add(vaultListResult[0]);
    try {
      await _strategy.mutate(
        execute:
            (ops) => ops.persistSinglesigAdd(
              id: nextId,
              secret: wallet.mnemonic!,
              passphrase: wallet.passphrase,
              item: vaultListResult[0],
            ),
        snapshot: () => vaults,
      );
    } catch (error) {
      vaults.removeLast();
      linker.unlinkSinglesigWallet(vaultListResult.first.id);
      // Idempotent cleanup: if persistSinglesigAdd already rolled back internally the disk delete
      // is a no-op; if the public list save failed this removes the orphaned wallet data.
      // Either way the trailing public list save inside mutate re-syncs disk with the reverted memory.
      await _strategy.mutate(
        execute: (ops) => ops.deleteWalletData(nextId, WalletType.singleSignature),
        snapshot: () => vaults,
      );
      rethrow;
    }
    await _recordNextWalletId();
    return vaultListResult[0];
  }

  Future<MultisigVaultListItem> addMultisigWallet(
    MultisigWallet wallet, {
    bool shouldAttachInnerVaultMetadata = false,
  }) async {
    final vaults = await _ensureLoaded();
    final linker = WalletLinker(vaults);

    final int nextId = _getNextWalletId();
    wallet.id = nextId;
    if (shouldAttachInnerVaultMetadata) {
      for (final signer in wallet.signers!) {
        linker.attachInnerWalletMetadata(signer);
      }
    }
    final Map<String, dynamic> data = wallet.toJson();
    MultisigVaultListItem newMultisigVault = await compute(WalletIsolates.createMultisigVault, data);
    Logger.logLongString('${newMultisigVault.toJson()}');
    linker.linkNewMultisigWallet(nextId, wallet.signers!);
    vaults.add(newMultisigVault);
    try {
      await _strategy.mutate(
        execute: (ops) => ops.persistMultisigAdd(id: nextId, item: newMultisigVault),
        snapshot: () => vaults,
      );
    } catch (error) {
      vaults.removeLast();
      linker.unlinkMultisigWallet(nextId);
      await _strategy.mutate(
        execute: (ops) => ops.deleteWalletData(nextId, WalletType.multiSignature),
        snapshot: () => vaults,
      );
      rethrow;
    }
    await _recordNextWalletId();
    return newMultisigVault;
  }

  Future<TaprootVaultListItem> addTaprootWallet(TaprootWalletCreateDto walletCreateDto) async {
    final vaults = await _ensureLoaded();

    final int nextId = _getNextWalletId();
    walletCreateDto.id = nextId;

    final Map<String, dynamic> data = walletCreateDto.toJson();
    final TaprootCreationResult result = await compute(WalletIsolates.createTaprootVault, data);
    final newTaprootVault = result.vault;
    Logger.logLongString('${newTaprootVault.toJson()}');
    vaults.add(newTaprootVault);
    final seedInfosForAdd = [...result.keyPathSaves, ...result.scriptPathSaves];
    assert(
      seedInfosForAdd.map((e) => e.extendedPublicKey).toSet().length == seedInfosForAdd.length,
      'Duplicate extendedPublicKey detected in taproot seedInfosForAdd',
    );
    try {
      await _strategy.mutate(
        execute: (ops) => ops.persistTaprootAdd(id: nextId, item: newTaprootVault, seedInfosForAdd: seedInfosForAdd),
        snapshot: () => vaults,
      );
    } catch (error) {
      vaults.removeLast();
      await _strategy.mutate(
        execute: (ops) => ops.deleteWalletData(nextId, WalletType.taproot),
        snapshot: () => vaults,
      );
      rethrow;
    }
    await _recordNextWalletId();
    return newTaprootVault;
  }

  Future<WalletPrivacyInfo> _getPrivacyInfo(int id, WalletType walletType) async {
    final key = WalletStorageKeys.privacyInfoKey(WalletStorageKeys.walletKey(id, walletType));
    final String? privacyInfoString = await _storageService.readStrict(key: key);
    if (privacyInfoString == null) {
      throw PrivacyInfoNotFoundException(walletId: id, walletType: walletType);
    }

    try {
      final json = jsonDecode(privacyInfoString);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Privacy info must be a JSON object.');
      }

      switch (walletType) {
        case WalletType.singleSignature:
          return SingleSigWalletPrivacyInfo.fromJson(json);
        case WalletType.multiSignature:
          return MultisigWalletPrivacyInfo.fromJson(json);
        case WalletType.taproot:
          return TaprootWalletPrivacyInfo.fromJson(json);
      }
    } on FormatException catch (e) {
      throw InvalidWalletDataException('Invalid privacy info for wallet id=$id, type=${walletType.name}', cause: e);
    } on TypeError catch (e) {
      throw InvalidWalletDataException(
        'Invalid privacy info structure for wallet id=$id, type=${walletType.name}',
        cause: e,
      );
    } on ArgumentError catch (e) {
      throw InvalidWalletDataException(
        'Invalid privacy info values for wallet id=$id, type=${walletType.name}',
        cause: e,
      );
    }
  }

  int _getNextWalletId() {
    return _sharedPrefs.getInt(SharedPrefsKeys.kNextIdField) ?? 1;
  }

  Future<void> _recordNextWalletId() async {
    final int nextId = _getNextWalletId();
    await _sharedPrefs.setInt(SharedPrefsKeys.kNextIdField, nextId + 1);
  }

  Future<({Uint8List secret, Uint8List? passphrase})> _decryptSeed(String key, {bool autoAuth = true}) async {
    final combinedBase64 = await _storageService.read(key: key);
    if (combinedBase64 == null && Platform.isIOS) {
      throw SeedInvalidatedException();
    }
    final (Uint8List iv, Uint8List ciphertext) = EncryptResult.fromCombinedBase64(combinedBase64!);

    final Uint8List? plaintext;
    try {
      plaintext = await _secureZoneRepository.decrypt(alias: key, iv: iv, ciphertext: ciphertext, autoAuth: autoAuth);
    } on PlatformException catch (e) {
      if (Platform.isAndroid && (e.code == 'INVALID_KEY' || e.code == 'KEY_INVALIDATED' || e.code == 'KEY_ERROR')) {
        throw SeedInvalidatedException();
      }
      rethrow;
    }

    final parsed = SecureZonePayloadCodec.parsePlaintext(plaintext!);
    return parsed;
  }

  Future<({Uint8List secret, Uint8List? passphrase})> _decryptSingleSigSeed(int id, {bool autoAuth = true}) async {
    assert(getVaultById(id) is SingleSigVaultListItem);
    final key = WalletStorageKeys.walletKey(id, WalletType.singleSignature);
    return _decryptSeed(key, autoAuth: autoAuth);
  }

  Future<Uint8List> getSingleSigSecret(int id, {bool autoAuth = true}) async {
    final parsed = await _decryptSingleSigSeed(id, autoAuth: autoAuth);
    return parsed.secret;
  }

  Future<Seed> getSingleSigSeedInSigningOnlyMode(int id) async {
    final parsed = await _decryptSingleSigSeed(id);
    final Uint8List secret = parsed.secret;
    final Uint8List? passphrase = parsed.passphrase;

    return Seed.fromMnemonic(secret, passphrase: passphrase);
  }

  Future<({Uint8List secret, Uint8List? passphrase})> _decryptTaprootSeed(
    int id,
    TaprootSeedKeyIdentifier seedIdentifier, {
    bool autoAuth = true,
  }) async {
    assert(getVaultById(id) is TaprootVaultListItem);
    final key = WalletStorageKeys.taprootSeedKey(id, seedIdentifier.extendedPublicKey);
    return _decryptSeed(key, autoAuth: autoAuth);
  }

  Future<Uint8List> getTaprootSecret(int id, TaprootSeedKeyIdentifier seedIdentifier, {bool autoAuth = true}) async {
    final parsed = await _decryptTaprootSeed(id, seedIdentifier, autoAuth: autoAuth);
    return parsed.secret;
  }

  Future<Seed> getTaprootSeedInSigningOnlyMode(int id, TaprootSeedKeyIdentifier seedIdentifier) async {
    if (!_isSigningOnlyMode) throw StateError('getTaprootSeedInSigningOnlyMode can only called on signing only mode.');
    final parsed = await _decryptTaprootSeed(id, seedIdentifier);
    final Uint8List secret = parsed.secret;
    final Uint8List? passphrase = parsed.passphrase;

    return Seed.fromMnemonic(secret, passphrase: passphrase);
  }

  Future<bool> hasPassphrase(int walletId) async {
    if (getVaultById(walletId) is! SingleSigVaultListItem) return false;
    return _strategy.hasPassphrase(walletId);
  }

  Future<bool> deleteWallet(int id) async {
    final vaults = _requireLoaded();

    final index = vaults.indexWhere((item) => item.id == id);
    if (index == -1) {
      // 중복 호출 등으로 이미 삭제된 경우. no-op로 처리하되 로그로 추적 가능하게.
      Logger.log('deleteWallet: id=$id not found (already deleted or duplicate call)');
      return false;
    }
    final vault = vaults[index];
    final vaultType = vault.vaultType;

    // 원본 _vaultList는 건드리지 않고, 새로운 상태를 별도로 준비한다.
    final newVaults = List<VaultListItemBase>.from(vaults);
    WalletLinker(newVaults).unlinkOnDelete(vault);
    newVaults.removeAt(index);

    try {
      await _strategy.mutate(execute: (ops) => ops.deleteWalletData(id, vaultType), snapshot: () => newVaults);
    } catch (e) {
      // execute 단계에서는 secret/privacy 삭제가 이미 완료되었을 수 있다.
      // public list에는 지갑이 여전히 남아있을 수 있으므로, public list 갱신만이라도 재시도한다.
      try {
        await _strategy.savePublicVaultList(newVaults);
      } catch (_) {
        // cleanup 실패 시 원래 예외를 던진다.
      }
      rethrow;
    }

    // 저장이 성공한 후에만 메모리 상태를 교체한다.
    _vaultList = newVaults;

    return true;
  }

  /// 서명 전용 모드 - 모든 지갑 삭제
  Future<void> deleteWallets() async {
    final vaults = _requireLoaded();

    final toDelete = List.of(vaults);
    await _strategy.mutate(
      execute: (ops) async {
        for (final vault in toDelete) {
          await ops.deleteWalletData(vault.id, vault.vaultType);
        }
      },
      snapshot: () => const <VaultListItemBase>[],
    );

    // 저장이 성공한 후에만 메모리 상태를 비운다.
    _vaultList = [];
  }

  Future<bool> updateWallet(int id, String newName, int colorIndex, int iconIndex) async {
    final vaults = _requireLoaded();

    final index = vaults.indexWhere((item) => item.id == id);
    final target = vaults[index];
    if (target.vaultType == WalletType.singleSignature) {
      SingleSigVaultListItem singleSigVault = target as SingleSigVaultListItem;
      Map<int, int>? linkedMultisigInfo = singleSigVault.linkedMultisigInfo;
      // 연결된 MultisigVaultListItem의 signers 객체도 UI 업데이트가 필요
      if (linkedMultisigInfo != null && linkedMultisigInfo.isNotEmpty) {
        for (var entry in linkedMultisigInfo.entries) {
          final linkedVault = getVaultById(entry.key);
          if (linkedVault is! MultisigVaultListItem) continue;

          linkedVault.signers[entry.value].name = newName;
          linkedVault.signers[entry.value].colorIndex = colorIndex;
          linkedVault.signers[entry.value].iconIndex = iconIndex;
        }
      }

      singleSigVault.name = newName;
      singleSigVault.colorIndex = colorIndex;
      singleSigVault.iconIndex = iconIndex;
    } else if (target.vaultType == WalletType.multiSignature || target.vaultType == WalletType.taproot) {
      target.name = newName;
      target.colorIndex = colorIndex;
      target.iconIndex = iconIndex;
    } else {
      throw '[wallet_list_manager/updateWallet]: _vaultList[$index] has wrong type: ${target.vaultType}';
    }

    await _strategy.savePublicVaultList(vaults);
    return true;
  }

  VaultListItemBase? getVaultById(int id) {
    final list = _vaultList;
    if (list == null) return null;
    final idx = list.indexWhere((element) => element.id == id);
    if (idx == -1) return null;
    return list[idx];
  }

  Future<MultisigVaultListItem> updateExternalSignerMemo(int walletId, int signerIndex, String? newMemo) async {
    final vaults = _requireLoaded();
    var wallet = getVaultById(walletId);
    assert(wallet != null);
    (wallet as MultisigVaultListItem).signers[signerIndex].memo = newMemo;

    await _strategy.savePublicVaultList(vaults);
    return wallet;
  }

  Future<MultisigVaultListItem> updateExternalSignerSource(
    int walletId,
    int signerIndex,
    HardwareWalletType newSignerSource,
  ) async {
    final vaults = _requireLoaded();
    var wallet = getVaultById(walletId);
    assert(wallet != null);
    (wallet as MultisigVaultListItem).signers[signerIndex].signerSource = newSignerSource;

    await _strategy.savePublicVaultList(vaults);
    return wallet;
  }

  Future<void> resetAll() async {
    await WalletStorageCleaner.clearAll(
      wallets: _vaultList,
      storageService: _storageService,
      secureZoneRepository: _secureZoneRepository,
    );
  }

  Future<void> updateIsSigningOnlyMode(bool isSigningOnlyMode) async {
    if (_isSigningOnlyMode == isSigningOnlyMode) return;
    if (!isSigningOnlyMode) {
      await _changeToSecureStorageMode();
      _strategy = SecureStorageStrategy(storageService: _storageService, secureZoneRepository: _secureZoneRepository);
    } else {
      await deleteWallets();
      _strategy = SigningOnlyStrategy(storageService: _storageService, secureZoneRepository: _secureZoneRepository);
    }
    _isSigningOnlyMode = isSigningOnlyMode;
  }

  Future<List<String>> _secureStorageKeysForVault(VaultListItemBase vault) async {
    final keys = <String>{};
    if (vault is SingleSigVaultListItem) {
      keys.add(WalletStorageKeys.walletKey(vault.id, WalletType.singleSignature));
    } else if (vault is TaprootVaultListItem) {
      keys.add(WalletStorageKeys.taprootSeedIndexKey(vault.id));
      final indexKeys = await _readTaprootSeedIndex(vault.id);
      keys.addAll(indexKeys);
      for (final seedInfo in vault.keyPathSeedInfos) {
        keys.add(WalletStorageKeys.taprootSeedKey(vault.id, seedInfo.extendedPublicKey));
      }
      for (final scriptPath in vault.scriptPathSeedInfos) {
        for (final seedInfo in scriptPath.seedInfos) {
          keys.add(WalletStorageKeys.taprootSeedKey(vault.id, seedInfo.extendedPublicKey));
        }
      }
    }
    return keys.toList();
  }

  Future<List<String>> _readTaprootSeedIndex(int walletId) async {
    final indexJson = await _storageService.read(key: WalletStorageKeys.taprootSeedIndexKey(walletId));
    if (indexJson == null) return [];
    try {
      return List<String>.from(jsonDecode(indexJson));
    } catch (_) {
      return [];
    }
  }

  Future<void> _cleanupModeTransitionMarkerAndBackups() async {
    final allKeys = await _storageService.getAllKeys();
    const backupPrefix = WalletStorageKeys.appModeTransitionBackupPrefix;
    final backupKeys = allKeys.where((k) => k.startsWith(backupPrefix)).toList();
    for (final key in backupKeys) {
      await _storageService.delete(key: key);
    }
    await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultModeTransitionMarker);
  }

  Future<void> _restoreVaultFromModeTransitionBackup(
    VaultListItemBase vault,
    List<_ModeTransitionBackupEntry> backupEntries,
    SecureStorageStrategy secureStrategy,
  ) async {
    final walletBackupEntries = backupEntries.where((e) => e.walletId == vault.id).toList();

    if (vault is SingleSigVaultListItem) {
      final secretEntry = walletBackupEntries.firstWhere(
        (e) => e.originalKey == WalletStorageKeys.walletKey(vault.id, WalletType.singleSignature),
      );
      final ciphertext = await _storageService.read(key: secretEntry.backupKey);
      if (ciphertext != null) {
        await secureStrategy.revertSinglesigModeTransition(id: vault.id, secretCiphertext: ciphertext);
      }
      return;
    }

    if (vault is TaprootVaultListItem) {
      final seedCiphertexts = <String, String>{};
      String? seedIndexJson;
      for (final entry in walletBackupEntries) {
        final value = await _storageService.read(key: entry.backupKey);
        if (value == null) continue;
        if (entry.originalKey == WalletStorageKeys.taprootSeedIndexKey(vault.id)) {
          seedIndexJson = value;
        } else {
          seedCiphertexts[entry.originalKey] = value;
        }
      }
      await secureStrategy.revertTaprootModeTransition(
        id: vault.id,
        seedCiphertexts: seedCiphertexts,
        seedIndexJson: seedIndexJson ?? '[]',
      );
      return;
    }

    if (vault is MultisigVaultListItem) {
      await secureStrategy.revertMultisigModeTransition(id: vault.id);
    }
  }

  Future<void> _changeToSecureStorageMode() async {
    assert(_isSigningOnlyMode);
    if (_vaultList == null || _vaultList!.isEmpty) {
      return;
    }

    final secureStrategy = SecureStorageStrategy(
      storageService: _storageService,
      secureZoneRepository: _secureZoneRepository,
    );

    // 이전에 중단된 전환의 잔여물이 있으면 먼저 정리합니다.
    await _cleanupModeTransitionMarkerAndBackups();

    final backupEntries = <_ModeTransitionBackupEntry>[];

    // 1. 모든 지갑의 기존 암호문을 백업 키에 복사합니다.
    for (final vault in _vaultList!) {
      final keys = await _secureStorageKeysForVault(vault);
      for (final key in keys) {
        final value = await _storageService.read(key: key);
        if (value != null) {
          final backupKey = WalletStorageKeys.appModeTransitionBackupKey(key);
          await _storageService.write(key: backupKey, value: value);
          backupEntries.add(_ModeTransitionBackupEntry(walletId: vault.id, originalKey: key, backupKey: backupKey));
        }
      }
    }

    // 2. 마커를 기록합니다.
    await _sharedPrefs.setString(
      SharedPrefsKeys.kVaultModeTransitionMarker,
      jsonEncode({
        'status': 'converting',
        'direction': 'signingOnlyToSecureStorage',
        'walletIds': _vaultList!.map((w) => w.id).toList(),
      }),
    );

    final startedIds = <int>[];

    try {
      // 3. 순차적으로 복호화 → passphrase 제거 → 재암호화 → 덮어쓰기
      for (final vault in _vaultList!) {
        startedIds.add(vault.id);
        if (vault is MultisigVaultListItem) {
          await secureStrategy.convertMultisigForModeTransition(id: vault.id, item: vault);
        } else if (vault is TaprootVaultListItem) {
          final seedInfosForAdd = <TaprootSeedInfoForSave>[];
          for (final seedInfo in vault.keyPathSeedInfos) {
            final seed = await getTaprootSeedInSigningOnlyMode(
              vault.id,
              TaprootSeedKeyIdentifier(extendedPublicKey: seedInfo.extendedPublicKey),
            );
            seedInfosForAdd.add(
              TaprootSeedInfoForSave(
                secretPassphrasePair: (secret: seed.mnemonic, passphrase: null),
                extendedPublicKey: seedInfo.extendedPublicKey,
              ),
            );
          }
          for (final scriptPathSeedInfo in vault.scriptPathSeedInfos) {
            for (final seedInfo in scriptPathSeedInfo.seedInfos) {
              final seed = await getTaprootSeedInSigningOnlyMode(
                vault.id,
                TaprootSeedKeyIdentifier(extendedPublicKey: seedInfo.extendedPublicKey),
              );
              seedInfosForAdd.add(
                TaprootSeedInfoForSave(
                  secretPassphrasePair: (secret: seed.mnemonic, passphrase: null),
                  extendedPublicKey: seedInfo.extendedPublicKey,
                ),
              );
            }
          }
          await secureStrategy.convertTaprootForModeTransition(
            id: vault.id,
            item: vault,
            seedInfosForAdd: seedInfosForAdd,
          );
        } else if (vault is SingleSigVaultListItem) {
          final Seed seed = await getSingleSigSeedInSigningOnlyMode(vault.id);
          await secureStrategy.convertSinglesigForModeTransition(
            id: vault.id,
            secret: seed.mnemonic,
            passphrase: seed.passphrase.isEmpty ? null : seed.passphrase,
            item: vault,
          );
        }
      }

      // 4. 공개 vault list 저장
      await secureStrategy.savePublicVaultList(_vaultList!);
    } catch (e) {
      // 5. 하나라도 실패하면 즉시 전체 롤백 (시작한 모든 지갑을 원상복구)
      for (final id in startedIds) {
        final vault = _vaultList!.firstWhere((v) => v.id == id);
        await _restoreVaultFromModeTransitionBackup(vault, backupEntries, secureStrategy);
      }
      rethrow;
    } finally {
      // 6. 백업 키 및 마커 삭제
      await _cleanupModeTransitionMarkerAndBackups();
    }
  }

  Future<void> updateSingleSigAccountVault(int id, int newAccountIndex, {Uint8List? inputPassphrase}) async {
    final vaults = _requireLoaded();

    final index = vaults.indexWhere((item) => item.id == id);
    if (index == -1) throw Exception('Vault not found');

    final existingVault = vaults[index];
    if (existingVault is! SingleSigVaultListItem) {
      throw ArgumentError(
        'Only SingleSigVaultListItem is supported for account update. Vault type is ${existingVault.vaultType}',
      );
    }

    final currentCoconutVault = existingVault.coconutVault as SingleSignatureVault;
    final parsed = await _decryptSingleSigSeed(id);
    final passphrase = _strategy.passphraseStoredWithSecret ? parsed.passphrase : inputPassphrase;

    final derivedNewAccountVault = await compute(WalletIsolates.deriveNewAccountVault, {
      'mnemonic': parsed.secret,
      'passphrase': passphrase,
      'addressTypeName': currentCoconutVault.addressType.name,
      'currentAccountIndex': currentCoconutVault.accountIndex,
      'newAccountIndex': newAccountIndex,
      'expectedMfp': currentCoconutVault.keyStore.masterFingerprint,
    });

    parsed.secret.wipe();
    if (_strategy.passphraseStoredWithSecret && parsed.passphrase != null) {
      parsed.passphrase!.wipe();
    }

    final rawJson =
        existingVault.toPublicJson()
          ..[SingleSigVaultListItem.fieldDescriptor] = derivedNewAccountVault['descriptor']
          ..[SingleSigVaultListItem.fieldSignerBsmsByAddressType] = existingVault.signerBsmsByAddressType.map(
            (k, v) => MapEntry(k.name, v),
          )
          ..['derivationPath'] = derivedNewAccountVault['derivationPath'];

    final updatedItem = await compute<Map<String, dynamic>, VaultListItemBase>(
      WalletIsolates.initializeWallet,
      rawJson,
    );

    vaults[index] = updatedItem;

    await _strategy.updateSinglesigPrivacy(id, updatedItem as SingleSigVaultListItem);
    await _strategy.savePublicVaultList(vaults);
  }

  /// Ensures the vault list is loaded, lazy-loading on first access.
  /// Use in entry-point write methods that can be called before any explicit load.
  Future<List<VaultListItemBase>> _ensureLoaded() async {
    if (_vaultList == null) {
      await _loadVaultList();
    }
    return _vaultList!;
  }

  /// Asserts the vault list has already been loaded.
  /// Use in methods whose preconditions guarantee a prior load.
  List<VaultListItemBase> _requireLoaded() {
    final list = _vaultList;
    if (list == null) {
      throw StateError('WalletRepository: vault list has not been loaded yet');
    }
    return list;
  }

  void dispose() {
    try {
      if (_walletLoadCancelToken != null && !_walletLoadCancelToken!.isCompleted) {
        _walletLoadCancelToken!.complete();
      }
    } catch (e) {
      Logger.error(e);
    }
  }
}
