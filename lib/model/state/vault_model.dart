import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item_factory.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item_factory.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/model/state/multisig_creation_model.dart';
import 'package:coconut_vault/services/shared_preferences_keys.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:flutter/foundation.dart';
import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/services/isolate_service.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/vibration_util.dart';

import '../../services/realm_service.dart';
import '../../services/secure_storage_service.dart';

// ignore: constant_identifier_names
const String VAULT_LIST = "VAULT_LIST";

class VaultModel extends ChangeNotifier {
  AppModel _appModel;
  final MultisigCreationModel _multisigCreationModel;

  late final SecureStorageService _storageService;
  late final RealmService _realmService;

  // 비동기 작업 Isolate
  IsolateHandler<void, List<VaultListItemBase>>? _vaultListIsolateHandler;
  IsolateHandler<Map<String, dynamic>, List<SinglesigVaultListItem>>?
      _addVaultIsolateHandler;
  IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>?
      _addMultisigVaultIsolateHandler;
  IsolateHandler<void, int>? _getSignerIndexIsolateHandler;
  IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>?
      _importMultisigVaultIsolateHandler;

  VaultModel(this._appModel, this._multisigCreationModel) {
    _storageService = SecureStorageService();
    _realmService = RealmService();
    // loadVaultList();
    //_initializeServicesAndHandler();
  }

  /// [_appModel]의 변동사항 업데이트
  void updateAppModel(AppModel appModel) {
    _appModel = appModel;
  }

  // Vault list
  List<VaultListItemBase> _vaultList = [];
  List<VaultListItemBase> get vaultList => _vaultList;
  // 리스트 로딩중 여부 (indicator 표시 및 중복 방지)
  bool _isVaultListLoading = false;
  bool get isVaultListLoading => _isVaultListLoading;
  // 리스트 로딩 완료 여부 (로딩작업 완료 후 바로 추가하기 표시)
  bool _isLoadVaultList = false;
  bool get isLoadVaultList => _isLoadVaultList;
  // double _vaultListLoadingProgress = 0.0;
  // double get vaultListLoadingProgress => _vaultListLoadingProgress;
  // static int itemSize = 0;
  bool _vaultInitialized = false;
  bool get vaultInitialized => _vaultInitialized;

  // TODO: 다중서명 구분값, 추후 라이브러리 연동 때 변경될 수 있음
  bool _isMultiSig = false;
  bool get isMultiSig => _isMultiSig;
  void testChangeMultiSig(bool value) {
    _isMultiSig = value;
    notifyListeners();
  }

  // addVault
  bool _isAddVaultCompleted = false;
  bool get isAddVaultCompleted => _isAddVaultCompleted;

  // 지갑 import 중에 입력한 니모닉
  String? _importingSecret;
  String? get importingSecret => _importingSecret;
  String? _importingPassphrase = '';
  String? get importingPassphrase => _importingPassphrase;

  String? _waitingForSignaturePsbtBase64;
  String? get waitingForSignaturePsbtBase64 => _waitingForSignaturePsbtBase64;

  String? signedRawTx;

  // lock 진입시 초기화
  void lockClear() {
    _importingSecret = null;
    _importingPassphrase = '';
    _waitingForSignaturePsbtBase64 = null;
    signedRawTx = null;
    _vaultList.clear();
    _vaultInitialized = false;
  }

  /// pin or biometric 인증 실패후 지갑 초기화
  Future<void> resetVault() async {
    await _storageService.deleteAll();
    _realmService.deleteAll();
    _importingSecret = null;
    _importingPassphrase = '';
    _waitingForSignaturePsbtBase64 = null;
    signedRawTx = null;
    _vaultList.clear();
    _vaultInitialized = false;
    await _appModel.resetPassword();
    notifyListeners();
  }

  // Returns a copy of the list of vault list.
  List<VaultListItemBase> getVaults() {
    if (_vaultList.isEmpty) {
      return [];
    }

    return List.from(_vaultList);
  }

  VaultListItemBase getVaultById(int id) {
    return _vaultList.firstWhere((element) => element.id == id);
  }

  VaultListItemBase getVaultByName(String name) {
    return _vaultList.firstWhere((element) => element.name == name);
  }

  List<MultisigVaultListItem> getMultisigVaults() {
    return _vaultList.whereType<MultisigVaultListItem>().toList();
  }

