import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/singlesig/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/common/secret.dart';
import 'package:coconut_vault/model/singlesig/singlesig_wallet.dart';
import 'package:coconut_vault/managers/wallet_list_manager.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/vibration_util.dart';

class WalletProvider extends ChangeNotifier {
  late final VisibilityProvider _visibilityProvider;
  late final WalletListManager _walletManager;

  WalletProvider(this._visibilityProvider) {
    _walletManager = WalletListManager();
  }

  // Vault list
  List<VaultListItemBase> _vaultList = [];
  List<VaultListItemBase> get vaultList => _vaultList;
  // 리스트 로딩중 여부 (indicator 표시 및 중복 방지)
  bool _isVaultListLoading = false;
  bool get isVaultListLoading => _isVaultListLoading;
  // vault_type_selection_screen.dart, vault_name_and_icon_setup_screen.dart 에서 사용
  // 다음 버튼 클릭시 loadVaultList()가 아직 진행중인 경우 완료 시점을 캐치하기 위함
  final ValueNotifier<bool> isVaultListLoadingNotifier =
      ValueNotifier<bool>(false);
  // 리스트 로딩 완료 여부 (로딩작업 완료 후 바로 추가하기 표시)
  // 최초 한번 완료 후 재로드 없음
  bool _isWalletsLoaded = false;
  bool get isWalletsLoaded => _isWalletsLoaded;

  // addVault
  bool _isAddVaultCompleted = false;
  bool get isAddVaultCompleted => _isAddVaultCompleted;

  // 리스트에 추가되는 애니메이션이 동작해야하면 true, 아니면 false를 담습니다.
  List<bool> _animatedVaultFlags = [];
  List<bool> get animatedVaultFlags => _animatedVaultFlags;

  String? _waitingForSignaturePsbtBase64;
  String? get waitingForSignaturePsbtBase64 => _waitingForSignaturePsbtBase64;

  String? signedRawTx;

  bool _isDisposed = false;

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

  Future<void> addSingleSigVault(SinglesigWallet wallet) async {
    _setAddVaultCompleted(false);

    await _walletManager.addSinglesigWallet(wallet);
    _vaultList = _walletManager.vaultList;

    setAnimatedVaultFlags(index: _vaultList.length);
    _setAddVaultCompleted(true);
    await _updateWalletLength();

    notifyListeners();
    // vibrateLight();
  }

  Future<void> addMultisigVaultAsync(String name, int color, int icon,
      List<MultisigSigner> signers, int requiredSignatureCount) async {
    _setAddVaultCompleted(false);

    await _walletManager.addMultisigWallet(MultisigWallet(
        null, name, icon, color, signers, requiredSignatureCount));

    _vaultList = _walletManager.vaultList;
    setAnimatedVaultFlags(index: _vaultList.length);
    _setAddVaultCompleted(true);
    await _updateWalletLength();
    notifyListeners();
  }

  Future<void> importMultisigVaultAsync(
      MultisigImportDetail details, int walletId) async {
    _setAddVaultCompleted(false);

    // 이 지갑이 위 멀티시그 지갑의 일부인지 확인하기
    MultisignatureVault multisigVault =
        MultisignatureVault.fromCoordinatorBsms(details.coordinatorBsms);

    // 중복 코드 확인
    List<SinglesigVaultListItem?> linkedWalletList = [];
    linkedWalletList.insertAll(
        0, List.filled(multisigVault.keyStoreList.length, null));
    bool isRelated = false;
    outerLoop:
    for (var wallet in _vaultList) {
      if (wallet.vaultType == WalletType.multiSignature) continue;

      var singlesigVaultListItem = wallet as SinglesigVaultListItem;
      var walletMFP =
          (singlesigVaultListItem.coconutVault as SingleSignatureVault)
              .keyStore
              .masterFingerprint;
      for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
        if (walletMFP == multisigVault.keyStoreList[i].masterFingerprint) {
          linkedWalletList[i] = wallet;
          if (singlesigVaultListItem.id == walletId) {
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
            name: details
                .namesMap[multisigVault.keyStoreList[i].masterFingerprint],
            keyStore: multisigVault.keyStoreList[i]));
      } else {
        // 내부 지갑
        signers.add(MultisigSigner(
          id: i,
          signerBsms: linkedWalletList[i]!.signerBsms!,
          innerVaultId: linkedWalletList[i]!.id,
          keyStore: KeyStore.fromSignerBsms(linkedWalletList[i]!.signerBsms!),
          name: linkedWalletList[i]!.name,
          iconIndex: linkedWalletList[i]!.iconIndex,
          colorIndex: linkedWalletList[i]!.colorIndex,
        ));
      }
    }

