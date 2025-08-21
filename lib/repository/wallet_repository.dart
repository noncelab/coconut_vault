import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:coconut_vault/utils/logger.dart';

/// 지갑의 public 정보는 shared prefs, 비밀 정보는 secure storage에 저장하는 역할을 하는 클래스입니다.
class WalletRepository {
  static String nextIdField = 'nextId';
  static String vaultTypeField = VaultListItemBase.vaultTypeField;

  final SecureStorageRepository _storageService = SecureStorageRepository();
  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();

  static final WalletRepository _instance = WalletRepository._internal();
  factory WalletRepository() => _instance;

  List<VaultListItemBase>? _vaultList;
  get vaultList => _vaultList;

  Completer<void>? _walletLoadCancelToken;

  WalletRepository._internal();

  Future<List<dynamic>?> loadVaultListJsonArrayString() async {
    String? jsonArrayString;

    jsonArrayString = _sharedPrefs.getString(SharedPrefsKeys.kVaultListField);

    //printLongString('--> $jsonArrayString');
    if (jsonArrayString.isEmpty || jsonArrayString == '[]') {
      _vaultList = [];
      return null;
    }

    return jsonDecode(jsonArrayString);
  }

  Future<void> loadAndEmitEachWallet(
      List<dynamic> jsonList, Function(VaultListItemBase wallet) emitOneItem) async {
    _walletLoadCancelToken = Completer<void>();

    List<VaultListItemBase> vaultList = [];

    var initIsolateHandler =
        IsolateHandler<Map<String, dynamic>, VaultListItemBase>(WalletIsolates.initializeWallet);
    await initIsolateHandler.initialize(initialType: InitializeType.initializeWallet);

    for (int i = 0; i < jsonList.length; i++) {
      VaultListItemBase item = await initIsolateHandler.run(jsonList[i]);

      if (_walletLoadCancelToken?.isCompleted == true) {
        initIsolateHandler.dispose();
        return;
      }

      emitOneItem(item);
      vaultList.add(item);
    }

    initIsolateHandler.dispose();

    _vaultList = vaultList;
  }

  Future<SingleSigVaultListItem> addSinglesigWallet(SingleSigWalletCreateDto wallet) async {
    if (_vaultList == null) {
      throw "[wallet_list_manager/addSinglesigWallet()] _vaultList is null. Load first.";
    }

    final int nextId = _getNextWalletId();
    wallet.id = nextId;
    final Map<String, dynamic> vaultData = wallet.toJson();

    var addVaultIsolateHandler =
        IsolateHandler<Map<String, dynamic>, List<SingleSigVaultListItem>>(WalletIsolates.addVault);
    await addVaultIsolateHandler.initialize(initialType: InitializeType.addVault);
    List<SingleSigVaultListItem> vaultListResult =
        await addVaultIsolateHandler.runAddVault(vaultData);
    addVaultIsolateHandler.dispose();

    _linkNewSinglesigVaultAndMultisigVaults(vaultListResult.first);
    await _saveSingleSigSecureData(
        nextId, wallet.mnemonic!, wallet.passphrase != null && wallet.passphrase!.isNotEmpty);

    _vaultList!.add(vaultListResult[0]);
    try {
      await _savePublicInfo();
    } catch (error) {
      _deleteSingleSigSecureData(nextId);
      rethrow;
    }
    _recordNextWalletId();
    return vaultListResult[0];
  }

  String _createWalletKeyString(int id, WalletType type) {
    return hashString("${id.toString()} - ${type.name}");
  }

  String _createPassphraseEnabledKeyString(String walletKeyString) {
    return hashString("$walletKeyString - passphraseEnabled");
  }

  Future<void> _savePublicInfo() async {
    if (_vaultList == null) return;

    final jsonString = jsonEncode(_vaultList!.map((item) => item.toJson()).toList());

    //printLongString("--> 저장: $jsonString");
    await _sharedPrefs.setString(SharedPrefsKeys.kVaultListField, jsonString);
  }