  SinglesigVaultListItem updateMultisigWithImportedKey(
      SinglesigVaultListItem singlesigVaultItem) {
    SinglesigVaultListItem ssv = singlesigVaultItem;

    /// 니모닉 문구를 통해 볼트를 추가했을 때, 가지고 있는 다중서명지갑에서 이 볼트를 키로 사용하고 있으면 정보를 변경합니다.
    for (int i = 0; i < _vaultList.length; i++) {
      VaultListItemBase vault = _vaultList[i];
      // 싱글 시그는 스킵
      if (vault.vaultType == VaultType.singleSignature) continue;

      List<MultisigSigner> signers = (vault as MultisigVaultListItem).signers;
      // 멀티 시그만 판단
      for (int j = 0; j < signers.length; j++) {
        String signerMfp = signers[j].keyStore.masterFingerprint;
        String importedMfp = (ssv.coconutVault as SingleSignatureVault)
            .keyStore
            .masterFingerprint;

        if (signerMfp == importedMfp) {
          // 다중 서명 지갑에서 signer로 사용되고 있는 mfp와 새로 추가된 볼트의 mfp가 같으면 정보를 변경
          final signer = (_vaultList[i] as MultisigVaultListItem).signers[j];
          signer
            ..innerVaultId = ssv.id
            ..name = ssv.name
            ..iconIndex = ssv.iconIndex
            ..colorIndex = ssv.colorIndex
            ..memo = '';
          if (ssv.linkedMultisigInfo == null) {
            ssv.linkedMultisigInfo = {vault.id: j};
          } else {
            ssv.linkedMultisigInfo!.addAll({i + 1: j});
          }
        }
      }
    }
    return ssv;
  }

  Future<void> addVault(Map<String, dynamic> vaultData) async {
    setAddVaultCompleted(false);
    if (_addVaultIsolateHandler == null) {
      _addVaultIsolateHandler =
          IsolateHandler<Map<String, dynamic>, List<SinglesigVaultListItem>>(
              addVaultIsolate);
      await _addVaultIsolateHandler!
          .initialize(initialType: InitializeType.addVault);
    }

    List<SinglesigVaultListItem> vaultListResult =
        await _addVaultIsolateHandler!.runAddVault(vaultData);
    vaultListResult.first =
        updateMultisigWithImportedKey(vaultListResult.first);

    if (_addVaultIsolateHandler != null) {
      _addVaultIsolateHandler!.dispose();
      _addVaultIsolateHandler = null;
    }

    _vaultList.addAll(vaultListResult);
    setAddVaultCompleted(true);
    await updateVaultInStorage();
    notifyListeners();
    stopImporting();
    // vibrateLight();
  }

  Future<void> addMultisigVaultAsync(
      int nextId, String name, int color, int icon) async {
    // _setAddVaultCompleted(false);

    // final signers = _multisigCreationModel.signers!;
    // final requiredSignatureCount =
    //     _multisigCreationModel.requiredSignatureCount!;
    // var newMultisigVault = await MultisigVaultListItemFactory().create(
    //     nextId: nextId,
    //     name: name,
    //     colorIndex: color,
    //     iconIndex: icon,
    //     secrets: {
    //       'signers': signers,
    //       'requiredSignatureCount': requiredSignatureCount,
    //     });
    setAddVaultCompleted(false);
    final signers = _multisigCreationModel.signers!;
    final requiredSignatureCount =
        _multisigCreationModel.requiredSignatureCount!;
    Map<String, dynamic> data = {
      'nextId': nextId,
      'name': name,
      'colorIndex': color,
      'iconIndex': icon,
      'secrets': {
        'signers': jsonEncode(signers.map((item) => item.toJson()).toList()),
        'requiredSignatureCount': requiredSignatureCount,
      }
    };

    if (_addMultisigVaultIsolateHandler == null) {
      _addMultisigVaultIsolateHandler =
          IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>(
              addMultisigVaultIsolate);
      await _addMultisigVaultIsolateHandler!
          .initialize(initialType: InitializeType.addMultisigVault);
    }

    MultisigVaultListItem newMultisigVault =
        await _addMultisigVaultIsolateHandler!.run(data);

    if (_addMultisigVaultIsolateHandler != null) {
      _addMultisigVaultIsolateHandler!.dispose();
      _addMultisigVaultIsolateHandler = null;
    }

    // for SinglesigVaultListItem multsig key map update
    updateLinkedMultisigInfo(signers, nextId);

    _vaultList.add(newMultisigVault);
    setAddVaultCompleted(true);
    await updateVaultInStorage();
    notifyListeners();
    _multisigCreationModel.reset();
  }

