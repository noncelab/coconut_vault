import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:flutter/foundation.dart';

const kMaxStarLength = 5;

class WalletProvider extends ChangeNotifier {
  late final VisibilityProvider _visibilityProvider;
  late final WalletRepository _walletRepository;
  late final PreferenceProvider _preferenceProvider;

  WalletProvider(
    this._visibilityProvider,
    this._preferenceProvider,
  ) {
    _walletRepository = WalletRepository();
    vaultListNotifier = ValueNotifier(_vaultList);
  }

  // Vault list
  List<VaultListItemBase> _vaultList = [];
  List<VaultListItemBase> get vaultList => vaultListNotifier.value;
  // 리스트 로딩중 여부 (indicator 표시 및 중복 방지)
  bool _isVaultListLoading = false;
  bool get isVaultListLoading => _isVaultListLoading;
  // vault_type_selection_screen, vault_name_and_icon_setup_screen, app_update_preparation_screen 에서 사용
  // 다음 버튼 클릭시 loadVaultList()가 아직 진행중인 경우 완료 시점을 캐치하기 위함
  final ValueNotifier<bool> isVaultListLoadingNotifier = ValueNotifier<bool>(false);
  // 리스트 로딩 완료 여부 (로딩작업 완료 후 바로 추가하기 표시)
  // 최초 한번 완료 후 재로드 없음
  bool _isWalletsLoaded = false;
  bool get isVaultsLoaded => _isWalletsLoaded;

  late final ValueNotifier<List<VaultListItemBase>> vaultListNotifier;

  // addVault
  bool _isAddVaultCompleted = false;
  bool get isAddVaultCompleted => _isAddVaultCompleted;

  String? _waitingForSignaturePsbtBase64;
  String? get waitingForSignaturePsbtBase64 => _waitingForSignaturePsbtBase64;

  String? signedRawTx;

  bool _isDisposed = false;

