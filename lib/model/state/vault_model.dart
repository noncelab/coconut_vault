import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item_factory.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item_factory.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/model/state/multisig_creation_model.dart';
import 'package:coconut_vault/services/shared_preferences_keys.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
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

  Future<void> addVault(Map<String, dynamic> vaultData) async {
    setAddVaultCompleted(false);
    if (_addVaultIsolateHandler == null) {
      _addVaultIsolateHandler =
          IsolateHandler<Map<String, dynamic>, List<SinglesigVaultListItem>>(
              addVaultIsolate);
      await _addVaultIsolateHandler!
          .initialize(initialType: InitializeType.addVault);
    }

    final vaultListResult =
        await _addVaultIsolateHandler!.runAddVault(vaultData);

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
    if (_multisigCreationModel.signers == null) return;
    setAddVaultCompleted(false);
    final signers = _multisigCreationModel.signers ?? [];
    final requiredSignatureCount =
        _multisigCreationModel.requiredSignatureCount ?? 0;
    Map<String, dynamic> data = {
      'nextId': nextId,
      'name': name,
      'colorIndex': color,
      'iconIndex': icon,
      'secrets': {
        'signers': jsonEncode(signers.map((item) => item.toJson()).toList()),
        'requiredSignatureCount': _multisigCreationModel.requiredSignatureCount,
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

    for (var signer in signers) {
      if (signer.innerVaultId == null) return;
      final id = signer.innerVaultId ?? 0;
      final name = signer.name ?? '';
      final colorIndex = signer.colorIndex ?? 0;
      final iconIndex = signer.iconIndex ?? 0;
      final multiSigIndex = signers.indexOf(signer);
      await updateVault(id, name, colorIndex, iconIndex,
          addMultisigKey: nextId, addMultisigIndex: multiSigIndex);
    }

    try {
      _vaultList.add(newMultisigVault);
    } catch (e) {
      print("[addMultisigVaultAsync Exception] $e");
    }
    setAddVaultCompleted(true);
    await updateVaultInStorage();
    notifyListeners();
    _multisigCreationModel.reset();
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

    MultisigVaultListItem newMultisigVault =
        await _importMultisigVaultIsolateHandler!.run(data);

    if (_importMultisigVaultIsolateHandler != null) {
      _importMultisigVaultIsolateHandler!.dispose();
      _importMultisigVaultIsolateHandler = null;
    }

    try {
      _vaultList.add(newMultisigVault);
    } catch (e) {
      print("[importMultisigVaultAsync Exception] $e");
    }
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
      int id, String newName, int colorIndex, int iconIndex,
      {int? addMultisigKey,
      int? addMultisigIndex,
      String? removeMultisigKey,
      int? signerIndex}) async {
    // _vaultList에서 name이 'name'인 항목을 찾아서 그 항목의 name을 newName으로 변경한다.
    final index = _vaultList.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('updateVaultName: no vault id is "$id"');
    }

    if (_vaultList[index].vaultType == VaultType.singleSignature) {
      SinglesigVaultListItem ssv = _vaultList[index] as SinglesigVaultListItem;
      Map<String, dynamic>? updateMultisigKey = ssv.multisigKey != null
          ? Map<String, dynamic>.from(ssv.multisigKey!)
          : {};
      if (addMultisigKey != null) {
        updateMultisigKey.addAll({'$addMultisigKey': addMultisigIndex});
      }

      if (removeMultisigKey != null) {
        updateMultisigKey.remove(removeMultisigKey);
      }

      _vaultList[index] = SinglesigVaultListItem(
        id: ssv.id,
        name: newName,
        colorIndex: colorIndex,
        iconIndex: iconIndex,
        secret: ssv.secret,
        passphrase: ssv.passphrase,
        multisigKey: updateMultisigKey,
      );
    } else if (_vaultList[index].vaultType == VaultType.multiSignature) {
      MultisigVaultListItem ssv = _vaultList[index] as MultisigVaultListItem;

      if (signerIndex != null) {
        ssv.signers[signerIndex].name = newName;
        ssv.signers[signerIndex].colorIndex = colorIndex;
        ssv.signers[signerIndex].iconIndex = iconIndex;
      }

      _vaultList[index] = MultisigVaultListItem(
          id: ssv.id,
          name: signerIndex != null ? ssv.name : newName,
          colorIndex: signerIndex != null ? ssv.colorIndex : colorIndex,
          iconIndex: signerIndex != null ? ssv.iconIndex : iconIndex,
          signers: ssv.signers,
          requiredSignatureCount: ssv.requiredSignatureCount);
    } else {
      throw "[vault_model/updateVault] _vaultList[$index] has wrong type: ${_vaultList[index].vaultType}";
    }

    // 해당 항목의 name을 newName으로 변경
    await updateVaultInStorage();
    notifyListeners();
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
          final innerVaultId = signer.innerVaultId ?? 0;
          final name = signer.name ?? '';
          final colorIndex = signer.colorIndex ?? 0;
          final iconIndex = signer.iconIndex ?? 0;
          await updateVault(
            innerVaultId,
            name,
            colorIndex,
            iconIndex,
            removeMultisigKey: '$id',
          );
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
      _appModel.saveNotEmptyVaultList(_vaultList.isNotEmpty);
      setVaultListLoading(false);
      if (_vaultListIsolateHandler != null) {
        _vaultListIsolateHandler!.dispose();
        _vaultListIsolateHandler = null;
      }
    }
  }

  Future<List<VaultListItemBase>> loadVaultListIsolate(
      void _, void Function(List<dynamic>)? setVaultListLoadingProgress) async {
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

    if (jsonArrayString != null) {
      List<dynamic> jsonList = jsonDecode(jsonArrayString);
      int totalItems = jsonList.length;
      for (int i = 0; i < totalItems; i++) {
        // TODO: singleSignature, multiSignature 하드코딩 필요 없도록 수정하기
        if (jsonList[i]['vaultType'] == 'singleSignature') {
          vaultList
              .add(SinglesigVaultListItemFactory().createFromJson(jsonList[i]));
        } else if (jsonList[i]['vaultType'] == 'multiSignature') {
          vaultList
              .add(MultisigVaultListItemFactory().createFromJson(jsonList[i]));
        } else {
          throw ArgumentError(
              "[vault_model] wrong vaultType: ${jsonList[i]['vaultType']}");
        }
      }
    }

    return vaultList;
  }

  Future<void> updateVaultInStorage() async {
    final jsonString =
        jsonEncode(_vaultList.map((item) => item.toJson()).toList());
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