  Future<void> _removePublicInfo() async {
    await _sharedPrefs.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultListField);
  }

  void _linkNewSinglesigVaultAndMultisigVaults(SingleSigVaultListItem singlesigItem) {
    outerLoop:
    for (int i = 0; i < _vaultList!.length; i++) {
      VaultListItemBase vault = _vaultList![i];
      // 싱글 시그는 스킵
      if (vault.vaultType == WalletType.singleSignature) continue;

      List<MultisigSigner> signers = (vault as MultisigVaultListItem).signers;
      // 멀티 시그만 판단
      String importedMfp =
          (singlesigItem.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
      for (int j = 0; j < signers.length; j++) {
        String signerMfp = signers[j].keyStore.masterFingerprint;

        if (signerMfp == importedMfp) {
          // 다중 서명 지갑에서 signer로 사용되고 있는 mfp와 새로 추가된 볼트의 mfp가 같으면 정보를 변경
          // 멀티시그 지갑 정보 변경
          final signer = (_vaultList![i] as MultisigVaultListItem).signers[j];
          signer
            ..innerVaultId = singlesigItem.id
            ..name = singlesigItem.name
            ..iconIndex = singlesigItem.iconIndex
            ..colorIndex = singlesigItem.colorIndex
            ..memo = null;

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

  Future<MultisigVaultListItem> addMultisigWallet(MultisigWallet wallet) async {
    if (_vaultList == null) {
      throw "[wallet_list_manager/addMultisigWallet()] _vaultList is null. Load first.";
    }

    final int nextId = _getNextWalletId();
    wallet.id = nextId;
    final Map<String, dynamic> data = wallet.toJson();

    var addMultisigVaultIsolateHandler =
        IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>(
            WalletIsolates.addMultisigVault);
    await addMultisigVaultIsolateHandler.initialize(initialType: InitializeType.addMultisigVault);
    MultisigVaultListItem newMultisigVault = await addMultisigVaultIsolateHandler.run(data);
    addMultisigVaultIsolateHandler.dispose();

    print('newMultisigVault: $newMultisigVault');

    // for SinglesigVaultListItem multsig key map update
    updateLinkedMultisigInfo(wallet.signers!, nextId);

    _vaultList!.add(newMultisigVault);
    await _savePublicInfo();
    _recordNextWalletId();
    return newMultisigVault;
  }

  /// 멀티시그 지갑이 추가될 때 (생성 또는 복사) 사용된 싱글시그 지갑들의 linkedMultisigInfo를 업데이트 합니다.
  void updateLinkedMultisigInfo(
    List<MultisigSigner> signers,
    int newWalletId,
  ) {
    // for SinglesigVaultListItem multsig key map update
    for (int i = 0; i < signers.length; i++) {
      var signer = signers[i];
      if (signers[i].innerVaultId == null) continue;
      SingleSigVaultListItem ssv = _vaultList!
          .firstWhere((element) => element.id == signer.innerVaultId!) as SingleSigVaultListItem;

      var keyMap = {newWalletId: i};
      if (ssv.linkedMultisigInfo != null) {
        ssv.linkedMultisigInfo!.addAll(keyMap);
      } else {
        ssv.linkedMultisigInfo = keyMap;
      }
    }
  }

  int _getNextWalletId() {
    return _sharedPrefs.getInt(nextIdField) ?? 1;
  }

  void _recordNextWalletId() {
    final int nextId = _getNextWalletId();
    _sharedPrefs.setInt(nextIdField, nextId + 1);
  }

  Future<String> getSecret(int id) async {
    var secretString =
        await _storageService.read(key: _createWalletKeyString(id, WalletType.singleSignature));
    return secretString!;
  }

  Future<void> _saveSingleSigSecureData(
      int walletId, String secretString, bool isPassphraseEnabled) async {
    String keyString = _createWalletKeyString(walletId, WalletType.singleSignature);
    await _storageService.write(key: keyString, value: secretString);

    String passphraseEnabledKeyString = _createPassphraseEnabledKeyString(keyString);
    await _storageService.write(
        key: passphraseEnabledKeyString, value: isPassphraseEnabled ? "true" : "false");
  }

  Future<void> _deleteSingleSigSecureData(int walletId) async {
    String keyString = _createWalletKeyString(walletId, WalletType.singleSignature);
    await _storageService.delete(key: keyString);

    String passphraseEnabledKeyString = _createPassphraseEnabledKeyString(keyString);
    await _storageService.delete(key: passphraseEnabledKeyString);
  }

  Future<bool> hasPassphrase(int walletId) async {
    String keyString = _createWalletKeyString(walletId, WalletType.singleSignature);
    String passphraseEnabledKeyString = _createPassphraseEnabledKeyString(keyString);
    return await _storageService.read(key: passphraseEnabledKeyString) == "true";
  }

  Future<bool> deleteWallet(int id) async {
    if (_vaultList == null) {
      throw '[wallet_list_manager/deleteWallet]: vaultList is empty';
    }

    final index = _vaultList!.indexWhere((item) => item.id == id);
    final vaultType = _vaultList![index].vaultType;

    if (vaultType == WalletType.multiSignature) {
      final multi = getVaultById(id) as MultisigVaultListItem;
      for (var signer in multi.signers) {
        if (signer.innerVaultId != null) {
          SingleSigVaultListItem ssv = getVaultById(signer.innerVaultId!) as SingleSigVaultListItem;
          ssv.linkedMultisigInfo!.remove(id);
        }
      }
    }

    _vaultList!.removeAt(index);

    if (vaultType == WalletType.singleSignature) {
      _deleteSingleSigSecureData(id);
    }
    await _savePublicInfo();

    return true;
  }

  Future<void> deleteWallets() async {
    if (_vaultList == null) {
      throw '[wallet_list_manager/deleteWallets]: vaultList is empty';
    }

    for (var vault in _vaultList!) {
      if (vault.vaultType == WalletType.singleSignature) {
        _deleteSingleSigSecureData(vault.id);
      }
    }
    _vaultList!.clear();
    await _savePublicInfo();
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

    await _savePublicInfo();
    return true;
  }

  VaultListItemBase? getVaultById(int id) {
    return _vaultList?.firstWhere((element) => element.id == id);
  }

  Future<MultisigVaultListItem> updateMemo(int walletId, int signerIndex, String? newMemo) async {
    var wallet = getVaultById(walletId);
    assert(wallet != null);
    (wallet as MultisigVaultListItem).signers[signerIndex].memo = newMemo;

    await _savePublicInfo();
    return wallet;
  }

  Future<void> resetAll() async {
    _vaultList?.clear();

    await UpdatePreparation.clearUpdatePreparationStorage(); // 비밀번호 초기화시 백업파일도 같이 삭제

    await _storageService.deleteAll();
    await _removePublicInfo();
  }

  Future<void> restoreFromBackupData(List<Map<String, dynamic>> backupData) async {
    final List<VaultListItemBase> vaultList = [];
    var initIsolateHandler =
        IsolateHandler<Map<String, dynamic>, VaultListItemBase>(WalletIsolates.initializeWallet);
    await initIsolateHandler.initialize(initialType: InitializeType.initializeWallet);
    for (final data in backupData) {
      VaultListItemBase wallet = await initIsolateHandler.run(data);
      if (data['vaultType'] == WalletType.singleSignature.name) {
        String keyString = _createWalletKeyString(wallet.id, WalletType.singleSignature);
        String passphraseKeyString = _createPassphraseEnabledKeyString(keyString);
        _storageService.write(key: keyString, value: data['secret']);
        _storageService.write(
            key: passphraseKeyString, value: data['hasPassphrase'] ? "true" : "false");
      }
      vaultList.add(wallet);
    }

    _vaultList = vaultList;
    await _savePublicInfo();
    initIsolateHandler.dispose();
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