  void _setVaultList(List<VaultListItemBase> value) {
    _vaultList = value;
    vaultListNotifier.value = value;
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

  List<VaultListItemBase> getVaultsByWalletType(WalletType walletType) {
    return vaultList.where((vault) => vault.vaultType == walletType).toList();
  }

  Future<SingleSigVaultListItem> addSingleSigVault(SingleSigWalletCreateDto wallet) async {
    _setAddVaultCompleted(false);

    final vault = await _walletRepository.addSinglesigWallet(wallet);
    _setVaultList(_walletRepository.vaultList);
    _preferenceProvider.setVaultOrder(_vaultList.map((e) => e.id).toList());
    _addToFavoriteWallets(_vaultList.last.id);

    _setAddVaultCompleted(true);
    await _updateWalletLength();

    notifyListeners();
    return vault;
  }

  Future<MultisigVaultListItem> addMultisigVault(String name, int color, int icon,
      List<MultisigSigner> signers, int requiredSignatureCount) async {
    _setAddVaultCompleted(false);

    final vault = await _walletRepository.addMultisigWallet(
        MultisigWallet(null, name, icon, color, signers, requiredSignatureCount));

    _setVaultList(_walletRepository.vaultList);
    _preferenceProvider.setVaultOrder(_vaultList.map((e) => e.id).toList());
    _addToFavoriteWallets(_vaultList.last.id);

    _setAddVaultCompleted(true);
    await _updateWalletLength();
    notifyListeners();
    return vault;
  }

  Future<void> _addToFavoriteWallets(int walletId) async {
    final favoriteWallets = _preferenceProvider.favoriteVaultIds.toList();

    // 즐겨찾기된 지갑이 5개이상이면 등록안함
    if (favoriteWallets.length < kMaxStarLength && !favoriteWallets.contains(walletId)) {
      favoriteWallets.add(walletId);
      await _preferenceProvider.setFavoriteVaultIds(favoriteWallets);
    }
  }

  Future<bool> hasPassphrase(int walletId) {
    return _walletRepository.hasPassphrase(walletId);
  }

  Future<MultisigVaultListItem> importMultisigVault(
      MultisigImportDetail details, int walletId) async {
    _setAddVaultCompleted(false);

    // 이 지갑이 위 멀티시그 지갑의 일부인지 확인하기
    MultisignatureVault multisigVault =
        MultisignatureVault.fromCoordinatorBsms(details.coordinatorBsms);

    // 중복 코드 확인
    List<SingleSigVaultListItem?> linkedWalletList = [];
    linkedWalletList.insertAll(0, List.filled(multisigVault.keyStoreList.length, null));
    bool isRelated = false;
    outerLoop:
    for (var wallet in _vaultList) {
      if (wallet.vaultType == WalletType.multiSignature) continue;

      var singleSigVaultListItem = wallet as SingleSigVaultListItem;
      var walletMfp =
          (singleSigVaultListItem.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
      for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
        if (walletMfp == multisigVault.keyStoreList[i].masterFingerprint) {
          linkedWalletList[i] = wallet;
          if (singleSigVaultListItem.id == walletId) {
            isRelated = true;
          }
          continue outerLoop;
        }
      }
    }

    if (!isRelated) {
      throw NotRelatedMultisigWalletException();
    }

    // MultisigImportDetail + vaultList를 이용하여 List<MultisigSigner>를 생성
    List<MultisigSigner> signers = [];
    for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
      // 외부 지갑
      if (linkedWalletList[i] == null) {
        signers.add(MultisigSigner(
            id: i,
            name: details.namesMap[multisigVault.keyStoreList[i].masterFingerprint],
            keyStore: multisigVault.keyStoreList[i]));
      } else {
        // 내부 지갑
        signers.add(MultisigSigner(
          id: i,
          signerBsms: linkedWalletList[i]!.signerBsms,
          innerVaultId: linkedWalletList[i]!.id,
          keyStore: KeyStore.fromSignerBsms(linkedWalletList[i]!.signerBsms),
          name: linkedWalletList[i]!.name,
          iconIndex: linkedWalletList[i]!.iconIndex,
          colorIndex: linkedWalletList[i]!.colorIndex,
        ));
      }
    }

    final vault = await addMultisigVault(details.name, details.colorIndex, details.iconIndex,
        signers, multisigVault.requiredSignature);

    _setAddVaultCompleted(true);
    notifyListeners();
    return vault;
  }

  /// [id]에 해당하는 지갑의 UI 정보 업데이트
  Future<void> updateVault(int id, String newName, int colorIndex, int iconIndex) async {
    await _walletRepository.updateWallet(id, newName, colorIndex, iconIndex);
    _setVaultList(_walletRepository.vaultList);
    notifyListeners();
  }

  /// 다중서명 지갑의 [singerIndex]번째 키로 사용한 외부 지갑의 메모를 업데이트
  Future updateMemo(int id, int signerIndex, String? newMemo) async {
    int index = _vaultList.indexWhere((wallet) => wallet.id == id);
    _vaultList[index] = await _walletRepository.updateMemo(id, signerIndex, newMemo);
  }

  /// SiglesigVaultListItem의 seed 중복 여부 확인
  // TODO: lib 파라미터 Uint8List로 수정 필요
  bool isSeedDuplicated(Uint8List secret, Uint8List passphrase) {
    var coconutVault = SingleSignatureVault.fromMnemonic(secret,
        addressType: AddressType.p2wpkh, passphrase: passphrase);
    final vaultIndex = _vaultList.indexWhere((element) {
      if (element is SingleSigVaultListItem) {
        return (element.coconutVault as SingleSignatureVault).descriptor == coconutVault.descriptor;
      }

      return false;
    });

    return vaultIndex != -1;
  }

  /// MultisigVaultListItem의 coordinatorBsms 중복 여부 확인
  MultisigVaultListItem? findMultisigWalletByCoordinatorBsms(String coordinatorBsms) {
    final vaultIndex = _vaultList.indexWhere((element) {
      return (element is MultisigVaultListItem && element.coordinatorBsms == coordinatorBsms);
    });

    return vaultIndex != -1 ? _vaultList[vaultIndex] as MultisigVaultListItem : null;
  }