  /// 멀티시그 지갑이 추가될 때 (생성 또는 복사) 사용된 키들의 linkedMultisigInfo를 업데이트 합니다.
  void updateLinkedMultisigInfo(
    List<MultisigSigner> signers,
    int newVaultId,
  ) {
// for SinglesigVaultListItem multsig key map update
    for (int i = 0; i < signers.length; i++) {
      var signer = signers[i];
      if (signers[i].innerVaultId == null) continue;
      SinglesigVaultListItem ssv =
          getVaultById(signer.innerVaultId!) as SinglesigVaultListItem;

      var keyMap = {newVaultId: i};
      if (ssv.linkedMultisigInfo != null) {
        ssv.linkedMultisigInfo!.addAll(keyMap);
      } else {
        ssv.linkedMultisigInfo = keyMap;
      }
    }
  }

  Future<void> importMultisigVaultAsync(
      String name, int color, int icon, String coordinatorBsms) async {
    setAddVaultCompleted(false);
    final nextId = SharedPrefsService().getInt('nextId') ?? 1;

    Map<String, dynamic> data = {
      'nextId': nextId,
      'name': name,
      'colorIndex': color,
      'iconIndex': icon,
      'secrets': {
        'bsms': coordinatorBsms,
        'vaultList':
            jsonEncode(_vaultList.map((item) => item.toJson()).toList()),
      }
    };
    if (_importMultisigVaultIsolateHandler == null) {
      _importMultisigVaultIsolateHandler =
          IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>(
              importMultisigVaultIsolate);
      await _importMultisigVaultIsolateHandler!
          .initialize(initialType: InitializeType.importMultisigVault);
    }

    // isolate 내부에서 멀티시그 지갑 signer들의 정보 입력 (MultisigKey,MultisigIndex), innerVault == null이면 외부지갑
    MultisigVaultListItem newMultisigVault =
        await _importMultisigVaultIsolateHandler!.run(data);

    // for SinglesigVaultListItem multsig key map update
    updateLinkedMultisigInfo(newMultisigVault.signers, nextId);

    _vaultList.add(newMultisigVault);

    _importMultisigVaultIsolateHandler!.dispose();
    _importMultisigVaultIsolateHandler = null;

    SharedPrefsService().setInt('nextId', nextId + 1);
    setAddVaultCompleted(true);
    await updateVaultInStorage();
    notifyListeners();
  }

  Future<int> getSignerIndexAsync(MultisignatureVault multisigVault,
      SinglesigVaultListItem singlesigVaultListItem) async {
    Map<String, dynamic> data = {
      'multisigVault': multisigVault.toJson(),
      'singlesigVault': singlesigVaultListItem.toJson(),
    };
    if (_getSignerIndexIsolateHandler == null) {
      _getSignerIndexIsolateHandler =
          IsolateHandler<Map<String, dynamic>, int>(getSignerIndexIsolate);
      await _getSignerIndexIsolateHandler!
          .initialize(initialType: InitializeType.getSignerIndex);
    }

    final signerIndex = await _getSignerIndexIsolateHandler!.run(data);

    if (_getSignerIndexIsolateHandler != null) {
      _getSignerIndexIsolateHandler!.dispose();
      _getSignerIndexIsolateHandler = null;
    }

    return signerIndex;
  }

  /// addMultisigKey, addMultisigIndex -> 다중 지갑이 추가될 때 일반 지갑의 multisigKey 업데이트
  /// removeMultisigKey -> 다중 지갑이 삭제될 때 일반 지갑의 multisigKey 삭제
  /// signerIndex -> 일반 지갑이 변경될 때 다중 지갑의 signer 업데이트
  Future<void> updateVault(
      int id, String newName, int colorIndex, int iconIndex) async {
    // _vaultList에서 name이 'name'인 항목을 찾아서 그 항목의 name을 newName으로 변경한다.
    final index = _vaultList.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('updateVaultName: no vault id is "$id"');
    }

