import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/exception/seed_invalidated_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/repository/migration/data_schema_migration_runner.dart';
import 'package:coconut_vault/repository/model/multisig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/single_sig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_payload_codec.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/coconut/extended_pubkey_utils.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 지갑의 public 정보는 shared prefs, 비밀 정보는 secure storage에 저장하는 역할을 하는 클래스입니다.
class WalletRepository {
  static const int currentDataSchemeVersion = 2;
  static String nextIdField = 'nextId';
  static String vaultTypeField = VaultListItemBase.vaultTypeField;

  final SecureStorageRepository _storageService = SecureStorageRepository();
  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();
  final SecureZoneRepository _secureZoneRepository = SecureZoneRepository();

  List<VaultListItemBase>? _vaultList;
  late bool _isSigningOnlyMode;
  late WalletPersistenceStrategy _strategy;
  get vaultList => _vaultList;

  Completer<void>? _walletLoadCancelToken;

  WalletRepository({bool isSigningOnlyMode = false}) {
    _isSigningOnlyMode = isSigningOnlyMode;
    _strategy = isSigningOnlyMode ? SigningOnlyStrategy() : SecureStorageStrategy();
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

    //printLongString('--> $jsonArrayString');
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
        jsonDecode(jsonArrayString),
        _sharedPrefs,
        migrationStrategy.writePrivacyInfo,
        _walletLoadCancelToken,
      );
      await updateDataSchemeVersion(currentDataSchemeVersion);
      jsonArrayString = _sharedPrefs.getString(SharedPrefsKeys.kVaultListField);
    }

    return jsonDecode(jsonArrayString);
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

  Future<void> _loadVaultList() async {
    final jsonList = await loadVaultListJsonArrayString() ?? [];
    await loadAndEmitEachWallet(jsonList, (VaultListItemBase wallet) {});
  }

  Future<SingleSigVaultListItem> addSinglesigWallet(SingleSigWalletCreateDto wallet) async {
    if (_vaultList == null) {
      await _loadVaultList();
    }

    final int nextId = _getNextWalletId();
    wallet.id = nextId;
    final Map<String, dynamic> vaultData = wallet.toJson();
    List<SingleSigVaultListItem> vaultListResult = await compute(WalletIsolates.addVault, vaultData);

    _linkNewSinglesigVaultToMultisigVaults(vaultListResult.first);
    _vaultList!.add(vaultListResult[0]);
    try {
      await _strategy.persistSinglesigAdd(
        id: nextId,
        secret: wallet.mnemonic!,
        passphrase: wallet.passphrase,
        item: vaultListResult[0],
      );
      await _strategy.savePublicVaultList(_vaultList!);
    } catch (error) {
      _vaultList!.removeLast();
      _unlinkSinglesigVaultFromMultisigVaults(vaultListResult.first.id);
      // Idempotent cleanup: if persistSinglesigAdd already rolled back internally this is a no-op,
      // if savePublicVaultList failed this removes the wallet data from disk.
      await _strategy.deleteWalletData(nextId, WalletType.singleSignature);
      rethrow;
    }
    await _recordNextWalletId();
    return vaultListResult[0];
  }

  Future<WalletPrivacyInfo> _getPrivacyInfo(int id, WalletType walletType) async {
    final key = WalletStorageKeys.privacyInfoKey(WalletStorageKeys.walletKey(id, walletType));
    final String? privacyInfoString = await _storageService.read(key: key);
    if (privacyInfoString == null) {
      throw "Privacy data cannot be found";
    }

    if (walletType == WalletType.singleSignature) {
      return SingleSigWalletPrivacyInfo.fromJson(jsonDecode(privacyInfoString));
    } else if (walletType == WalletType.multiSignature) {
      return MultisigWalletPrivacyInfo.fromJson(jsonDecode(privacyInfoString));
    }
    throw "Unsupported wallet type";
  }

  Future<void> _removePublicInfo() async {
    await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.vaultListLength);
    await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultListField);
  }

  void _linkNewSinglesigVaultToMultisigVaults(SingleSigVaultListItem singlesigItem) {
    outerLoop:
    for (int i = 0; i < _vaultList!.length; i++) {
      VaultListItemBase vault = _vaultList![i];
      // 싱글 시그는 스킵
      if (vault.vaultType == WalletType.singleSignature) continue;

      List<MultisigSigner> signers = (vault as MultisigVaultListItem).signers;
      // 멀티 시그만 판단
      String expectedMfp = (singlesigItem.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;

      // singlesigItem의 p2wsh용 derivationPath 가져오기 (BSMS에서)
      final bsms = Bsms.parseSigner(singlesigItem.signerBsmsByAddressType[AddressType.p2wsh]!);
      String expectedDerivationPath = bsms.signer!.path;
      String expectedXpub = bsms.signer!.extendedPublicKey.serialize(toXpub: true);
      for (int j = 0; j < signers.length; j++) {
        String signerMfp = signers[j].keyStore.masterFingerprint;
        String signerDerivationPath = signers[j].getSignerDerivationPath();
        String signerXpub = Bsms.parseSigner(signers[j].signerBsms!).signer!.extendedPublicKey.serialize(toXpub: true);
        // masterFingerprint와 derivationPath 모두 일치해야 함
        if (signerMfp.toUpperCase() == expectedMfp.toUpperCase() &&
            signerDerivationPath == expectedDerivationPath &&
            signerXpub == expectedXpub) {
          // 다중 서명 지갑에서 signer로 사용되고 있는 mfp와 새로 추가된 볼트의 mfp가 같으면 정보를 변경
          // 멀티시그 지갑 정보 변경
          (_vaultList![i] as MultisigVaultListItem).signers[j].linkInternalWallet(singlesigItem);
          // 싱글시그 지갑 정보 변경
          Map<int, int> linkedMultisigInfo = {vault.id: j};
          if (singlesigItem.linkedMultisigInfo == null) {
            singlesigItem.linkedMultisigInfo = linkedMultisigInfo;
          } else {
            singlesigItem.linkedMultisigInfo!.addAll(linkedMultisigInfo);
          }
          continue outerLoop; // 같은 singlesig가 하나의 multisig 지갑에 2번 이상 signer로 등록될 수 없으므로
        }
      }
    }
  }

  void _unlinkSinglesigVaultFromMultisigVaults(int singleSigWalletId) {
    outerLoop:
    for (int i = 0; i < _vaultList!.length; i++) {
      VaultListItemBase vault = _vaultList![i];
      // 싱글 시그는 스킵
      if (vault.vaultType == WalletType.singleSignature) continue;

      List<MultisigSigner> signers = (vault as MultisigVaultListItem).signers;
      for (int j = 0; j < signers.length; j++) {
        if (signers[j].innerVaultId == singleSigWalletId) {
          signers[j].unlinkInternalWallet();
          continue outerLoop;
        }
      }
    }
  }

  Future<MultisigVaultListItem> addMultisigWallet(
    MultisigWallet wallet, {
    bool shouldAttachInnerVaultMetadata = false,
  }) async {
    if (_vaultList == null) {
      await _loadVaultList();
    }

    final int nextId = _getNextWalletId();
    wallet.id = nextId;
    if (shouldAttachInnerVaultMetadata) {
      for (final signer in wallet.signers!) {
        _attachInnerVaultMetadata(multisigSigner: signer);
      }
    }
    final Map<String, dynamic> data = wallet.toJson();
    MultisigVaultListItem newMultisigVault = await compute(WalletIsolates.addMultisigVault, data);
    Logger.logLongString('${newMultisigVault.toJson()}');
    // update SinglesigVaultListItem multsig key map
    _linkNewMultisigVaultToSingleSigVaults(wallet.signers!, nextId);
    _vaultList!.add(newMultisigVault);
    try {
      await _strategy.persistMultisigAdd(id: nextId, item: newMultisigVault);
      await _strategy.savePublicVaultList(_vaultList!);
    } catch (error) {
      _vaultList!.removeLast();
      _unlinkMultisigVaultFromSingleSigVaults(nextId);
      await _strategy.deleteWalletData(nextId, WalletType.multiSignature);
      rethrow;
    }
    await _recordNextWalletId();
    return newMultisigVault;
  }

  void _attachInnerVaultMetadata({required MultisigSigner multisigSigner}) {
    assert(_vaultList != null);
    assert(multisigSigner.signerBsms != null && multisigSigner.signerBsms!.isNotEmpty);

    final parsedInputBsms = SignerBsms.parse(multisigSigner.signerBsms!);
    final inputKey = parsedInputBsms.extendedKey;

    final vaultIndex = _vaultList!.indexWhere((element) {
      if (element is! SingleSigVaultListItem) return false;

      final String rawBsmsString = element.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false);

      try {
        final targetBsmsObj = SignerBsms.parse(rawBsmsString);
        final targetKey = targetBsmsObj.extendedKey;

        return isEquivalentExtendedPubKey(inputKey, targetKey);
      } catch (e) {
        return false;
      }
    });

    if (vaultIndex == -1) return;

    final vault = _vaultList![vaultIndex];
    multisigSigner.innerVaultId = vault.id;
    multisigSigner.name = vault.name;
    multisigSigner.colorIndex = vault.colorIndex;
    multisigSigner.iconIndex = vault.iconIndex;
  }

  /// 멀티시그 지갑이 추가될 때 (생성 또는 복사) 사용된 싱글시그 지갑들의 linkedMultisigInfo를 업데이트 합니다.
  void _linkNewMultisigVaultToSingleSigVaults(List<MultisigSigner> signers, int newWalletId) {
    // for SinglesigVaultListItem multsig key map update
    for (int i = 0; i < signers.length; i++) {
      var signer = signers[i];
      if (signers[i].innerVaultId == null) continue;
      SingleSigVaultListItem ssv =
          _vaultList!.firstWhere((element) => element.id == signer.innerVaultId!) as SingleSigVaultListItem;

      var keyMap = {newWalletId: i};
      if (ssv.linkedMultisigInfo != null) {
        ssv.linkedMultisigInfo!.addAll(keyMap);
      } else {
        ssv.linkedMultisigInfo = keyMap;
      }
    }
  }

  void _unlinkMultisigVaultFromSingleSigVaults(int multisigWalletId) {
    for (int i = 0; i < _vaultList!.length; i++) {
      VaultListItemBase vault = _vaultList![i];
      // 싱글 시그는 스킵
      if (vault.vaultType == WalletType.multiSignature) continue;
      SingleSigVaultListItem ssv = _vaultList![i] as SingleSigVaultListItem;
      ssv.linkedMultisigInfo?.remove(multisigWalletId);
    }
  }

  int _getNextWalletId() {
    return _sharedPrefs.getInt(nextIdField) ?? 1;
  }

  Future<void> _recordNextWalletId() async {
    final int nextId = _getNextWalletId();
    await _sharedPrefs.setInt(nextIdField, nextId + 1);
  }

  Future<({Uint8List secret, Uint8List? passphrase})> _decryptSecret(int id, {bool autoAuth = true}) async {
    final key = WalletStorageKeys.walletKey(id, WalletType.singleSignature);
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

  Future<Uint8List> getSecret(int id, {bool autoAuth = true}) async {
    final parsed = await _decryptSecret(id, autoAuth: autoAuth);
    return parsed.secret;
  }

  Future<Seed> getSeedInSigningOnlyMode(int id) async {
    final parsed = await _decryptSecret(id);
    final Uint8List secret = parsed.secret;
    final Uint8List? passphrase = parsed.passphrase;

    return Seed.fromMnemonic(secret, passphrase: passphrase);
  }

  Future<bool> hasPassphrase(int walletId) async {
    return _strategy.hasPassphrase(walletId);
  }

  Future<bool> deleteWallet(int id) async {
    if (_vaultList == null) {
      throw '[wallet_list_manager/deleteWallet]: vaultList is empty';
    }

    final index = _vaultList!.indexWhere((item) => item.id == id);
    if (index == -1) {
      // 이미 삭제되었거나 존재하지 않음
      return false;
    }
    final vault = _vaultList![index];
    final vaultType = vault.vaultType;
    if (vaultType == WalletType.singleSignature) {
      final single = vault as SingleSigVaultListItem;
      if (single.linkedMultisigInfo?.isNotEmpty == true) {
        for (var entry in single.linkedMultisigInfo!.entries) {
          final multisig = getVaultById(entry.key) as MultisigVaultListItem;
          multisig.signers[entry.value].unlinkInternalWallet();
          assert(multisig.signers[entry.value].signerBsms != null);
        }
      }
    }
    if (vaultType == WalletType.multiSignature) {
      final multi = vault as MultisigVaultListItem;
      for (var signer in multi.signers) {
        if (signer.innerVaultId != null) {
          final ssv = getVaultById(signer.innerVaultId!);
          if (ssv is SingleSigVaultListItem) {
            ssv.linkedMultisigInfo?.remove(id);
          }
        }
      }
    }
    _vaultList!.removeAt(index);

    await _strategy.deleteWalletData(id, vaultType);
    await _strategy.savePublicVaultList(_vaultList!);

    return true;
  }

  Future<void> deleteWallets() async {
    debugPrint('_vaultList: ${_vaultList?.length}');
    if (_vaultList == null) {
      throw '[wallet_list_manager/deleteWallets]: vaultList is empty';
    }

    for (var vault in _vaultList!) {
      await _strategy.deleteWalletData(vault.id, vault.vaultType);
    }
    _vaultList!.clear();
    await _strategy.savePublicVaultList(_vaultList!);
  }

  Future<bool> updateWallet(int id, String newName, int colorIndex, int iconIndex) async {
    if (_vaultList == null) {
      throw Exception('[wallet_list_manager/updateWallet]: vaultList is empty');
    }

    final index = _vaultList!.indexWhere((item) => item.id == id);
    if (_vaultList![index].vaultType == WalletType.singleSignature) {
      SingleSigVaultListItem singleSigVault = _vaultList![index] as SingleSigVaultListItem;
      Map<int, int>? linkedMultisigInfo = singleSigVault.linkedMultisigInfo;
      // 연결된 MultisigVaultListItem의 signers 객체도 UI 업데이트가 필요
      if (linkedMultisigInfo != null && linkedMultisigInfo.isNotEmpty) {
        for (var entry in linkedMultisigInfo.entries) {
          if (getVaultById(id) != null) {
            MultisigVaultListItem msv = getVaultById(entry.key) as MultisigVaultListItem;
            msv.signers[entry.value].name = newName;
            msv.signers[entry.value].colorIndex = colorIndex;
            msv.signers[entry.value].iconIndex = iconIndex;
          }
        }
      }

      singleSigVault.name = newName;
      singleSigVault.colorIndex = colorIndex;
      singleSigVault.iconIndex = iconIndex;
    } else if (_vaultList![index].vaultType == WalletType.multiSignature) {
      MultisigVaultListItem ssv = _vaultList![index] as MultisigVaultListItem;
      ssv.name = newName;
      ssv.colorIndex = colorIndex;
      ssv.iconIndex = iconIndex;
    } else {
      throw '[wallet_list_manager/updateWallet]: _vaultList[$index] has wrong type: ${_vaultList![index].vaultType}';
    }

    await _strategy.savePublicVaultList(_vaultList!);
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
    var wallet = getVaultById(walletId);
    assert(wallet != null);
    (wallet as MultisigVaultListItem).signers[signerIndex].memo = newMemo;

    await _strategy.savePublicVaultList(_vaultList!);
    return wallet;
  }

  Future<MultisigVaultListItem> updateExternalSignerSource(
    int walletId,
    int signerIndex,
    HardwareWalletType newSignerSource,
  ) async {
    var wallet = getVaultById(walletId);
    assert(wallet != null);
    (wallet as MultisigVaultListItem).signers[signerIndex].signerSource = newSignerSource;

    await _strategy.savePublicVaultList(_vaultList!);
    return wallet;
  }

  Future<void> resetAll() async {
    if (_vaultList != null && _vaultList!.isNotEmpty) {
      try {
        await _secureZoneRepository.deleteKeys(
          aliasList:
              _vaultList!
                  .map((e) {
                    if (e.vaultType == WalletType.multiSignature) return null;
                    return WalletStorageKeys.walletKey(e.id, WalletType.singleSignature);
                  })
                  .whereType<String>()
                  .toList(),
        );
      } on PlatformException catch (e) {
        Logger.error('--> ❌ SZR deleteAll 실패 ${e.toString()} ');
      }
    }

    _vaultList?.clear();

    try {
      await _storageService.deleteAll();
    } on PlatformException catch (e) {
      Logger.error('--> ❌ FSS deleteAll 실패 ${e.toString()} ');
    }
    await _removePublicInfo();
    await _sharedPrefs.deleteSharedPrefsWithKey(nextIdField);
  }

  Future<void> updateIsSigningOnlyMode(bool isSigningOnlyMode) async {
    if (_isSigningOnlyMode == isSigningOnlyMode) return;
    if (!isSigningOnlyMode) {
      await _changeToSecureStorageMode();
      _strategy = SecureStorageStrategy();
    } else {
      await resetAll();
      _strategy = SigningOnlyStrategy();
    }
    _isSigningOnlyMode = isSigningOnlyMode;
  }

  Future<void> _changeToSecureStorageMode() async {
    assert(_isSigningOnlyMode);
    if (_vaultList == null || _vaultList!.isEmpty) {
      return;
    }

    final secureStrategy = SecureStorageStrategy();
    for (final vault in _vaultList!) {
      if (vault is MultisigVaultListItem) {
        await secureStrategy.persistMultisigAdd(id: vault.id, item: vault);
        continue;
      }

      final singleSigWallet = vault as SingleSigVaultListItem;
      final Seed seed = await getSeedInSigningOnlyMode(vault.id);
      await secureStrategy.persistSinglesigAdd(
        id: vault.id,
        secret: seed.mnemonic,
        passphrase: seed.passphrase.isEmpty ? null : seed.passphrase,
        item: singleSigWallet,
      );
    }

    await secureStrategy.savePublicVaultList(_vaultList!);
  }

  Future<void> updateSingleSigAccountVault(int id, int newAccountIndex, {Uint8List? inputPassphrase}) async {
    if (_vaultList == null) throw Exception('vaultList is empty');

    final index = _vaultList!.indexWhere((item) => item.id == id);
    if (index == -1) throw Exception('Vault not found');

    final existingVault = _vaultList![index];
    if (existingVault is! SingleSigVaultListItem) {
      throw ArgumentError(
        'Only SingleSigVaultListItem is supported for account update. Vault type is ${existingVault.vaultType}',
      );
    }

    final currentCoconutVault = existingVault.coconutVault as SingleSignatureVault;

    final parsed = await _decryptSecret(id);
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

    _vaultList![index] = updatedItem;

    await _strategy.updateSinglesigPrivacy(id, updatedItem as SingleSigVaultListItem);
    await _strategy.savePublicVaultList(_vaultList!);
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