  VaultListItemBase? findWalletByDescriptor(String descriptor) {
    final vaultIndex =
        _vaultList.indexWhere((element) => element.coconutVault.descriptor == descriptor);

    return vaultIndex != -1 ? _vaultList[vaultIndex] : null;
  }

  bool isNameDuplicated(String name) {
    final vaultIndex = _vaultList.indexWhere((element) => element.name == name);

    return vaultIndex != -1;
  }

  Future<void> deleteWallet(int id) async {
    if (await _walletRepository.deleteWallet(id)) {
      _setVaultList(_walletRepository.vaultList);
      await _preferenceProvider.removeVaultOrder(id);
      await _preferenceProvider.removeFavoriteVaultId(id);
      notifyListeners();
      _updateWalletLength();
    }
  }

  Future<void> deleteAllWallets() async {
    await _walletRepository.deleteWallets();
    _setVaultList(_walletRepository.vaultList);
    notifyListeners();
    _updateWalletLength();
  }

  Future<void> loadVaultList() async {
    if (_isVaultListLoading) return;

    _isVaultListLoading = true;
    isVaultListLoadingNotifier.value = true;
    notifyListeners();

    try {
      final jsonList = await _walletRepository.loadVaultListJsonArrayString();

      if (jsonList != null) {
        if (jsonList.isEmpty) {
          _updateWalletLength();

          notifyListeners();
          return;
        }

        await _walletRepository.loadAndEmitEachWallet(jsonList, (VaultListItemBase wallet) {
          if (_isDisposed) {
            return;
          }
          _vaultList.add(wallet);
          notifyListeners();
        });
      }

      if (_isDisposed) {
        return;
      }

      vibrateLight();
    } catch (e) {
      Logger.log('[loadVaultList] Exception : ${e.toString()}');
      rethrow;
    } finally {
      if (_isDisposed) {
        // ignore: control_flow_in_finally
        return;
      }
      _isVaultListLoading = false;
      isVaultListLoadingNotifier.value = false;
      _isWalletsLoaded = true;
      notifyListeners();
    }
    return;
  }

  Future<void> _updateWalletLength() async {
    await _visibilityProvider.saveWalletCount(_vaultList.length);
  }

  void setWaitingForSignaturePsbtBase64(String psbt) {
    _waitingForSignaturePsbtBase64 = psbt;
  }

  void clearWaitingForSignaturePsbt() {
    _waitingForSignaturePsbtBase64 = null;
  }

  void _setAddVaultCompleted(bool value) {
    _isAddVaultCompleted = value;
    notifyListeners();
  }

  Future<Uint8List> getSecret(int id) async {
    return await _walletRepository.getSecret(id);
  }

  Future<String> createBackupData() async {
    final List<Map<String, dynamic>> backupData = [];

    try {
      for (final vault in _vaultList) {
        final vaultData = vault.toJson();

        if (vault.vaultType == WalletType.singleSignature) {
          vaultData['secret'] = await getSecret(vault.id);
          vaultData['hasPassphrase'] = await hasPassphrase(vault.id);
        }

        backupData.add(vaultData);
      }

      final jsonData = jsonEncode(backupData);
      return jsonData;
    } finally {
      for (final vault in backupData) {
        if (vault['vaultType'] == WalletType.singleSignature) {
          (vault['secret'] as Uint8List).wipe();
        }
      }
    }
  }

  Future<void> restoreFromBackupData(String jsonData) async {
    final List<Map<String, dynamic>> backupDataMapList = jsonDecode(jsonData)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    /// 아래 restoreFromBackupData 함수 내에서 secret정보는 사라집니다.
    await _walletRepository.restoreFromBackupData(backupDataMapList);

    _setVaultList(_walletRepository.vaultList);
    notifyListeners();
    await _updateWalletLength();
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    // stop if loading
    _isDisposed = true;
    _walletRepository.dispose();

    _vaultList.clear();
    _waitingForSignaturePsbtBase64 = null;
    signedRawTx = null;
    super.dispose();
  }
}
