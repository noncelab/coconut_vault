import 'dart:async';
import 'dart:convert';

import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/services/isolate_service.dart';
import 'package:coconut_vault/services/realm_service.dart';
import 'package:coconut_vault/services/secure_storage_service.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
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

  Future loadAndEmitEachWallet(
      Function(VaultListItemBase? wallet, int length) emitOneItem) async {
    List<VaultListItemBase> vaultList = [];
    String? jsonArrayString;
    int length = 0;
    try {
      jsonArrayString = await _storageService.read(key: vaultListField);
    } catch (_) {
      jsonArrayString = _realmService.getValue(key: vaultListField);
    }

    if (jsonArrayString == null) {
      emitOneItem(null, length);
      return;
    }

    List<dynamic> jsonList = jsonDecode(jsonArrayString);

    length = jsonList.length;

    if (length == 0) {
      emitOneItem(null, length);
      return;
    }

    var initIsolateHandler =
        IsolateHandler<Map<String, dynamic>, VaultListItemBase>(
            initializeWallet);
    await initIsolateHandler.initialize(
        initialType: InitializeType.initializeWallet);

    for (int i = 0; i < jsonList.length; i++) {
      VaultListItemBase item = await initIsolateHandler.run(jsonList[i]);
      emitOneItem(item, length);
      vaultList.add(item);
    }

    initIsolateHandler.dispose();

    _vaultList = vaultList;
  }

  /// 저장소에까지 저장 완료 후 최종 생성 결과를 반환해준다. 그럼 vault_model에서는 리스트에 추가하면 됨
  Future<SinglesigVaultListItem> addSinglesigWallet(
      {required String name,
      required int iconIndex,
      required int colorIndex,
      required String mnemonic,
      required String passphrase}) async {
    final int nextId = _sharedPrefs.getInt('nextId') ?? 1;

    final Map<String, dynamic> vaultData = {
      'id': nextId,
      'name': name,
      'iconIndex': iconIndex,
      'colorIndex': colorIndex,
      'importingSecret': mnemonic,
      'importingPassphrase': passphrase,
    };

    var addVaultIsolateHandler =
        IsolateHandler<Map<String, dynamic>, List<SinglesigVaultListItem>>(
            addVaultIsolate);
    await addVaultIsolateHandler.initialize(
        initialType: InitializeType.addVault);
    List<SinglesigVaultListItem> vaultListResult =
        await addVaultIsolateHandler.runAddVault(vaultData);
    addVaultIsolateHandler.dispose();

    // TODO: linkNewSinglesigVaultAndMultisigVaults(vaultListResult.first);
    // TODO: add to storage
    // secret 정보는 secure storage에 저장
    // ui 요소 local storage에 저장
    // 만약 여기서 실패하면 위 secure storage에 저장했던 것도 rollback 해야 함.

    return vaultListResult[0];
  }

  void _linkNewSinglesigVaultAndMultisigVaults(
      SinglesigVaultListItem singlesigItem) {
    // outerLoop:
    // for (int i = 0; i < _vaultList.length; i++) {
    //   VaultListItemBase vault = _vaultList[i];
    //   // 싱글 시그는 스킵
    //   if (vault.vaultType == VaultType.singleSignature) continue;

    //   List<MultisigSigner> signers = (vault as MultisigVaultListItem).signers;
    //   // 멀티 시그만 판단
    //   String importedMfp =
    //       (singlesigItem.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
    //   for (int j = 0; j < signers.length; j++) {
    //     String signerMfp = signers[j].keyStore.masterFingerprint;

    //     if (signerMfp == importedMfp) {
    //       // 다중 서명 지갑에서 signer로 사용되고 있는 mfp와 새로 추가된 볼트의 mfp가 같으면 정보를 변경
    //       final signer = (_vaultList[i] as MultisigVaultListItem).signers[j];
    //       signer
    //         ..innerVaultId = singlesigItem.id
    //         ..name = singlesigItem.name
    //         ..iconIndex = singlesigItem.iconIndex
    //         ..colorIndex = singlesigItem.colorIndex
    //         ..memo = null;
    //       Map<int, int> linkedMultisigInfo = {vault.id: j};
    //       if (singlesigItem.linkedMultisigInfo == null) {
    //         singlesigItem.linkedMultisigInfo = linkedMultisigInfo;
    //       } else {
    //         singlesigItem.linkedMultisigInfo!.addAll(linkedMultisigInfo);
    //       }
    //       continue outerLoop; // 같은 singlesig가 하나의 multisig 지갑에 2번 이상 signer로 등록될 수 없으므로
    //     }
    //   }
    // }
  }

  /// 저장소에까지 저장 완료 후 최종 생성 결과를 반환해준다. 그럼 vault_model에서는 리스트에 추가하면 됨
  Future addMultisigWallet() async {
    //
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
  // addWallet()
  // deleteWallet()
  // updateWallet()
  // resetAll()
}