    if (_vaultList[index].vaultType == VaultType.singleSignature) {
      SinglesigVaultListItem ssv = _vaultList[index] as SinglesigVaultListItem;
      Map<int, int>? linkedMultisigInfo = ssv.linkedMultisigInfo;
      // 연결된 MultisigVaultListItem의 signers 객체도 UI 업데이트가 필요
      if (linkedMultisigInfo != null && linkedMultisigInfo.isNotEmpty) {
        for (var entry in linkedMultisigInfo.entries) {
          MultisigVaultListItem msv =
              getVaultById(entry.key) as MultisigVaultListItem;
          msv.signers[entry.value].name = newName;
          msv.signers[entry.value].colorIndex = colorIndex;
          msv.signers[entry.value].iconIndex = iconIndex;
        }
      }

      _vaultList[index] = SinglesigVaultListItem(
          id: ssv.id,
          name: newName,
          colorIndex: colorIndex,
          iconIndex: iconIndex,
          secret: ssv.secret,
          passphrase: ssv.passphrase,
          linkedMultisigInfo: ssv.linkedMultisigInfo);
    } else if (_vaultList[index].vaultType == VaultType.multiSignature) {
      MultisigVaultListItem ssv = _vaultList[index] as MultisigVaultListItem;

      _vaultList[index] = MultisigVaultListItem(
          id: ssv.id,
          name: newName,
          colorIndex: colorIndex,
          iconIndex: iconIndex,
          signers: ssv.signers,
          requiredSignatureCount: ssv.requiredSignatureCount,
          coordinatorBsms: ssv.coordinatorBsms);
    } else {
      throw "[vault_model/updateVault] _vaultList[$index] has wrong type: ${_vaultList[index].vaultType}";
    }

