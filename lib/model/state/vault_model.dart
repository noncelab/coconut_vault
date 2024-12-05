import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_import_detail.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/model/manager/multisig_wallet.dart';
import 'package:coconut_vault/model/manager/secret.dart';
import 'package:coconut_vault/model/manager/singlesig_wallet.dart';
import 'package:coconut_vault/model/manager/wallet_list_manager.dart';
import 'package:coconut_vault/model/state/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/model/state/multisig_creation_model.dart';
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
  late final WalletListManager _walletManager;

  // 비동기 작업 Isolate
  // IsolateHandler<void, List<VaultListItemBase>>? _vaultListIsolateHandler;
  // IsolateHandler<Map<String, dynamic>, List<SinglesigVaultListItem>>?
  //     _addVaultIsolateHandler;
  IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>?
      _addMultisigVaultIsolateHandler;
  IsolateHandler<void, int>? _getSignerIndexIsolateHandler;
  IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>?
      _importMultisigVaultIsolateHandler;

  VaultModel(this._appModel, this._multisigCreationModel) {
    _storageService = SecureStorageService();
    _realmService = RealmService();
    _walletManager = WalletListManager();
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
  // 지갑 Skeleton 표시 개수
  int _vaultSkeletonLength = 0;
  int get vaultSkeletonLength => _vaultSkeletonLength;
  // 리스트 로딩중 여부 (indicator 표시 및 중복 방지)
  bool _isVaultListLoading = false;
  bool get isVaultListLoading => _isVaultListLoading;
  // 리스트 로딩 완료 여부 (로딩작업 완료 후 바로 추가하기 표시)
  bool _isLoadVaultList = false;
  bool get isLoadVaultList => _isLoadVaultList;
  // 지갑 추가, 지갑 삭제, 서명완료 후 불필요하게 loadVaultList() 호출되는 것을 막음
  bool _vaultInitialized = false;
  bool get vaultInitialized => _vaultInitialized;

  // addVault
  bool _isAddVaultCompleted = false;
  bool get isAddVaultCompleted => _isAddVaultCompleted;

  // 리스트에 추가되는 애니메이션이 동작해야하면 true, 아니면 false를 담습니다.
  List<bool> _animatedVaultFlags = [];
  List<bool> get animatedVaultFlags => _animatedVaultFlags;

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
    _vaultList.clear();
    _animatedVaultFlags = [];
    _importingSecret = null;
    _importingPassphrase = '';
    _waitingForSignaturePsbtBase64 = null;
    signedRawTx = null;
    _vaultInitialized = false;
    await _walletManager.resetAll();
    await _appModel.resetPassword();
    notifyListeners();
  }

  // Returns a copy of the list of vault list.
  List<VaultListItemBase> getVaults() {
    if (_vaultList.isEmpty) {
      _animatedVaultFlags = [];

      return [];
    }

    if (_animatedVaultFlags.isNotEmpty && _animatedVaultFlags.last) {
      setAnimatedVaultFlags(index: _vaultList.length);
    } else {
      _animatedVaultFlags = List.filled(_vaultList.length, false);
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

  void setAnimatedVaultFlags({int? index}) {
    _animatedVaultFlags = List.filled(_vaultList.length, false);
    if (index != null) {
      _animatedVaultFlags[index - 1] = true;
    }
  }

  void linkNewSinglesigVaultAndMultisigVaults(
      SinglesigVaultListItem singlesigVaultItem) {
    SinglesigVaultListItem ssv = singlesigVaultItem;

    /// 니모닉 문구를 통해 볼트를 추가했을 때, 가지고 있는 다중서명지갑에서 이 볼트를 키로 사용하고 있으면 정보를 변경합니다.
    outerLoop:
    for (int i = 0; i < _vaultList.length; i++) {
      VaultListItemBase vault = _vaultList[i];
      // 싱글 시그는 스킵
      if (vault.vaultType == VaultType.singleSignature) continue;

      List<MultisigSigner> signers = (vault as MultisigVaultListItem).signers;
      // 멀티 시그만 판단
      String importedMfp =
          (ssv.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
      for (int j = 0; j < signers.length; j++) {
        String signerMfp = signers[j].keyStore.masterFingerprint;

        if (signerMfp == importedMfp) {
          // 다중 서명 지갑에서 signer로 사용되고 있는 mfp와 새로 추가된 볼트의 mfp가 같으면 정보를 변경
          final signer = (_vaultList[i] as MultisigVaultListItem).signers[j];
          signer
            ..innerVaultId = ssv.id
            ..name = ssv.name
            ..iconIndex = ssv.iconIndex
            ..colorIndex = ssv.colorIndex
            ..memo = null;
          Map<int, int> linkedMultisigInfo = {vault.id: j};
          if (ssv.linkedMultisigInfo == null) {
            ssv.linkedMultisigInfo = linkedMultisigInfo;
          } else {
            ssv.linkedMultisigInfo!.addAll(linkedMultisigInfo);
          }
          continue outerLoop; // 같은 singlesig가 하나의 multisig 지갑에 2번 이상 signer로 등록될 수 없으므로
        }
      }
    }
  }

  Future<void> addVault(SinglesigWallet wallet) async {
    setAddVaultCompleted(false);

    await _walletManager.addSinglesigWallet(wallet);
    _vaultList = _walletManager.vaultList;

    setAnimatedVaultFlags(index: _vaultList.length);
    setAddVaultCompleted(true);
    await updateVaultInStorage();

    notifyListeners();
    completeSinglesigImporting();
    // vibrateLight();
  }

  Future<void> addMultisigVaultAsync(String name, int color, int icon) async {
    setAddVaultCompleted(false);

    final signers = _multisigCreationModel.signers!;
    final requiredSignatureCount =
        _multisigCreationModel.requiredSignatureCount!;

    await _walletManager.addMultisigWallet(MultisigWallet(
        null, name, icon, color, signers, requiredSignatureCount));

    _vaultList = _walletManager.vaultList;
    setAnimatedVaultFlags(index: _vaultList.length);
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
      MultisigImportDetail details, int walletId) async {
    setAddVaultCompleted(false);

    // 이 지갑이 위 멀티시그 지갑의 일부인지 확인하기
    MultisignatureVault multisigVault =
        MultisignatureVault.fromCoordinatorBsms(details.coordinatorBsms);

    // 중복 코드 확인
    List<SinglesigVaultListItem?> linkedWalletList = [];
    bool isRelated = false;
    outerLoop:
    for (var wallet in _vaultList) {
      if (wallet.vaultType == VaultType.multiSignature) continue;
      for (var keyStore in multisigVault.keyStoreList) {
        var singlesigVaultListItem = wallet as SinglesigVaultListItem;
        if ((singlesigVaultListItem.coconutVault as SingleSignatureVault)
                .keyStore
                .masterFingerprint ==
            keyStore.masterFingerprint) {
          linkedWalletList.add(wallet);
          if (singlesigVaultListItem.id == walletId) {
            isRelated = true;
          }
          continue outerLoop;
        }
        linkedWalletList.add(null);
      }
    }

    if (!isRelated) {
      throw NotRelatedMultisigWalletException();
    }

    List<MultisigSigner> signers = [];
    for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
      // 외부 지갑
      if (linkedWalletList[i] == null) {
        signers.add(MultisigSigner(
            id: i,
            name: details
                .namesMap[multisigVault.keyStoreList[i].masterFingerprint],
            keyStore: multisigVault.keyStoreList[i]));
      } else {
        // 내부 지갑
        signers.add(MultisigSigner(
          id: i,
          // TODO: signerBsms: linkedWalletList[i].signerBsms,
          signerBsms: 'signerBSMS',
          innerVaultId: linkedWalletList[i]!.id,
          keyStore: KeyStore.fromSignerBsms(
              'signerBsms'), //TODO: linkedWalletList[i].signerBsms
          name: linkedWalletList[i]!.name,
          iconIndex: linkedWalletList[i]!.iconIndex,
          colorIndex: linkedWalletList[i]!.colorIndex,
        ));
      }
    }

    _multisigCreationModel.signers = signers;
    _multisigCreationModel.setQuoramRequirement(
        multisigVault.requiredSignature, multisigVault.keyStoreList.length);
    await addMultisigVaultAsync(
        details.name, details.colorIndex, details.iconIndex);
    // return multisigVault.keyStoreList.indexWhere((keyStore) =>
    //     keyStore.masterFingerprint ==
    //     (singlesigVaultListItem.coconutVault as SingleSignatureVault)
    //         .keyStore
    //         .masterFingerprint);

    // // 이 지갑의 signerBsms, isolate 실행
    // int signerIndex = await _vaultModel.getSignerIndexAsync(
    //     multisigVault, vaultListItem as SinglesigVaultListItem);

    // //Logger.log('signerIndex = $signerIndex');
    // if (signerIndex == -1) {
    //   onFailedScanning('이 지갑을 키로 사용한 다중 서명 지갑이 아닙니다.');
    //   return;
    // }

    // TODO: details를 가지고 MultisigWallet을 생성해야한다.

    // final nextId = SharedPrefsService().getInt('nextId') ?? 1;

    // Map<String, dynamic> data = {
    //   'nextId': nextId,
    //   'name': details.name,
    //   'colorIndex': details.colorIndex,
    //   'iconIndex': details.iconIndex,
    //   'namesMap': details.namesMap,
    //   'secrets': {
    //     'bsms': details.coordinatorBsms,
    //     'vaultList':
    //         jsonEncode(_vaultList.map((item) => item.toJson()).toList()),
    //   }
    // };
    // if (_importMultisigVaultIsolateHandler == null) {
    //   _importMultisigVaultIsolateHandler =
    //       IsolateHandler<Map<String, dynamic>, MultisigVaultListItem>(
    //           importMultisigVaultIsolate);
    //   await _importMultisigVaultIsolateHandler!
    //       .initialize(initialType: InitializeType.importMultisigVault);
    // }

    // isolate 내부에서 멀티시그 지갑 signer들의 정보 입력 (MultisigKey,MultisigIndex), innerVault == null이면 외부지갑
    // MultisigVaultListItem newMultisigVault =
    //     await _importMultisigVaultIsolateHandler!.run(data);

    // for SinglesigVaultListItem multsig key map update
    // updateLinkedMultisigInfo(newMultisigVault.signers, nextId);

    // _vaultList.add(newMultisigVault);
    // setAnimatedVaultFlags(index: _vaultList.length);

    // _importMultisigVaultIsolateHandler!.dispose();
    // _importMultisigVaultIsolateHandler = null;

    // SharedPrefsService().setInt('nextId', nextId + 1);
    setAddVaultCompleted(true);
    //await updateVaultInStorage();
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

  /// [id]에 해당하는 지갑의 UI 정보 업데이트
  Future<void> updateVault(
      int id, String newName, int colorIndex, int iconIndex) async {
    if (await _walletManager.updateWallet(id, newName, colorIndex, iconIndex)) {
      _vaultList = _walletManager.vaultList;
      notifyListeners();
    }
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

  Future<void> deleteVault(int id) async {
    if (await _walletManager.deleteWallet(id)) {
      _vaultList = _walletManager.vaultList;
      notifyListeners();
    }
  }

  Future<void> loadVaultList() async {
    if (_isVaultListLoading) return;

    _isVaultListLoading = true;
    _vaultSkeletonLength = _appModel.vaultListLength;
    notifyListeners();

    try {
      final jsonList = await _walletManager.loadVaultListJsonArrayString();

      if (jsonList != null) {
        if (_vaultSkeletonLength == 0) {
          // 이전 버전 사용자는 vault개수가 로컬에 없으므로 업데이트
          _vaultSkeletonLength = jsonList.length;
          _appModel.saveVaultListLength(jsonList.length);
          notifyListeners();
        }
        await _walletManager.loadAndEmitEachWallet(jsonList,
            (VaultListItemBase wallet) {
          _vaultList.add(wallet);
          _vaultSkeletonLength = _vaultSkeletonLength - 1;
          notifyListeners();
        });
      }

      vibrateLight();
      _vaultInitialized = true;
    } catch (e) {
      Logger.log('[loadVaultList] Exception : ${e.toString()}');
      rethrow;
    } finally {
      _isVaultListLoading = false;
      _isLoadVaultList = true;
      notifyListeners();
    }
    return;
  }

  Future<void> updateVaultInStorage() async {
    final jsonString =
        jsonEncode(_vaultList.map((item) => item.toJson()).toList());
    // printLongString('updateVaultInStorage ---> $jsonString');
    await _storageService.write(key: VAULT_LIST, value: jsonString);
    _realmService.updateKeyValue(key: VAULT_LIST, value: jsonString);
    _appModel.saveVaultListLength(_vaultList.length);
  }

  void startImporting(String secret, String passphrase) {
    _importingSecret = secret;
    _importingPassphrase = passphrase;
  }

  void completeSinglesigImporting() {
    _importingSecret = null;
  }

  void setWaitingForSignaturePsbtBase64(String psbt) {
    _waitingForSignaturePsbtBase64 = psbt;
  }

  void clearWaitingForSignaturePsbt() {
    _waitingForSignaturePsbtBase64 = null;
  }

  void setAddVaultCompleted(bool value) {
    _isAddVaultCompleted = value;
    notifyListeners();
  }

  Future<Secret> getSecret(int id) async {
    return await _walletManager.getSecret(id);
  }

  @override
  void dispose() {
    // if (_vaultListIsolateHandler != null) {
    //   _vaultListIsolateHandler!.dispose();
    //   _vaultListIsolateHandler = null;
    // }
    // if (_addVaultIsolateHandler != null) {
    //   _addVaultIsolateHandler!.dispose();
    //   _addVaultIsolateHandler = null;
    // }
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
