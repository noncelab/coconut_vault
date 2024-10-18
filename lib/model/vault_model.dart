import 'dart:async';
import 'dart:convert';

import 'package:coconut_vault/services/shared_preferences_keys.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:coconut_vault/utils/logger.dart';
import '../services/secure_storage_service.dart';
import 'vault_list_item.dart';

// ignore: constant_identifier_names
const String VAULT_LIST = "VAULT_LIST";

class VaultModel extends ChangeNotifier {
  AppModel _appModel;
  late final SecureStorageService _storageService;

  // 비동기 작업 Isolate
  IsolateHandler<void, List<VaultListItem>>? _vaultListIsolateHandler;
  IsolateHandler<Map<String, dynamic>, List<VaultListItem>>?
      _addVaultIsolateHandler;

  VaultModel(this._appModel) {
    _storageService = SecureStorageService();
    // loadVaultList();
    //_initializeServicesAndHandler();
  }

  /// [_appModel]의 변동사항 업데이트
  void updateAppModel(AppModel appModel) {
    _appModel = appModel;
  }

  // Vault list
  List<VaultListItem> _vaultList = [];
  bool _isVaultListLoading = false;
  // double _vaultListLoadingProgress = 0.0;
  List<VaultListItem> get vaultList => _vaultList;
  bool get isVaultListLoading => _isVaultListLoading; // 상태 접근자 추가
  // double get vaultListLoadingProgress => _vaultListLoadingProgress;
  // static int itemSize = 0;
  bool _vaultInitialized = false;
  bool get vaultInitialized => _vaultInitialized;

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
    _importingSecret = null;
    _importingPassphrase = '';
    _waitingForSignaturePsbtBase64 = null;
    signedRawTx = null;
    _vaultList.clear();
    await _appModel.resetPassword();
    notifyListeners();
  }

  // Returns a copy of the list of vault list.
  List<VaultListItem> getVaults() {
    if (_vaultList.isEmpty) {
      return [];
    }

    return List.from(_vaultList);
  }

  VaultListItem getVaultById(int id) {
    return _vaultList.firstWhere((element) => element.id == id);
  }

  VaultListItem getVaultByName(String name) {
    return _vaultList.firstWhere((element) => element.name == name);
  }

  Future<void> addVault(Map<String, dynamic> vaultData) async {
    _setAddVaultCompleted(false);
    // web에서는 Isolate를 지원하지 않으므로,
    // vaultData를 이용해서 새로운 vaultListResult를 만들어야 합니다.
    VaultListItem newItem = await VaultListItem.create(
      name: vaultData['inputText'],
      colorIndex: vaultData['selectedIconIndex'],
      iconIndex: vaultData['selectedColorIndex'],
      secret: vaultData['importingSecret'],
      passphrase: vaultData['importingPassphrase'],
    );

    _vaultList.addAll([newItem]);
    _setAddVaultCompleted(true);
    await updateVaultInStorage();

    notifyListeners();
    stopImporting();
  }

  Future<void> updateVault(
      int id, String newName, int colorIndex, int iconIndex) async {
    // _vaultList에서 name이 'name'인 항목을 찾아서 그 항목의 name을 newName으로 변경한다.
    final index = _vaultList.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('updateVaultName: no vault id is "$id"');
    }

    // _vaultList[index].vault!.name = newName;

    _vaultList[index] = VaultListItem(
      id: _vaultList[index].id,
      name: newName,
      colorIndex: colorIndex,
      iconIndex: iconIndex,
      secret: _vaultList[index].secret,
      passphrase: _vaultList[index].passphrase,
    );

    // 해당 항목의 name을 newName으로 변경
    await updateVaultInStorage();
    notifyListeners();
  }

  bool isSeedDuplicated(String secret, String passphrase) {
    final vaultIndex = _vaultList.indexWhere((element) =>
        element.secret == secret && element.passphrase == passphrase);

    return vaultIndex != -1;
  }

  bool isNameDuplicated(String name) {
    final vaultIndex = _vaultList.indexWhere((element) => element.name == name);

    return vaultIndex != -1;
  }

  Future<void> deleteVault(int id) async {
    final index = _vaultList.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('deleteVault: no vault id is "$id"');
    }

    _vaultList.removeAt(index);

    await updateVaultInStorage();
    notifyListeners();
  }

  Future<void> loadVaultList() async {
    if (_isVaultListLoading) return;

    _setVaultListLoading(true);
    try {
      List<VaultListItem> vaultList = [];
      String? jsonArrayString = await _storageService.read(key: VAULT_LIST);

      if (jsonArrayString != null) {
        List<dynamic> jsonList = jsonDecode(jsonArrayString);
        int totalItems = jsonList.length;
        for (int i = 0; i < totalItems; i++) {
          vaultList.add(VaultListItem.fromJson(jsonList[i]));
        }
      }

      _vaultList = vaultList;
      _vaultInitialized = true;
    } catch (e) {
      Logger.log('[loadVaultList] Exception : ${e.toString()}');
    } finally {
      _appModel.saveNotEmptyVaultList(_vaultList.isNotEmpty);
      _setVaultListLoading(false);
    }
  }

  static Future<List<VaultListItem>> _loadVaultListIsolate(
      void _, void Function(List<dynamic>)? setVaultListLoadingProgress) async {
    List<VaultListItem> vaultList = [];
    String? jsonArrayString;
    final SecureStorageService storageService = SecureStorageService();
    jsonArrayString = await storageService.read(key: VAULT_LIST);

    if (jsonArrayString != null) {
      List<dynamic> jsonList = jsonDecode(jsonArrayString);
      int totalItems = jsonList.length;
      for (int i = 0; i < totalItems; i++) {
        vaultList.add(VaultListItem.fromJson(jsonList[i]));
      }
    }

    return vaultList;
  }

  Future<void> updateVaultInStorage() async {
    final jsonString =
        jsonEncode(_vaultList.map((item) => item.toJson()).toList());
    await _storageService.write(key: VAULT_LIST, value: jsonString);

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

  void _setVaultListLoading(bool value) {
    _isVaultListLoading = value;
    notifyListeners();
  }

  void _setAddVaultCompleted(bool value) {
    _isAddVaultCompleted = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_vaultListIsolateHandler != null) {
      _vaultListIsolateHandler!.dispose();
    }
    if (_addVaultIsolateHandler != null) {
      _addVaultIsolateHandler!.dispose();
    }
    super.dispose();
  }
}