    await addMultisigVaultAsync(details.name, details.colorIndex,
        details.iconIndex, signers, multisigVault.requiredSignature);

    _setAddVaultCompleted(true);
    notifyListeners();
  }

  /// [id]에 해당하는 지갑의 UI 정보 업데이트
  Future<void> updateVault(
      int id, String newName, int colorIndex, int iconIndex) async {
    await _walletManager.updateWallet(id, newName, colorIndex, iconIndex);
    _vaultList = _walletManager.vaultList;
    notifyListeners();
  }

  /// 다중서명 지갑의 [singerIndex]번째 키로 사용한 외부 지갑의 메모를 업데이트
  Future updateMemo(int id, int signerIndex, String? newMemo) async {
    int index = _vaultList.indexWhere((wallet) => wallet.id == id);
    _vaultList[index] =
        await _walletManager.updateMemo(id, signerIndex, newMemo);
  }

  /// SiglesigVaultListItem의 seed 중복 여부 확인
  bool isSeedDuplicated(String secret, String passphrase) {
    var coconutVault = SingleSignatureVault.fromMnemonic(
        secret, AddressType.p2wpkh,
        passphrase: passphrase);
    final vaultIndex = _vaultList.indexWhere((element) {
      if (element is SinglesigVaultListItem) {
        return (element.coconutVault as SingleSignatureVault).descriptor ==
            coconutVault.descriptor;
      }

      return false;
    });

    return vaultIndex != -1;
  }

  /// MultisigVaultListItem의 coordinatorBsms 중복 여부 확인
  MultisigVaultListItem? findMultisigWalletByCoordinatorBsms(
      String coordinatorBsms) {
    final vaultIndex = _vaultList.indexWhere((element) =>
        (element is MultisigVaultListItem &&
            element.coordinatorBsms == coordinatorBsms));

    return vaultIndex != -1
        ? _vaultList[vaultIndex] as MultisigVaultListItem
        : null;
  }

  VaultListItemBase? findWalletByDescriptor(String descriptor) {
    final vaultIndex = _vaultList
        .indexWhere((element) => element.coconutVault.descriptor == descriptor);

    return vaultIndex != -1 ? _vaultList[vaultIndex] : null;
  }

  bool isNameDuplicated(String name) {
    final vaultIndex = _vaultList.indexWhere((element) => element.name == name);

    return vaultIndex != -1;
  }

  Future<void> deleteVault(int id) async {
    if (await _walletManager.deleteWallet(id)) {
      _vaultList = _walletManager.vaultList;
      notifyListeners();
      _updateWalletLength();
    }
  }

  Future<void> loadVaultList() async {
    if (_isVaultListLoading) return;

    _isVaultListLoading = true;
    isVaultListLoadingNotifier.value = true;
    notifyListeners();

    try {
      final jsonList = await _walletManager.loadVaultListJsonArrayString();

      if (jsonList != null) {
        if (jsonList.isEmpty) {
          _updateWalletLength();
          notifyListeners();
          return;
        }

        await _walletManager.loadAndEmitEachWallet(jsonList,
            (VaultListItemBase wallet) {
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

  _updateWalletLength() {
    _visibilityProvider.saveWalletCount(_vaultList.length);
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

  Future<Secret> getSecret(int id) async {
    return await _walletManager.getSecret(id);
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    // stop if loading
    _isDisposed = true;
    _walletManager.dispose();

    _vaultList.clear();
    _animatedVaultFlags = [];
    _waitingForSignaturePsbtBase64 = null;
    signedRawTx = null;
    super.dispose();
  }
}