    // 해당 항목의 name을 newName으로 변경
    await updateVaultInStorage();
    notifyListeners();
  }

  /// 다중서명 지갑의 [singerIndex]번째 키로 사용한 외부 지갑의 메모를 업데이트
  Future updateMemo(int id, int signerIndex, String? newMemo) async {
    final i = _vaultList.indexWhere((item) => item.id == id);
    assert(i != -1 && _vaultList[i].vaultType == VaultType.multiSignature);
    assert((_vaultList[i] as MultisigVaultListItem)
            .signers[signerIndex]
            .innerVaultId ==
        null);

    (_vaultList[i] as MultisigVaultListItem).signers[signerIndex].memo =
        newMemo;

    await updateVaultInStorage();
  }

  /// SiglesigVaultListItem의 seed 중복 여부 확인
  bool isSeedDuplicated(String secret, String passphrase) {
    final vaultIndex = _vaultList.indexWhere((element) {
      if (element is SinglesigVaultListItem) {
        return element.secret == secret && element.passphrase == passphrase;
      }

      return false;
    });

    return vaultIndex != -1;
  }

  /// MultisigVaultListItem의 coordinatorBsms 중복 여부 확인
  bool isMultisigVaultDuplicated(String coordinatorBsms) {
    final vaultIndex = _vaultList.indexWhere((element) =>
        (element is MultisigVaultListItem &&
            element.coordinatorBsms == coordinatorBsms));
    print(">>> vaultIndex: $vaultIndex");
    return vaultIndex != -1;
  }

  bool isNameDuplicated(String name) {
    final vaultIndex = _vaultList.indexWhere((element) => element.name == name);

    return vaultIndex != -1;
  }

  Future<void> deleteVault(int id, {isMultisig = false}) async {
    final index = _vaultList.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('deleteVault: no vault id is "$id"');
    }

    if (isMultisig) {
      final multi = getVaultById(id) as MultisigVaultListItem;
      for (var signer in multi.signers) {
        if (signer.innerVaultId != null) {
          SinglesigVaultListItem ssv =
              getVaultById(signer.innerVaultId!) as SinglesigVaultListItem;
          ssv.linkedMultisigInfo!.remove(id);
        }
      }
    }

    _vaultList.removeAt(index);

    await updateVaultInStorage();
    notifyListeners();
  }

  Future<void> loadVaultList() async {
    if (_isVaultListLoading) return;

    setVaultListLoading(true);
    try {
      if (_vaultListIsolateHandler == null) {
        _vaultListIsolateHandler =
            IsolateHandler<void, List<VaultListItemBase>>(loadVaultListIsolate);
        await _vaultListIsolateHandler!.initialize();
      }

      if (_vaultListIsolateHandler!.isInitialized) {
        _vaultList = await _vaultListIsolateHandler!.run(null);
        vibrateLight();
      } else {
        throw Exception("IsolateHandler not initialized");
      }

      _vaultInitialized = true;
    } catch (e) {
      Logger.log('[loadVaultList] Exception : ${e.toString()}');
    } finally {
      if (_vaultListIsolateHandler != null &&
          _vaultListIsolateHandler!.isInitialized) {
        try {
          _vaultListIsolateHandler!.dispose();
          _vaultListIsolateHandler = null;
        } catch (e) {
          Logger.log('[loadVaultList] Dispose Exception: ${e.toString()}');
        }
      }
      _appModel.saveNotEmptyVaultList(_vaultList.isNotEmpty);
      setVaultListLoading(false);
    }
  }

  static Future<List<VaultListItemBase>> loadVaultListIsolate(
      void _, void Function(dynamic)? setVaultListLoadingProgress) async {
    BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
    List<VaultListItemBase> vaultList = [];
    String? jsonArrayString;
    final SecureStorageService storageService = SecureStorageService();
    final RealmService realmService = RealmService();
    try {
      jsonArrayString = await storageService.read(key: VAULT_LIST);
    } catch (_) {
      jsonArrayString = realmService.getValue(key: VAULT_LIST);
    }

    printLongString('jsonArrayString--> $jsonArrayString');

    if (jsonArrayString != null) {
      const String vaultTypeField = 'vaultType';
      List<dynamic> jsonList = jsonDecode(jsonArrayString);
      for (int i = 0; i < jsonList.length; i++) {
        if (jsonList[i][vaultTypeField] == VaultType.singleSignature.name) {
          vaultList
              .add(SinglesigVaultListItemFactory().createFromJson(jsonList[i]));
        } else if (jsonList[i][vaultTypeField] ==
            VaultType.multiSignature.name) {
          vaultList
              .add(MultisigVaultListItemFactory().createFromJson(jsonList[i]));
        } else {
          // coconut_vault 1.0.1 -> 2.0.0 업데이트 되면서 vaultType이 추가됨
          jsonList[i][vaultTypeField] = VaultType.singleSignature.name;
          vaultList
              .add(SinglesigVaultListItemFactory().createFromJson(jsonList[i]));
        }
      }
    }

    return vaultList;
  }

  Future<void> updateVaultInStorage() async {
    final jsonString =
        jsonEncode(_vaultList.map((item) => item.toJson()).toList());
    printLongString('updateVaultInStorage ---> $jsonString');
    await _storageService.write(key: VAULT_LIST, value: jsonString);
    _realmService.updateKeyValue(key: VAULT_LIST, value: jsonString);

    await SharedPrefsService()
        .setBool(SharedPrefsKeys.isNotEmptyVaultList, _vaultList.isNotEmpty);
    _appModel.saveNotEmptyVaultList(_vaultList.isNotEmpty);
  }

  void startImporting(String secret, String passphrase) {
    _importingSecret = secret;
    _importingPassphrase = passphrase;
  }

  void stopImporting() {
    _importingSecret = null;
  }

  void setWaitingForSignaturePsbtBase64(String psbt) {
    _waitingForSignaturePsbtBase64 = psbt;
  }

  void clearWaitingForSignaturePsbt() {
    _waitingForSignaturePsbtBase64 = null;
  }

  void setVaultListLoading(bool value) {
    _isVaultListLoading = value;
    _isLoadVaultList = !value;
    notifyListeners();
  }

  void setAddVaultCompleted(bool value) {
    _isAddVaultCompleted = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_vaultListIsolateHandler != null) {
      _vaultListIsolateHandler!.dispose();
      _vaultListIsolateHandler = null;
    }
    if (_addVaultIsolateHandler != null) {
      _addVaultIsolateHandler!.dispose();
      _addVaultIsolateHandler = null;
    }
    if (_addMultisigVaultIsolateHandler != null) {
      _addMultisigVaultIsolateHandler!.dispose();
      _addMultisigVaultIsolateHandler = null;
    }
    if (_getSignerIndexIsolateHandler != null) {
      _getSignerIndexIsolateHandler!.dispose();
      _getSignerIndexIsolateHandler = null;
    }
    if (_importMultisigVaultIsolateHandler != null) {
      _importMultisigVaultIsolateHandler!.dispose();
      _importMultisigVaultIsolateHandler = null;
    }
    super.dispose();
  }
}
