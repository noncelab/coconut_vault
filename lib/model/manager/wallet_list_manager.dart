import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/model/manager/multisig_wallet.dart';
import 'package:coconut_vault/model/manager/secret.dart';
import 'package:coconut_vault/model/manager/singlesig_wallet.dart';
import 'package:coconut_vault/services/isolate_service.dart';
import 'package:coconut_vault/services/realm_service.dart';
import 'package:coconut_vault/services/secure_storage_service.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';

/// 지갑의 public 정보는 shared prefs, 비밀 정보는 secure storage에 저장하는 역할을 하는 클래스입니다.
class WalletListManager {
  static String vaultListField = 'VAULT_LIST';
  // static String keyListField = 'keyList';
  static String nextIdField = 'nextId';
  static String vaultTypeField = VaultListItemBase.vaultTypeField;

  final SecureStorageService _storageService = SecureStorageService();
  final RealmService _realmService = RealmService(); // TODO:
  final SharedPrefsService _sharedPrefs = SharedPrefsService();

  static final WalletListManager _instance = WalletListManager._internal();
  factory WalletListManager() => _instance;

  late List<String> _keys;

  List<VaultListItemBase>? _vaultList;
  get vaultList => _vaultList;

  WalletListManager._internal();

  Future<void> init() async {
    // init in main.dart
    //_keys = await getKeys();
  }

  // Future<List<String>> getKeys() async {
  //   String? keys = await _storageService.read(key: keyListField);

  //   if (keys == null) return [];

  //   return jsonDecode(keys);
  // }

  Future<List<dynamic>?> loadVaultListJsonArrayString() async {
    String? jsonArrayString;

    try {
      jsonArrayString = await _storageService.read(key: vaultListField);
    } catch (_) {
      jsonArrayString = _realmService.getValue(key: vaultListField);
    }

    // printLongString('--> $jsonArrayString');
    if (jsonArrayString == null) {
      _vaultList = [];
      return null;
    }

    return jsonDecode(jsonArrayString);
  }

  Future loadAndEmitEachWallet(List<dynamic> jsonList,
      Function(VaultListItemBase wallet) emitOneItem) async {
    List<VaultListItemBase> vaultList = [];

    var initIsolateHandler =
        IsolateHandler<Map<String, dynamic>, VaultListItemBase>(
            initializeWallet);
    await initIsolateHandler.initialize(
        initialType: InitializeType.initializeWallet);

    for (int i = 0; i < jsonList.length; i++) {
      VaultListItemBase item = await initIsolateHandler.run(jsonList[i]);
      emitOneItem(item);
      vaultList.add(item);
    }

    initIsolateHandler.dispose();

    _vaultList = vaultList;
  }

  Future<SinglesigVaultListItem> addSinglesigWallet(
      SinglesigWallet wallet) async {
    if (_vaultList == null) {
      throw "[wallet_list_manager/addSinglesigWallet()] _vaultList is null. Load first.";
    }

    try {
      final int nextId = _getNextWalletId();
      wallet.id = nextId;
      final Map<String, dynamic> vaultData = wallet.toJson();

      var addVaultIsolateHandler =
          IsolateHandler<Map<String, dynamic>, List<SinglesigVaultListItem>>(
              addVaultIsolate);
      await addVaultIsolateHandler.initialize(
          initialType: InitializeType.addVault);
      List<SinglesigVaultListItem> vaultListResult =
          await addVaultIsolateHandler.runAddVault(vaultData);
      addVaultIsolateHandler.dispose();

      _linkNewSinglesigVaultAndMultisigVaults(vaultListResult.first);

      String keyString =
          _createWalletKeyString(nextId, VaultType.singleSignature);
      _storageService.write(
          key: keyString,
          value: jsonEncode(
              Secret(wallet.mnemonic!, wallet.passphrase!).toJson()));

      try {
        savePublicInfo();
      } catch (error) {
        _storageService.delete(key: keyString);
        rethrow;
      }

      _vaultList!.add(vaultListResult[0]);
      _recordNextWalletId();
      return vaultListResult[0];
    } catch (_) {
      rethrow;
    }
  }

  String _createWalletKeyString(int id, VaultType type) {
    return hashString("${id.toString()} - ${type.name}");
  }

  Future savePublicInfo() async {
    if (_vaultList == null) return;

    final jsonString =
        jsonEncode(_vaultList!.map((item) => item.toJson()).toList());
    _sharedPrefs.setString(vaultListField, jsonString);
  }

  void _linkNewSinglesigVaultAndMultisigVaults(
      SinglesigVaultListItem singlesigItem) {
    outerLoop:
    for (int i = 0; i < _vaultList!.length; i++) {
      VaultListItemBase vault = _vaultList![i];
      // 싱글 시그는 스킵
      if (vault.vaultType == VaultType.singleSignature) continue;

      List<MultisigSigner> signers = (vault as MultisigVaultListItem).signers;
      // 멀티 시그만 판단
      String importedMfp = (singlesigItem.coconutVault as SingleSignatureVault)
          .keyStore
          .masterFingerprint;
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
            addMultisigVaultIsolate);
    await addMultisigVaultIsolateHandler.initialize(
        initialType: InitializeType.addMultisigVault);
    MultisigVaultListItem newMultisigVault =
        await addMultisigVaultIsolateHandler.run(data);
    addMultisigVaultIsolateHandler.dispose();

    // for SinglesigVaultListItem multsig key map update
    updateLinkedMultisigInfo(wallet.signers!, nextId);

    savePublicInfo();

    _vaultList!.add(newMultisigVault);
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
      SinglesigVaultListItem ssv = _vaultList!
              .firstWhere((element) => element.id == signer.innerVaultId!)
          as SinglesigVaultListItem;

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

  void _rollbackNextWalletId() {
    final int nextId = _getNextWalletId();
    if (nextId == 1) return;

    _sharedPrefs.setInt(nextIdField, nextId - 1);
  }

  // getWallet(String key)
  // deleteWallet()
  // updateWallet()
  // resetAll()
}
