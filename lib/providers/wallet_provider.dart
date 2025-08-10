import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/model/common/secret.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:flutter/foundation.dart';

class WalletProvider extends ChangeNotifier {
  late final VisibilityProvider _visibilityProvider;
  late final WalletRepository _walletRepository;

  WalletProvider(this._visibilityProvider) {
    _walletRepository = WalletRepository();
  }

  // Vault list
  List<VaultListItemBase> _vaultList = [];
  List<VaultListItemBase> get vaultList => _vaultList;
  // 리스트 로딩중 여부 (indicator 표시 및 중복 방지)
  bool _isVaultListLoading = false;
  bool get isVaultListLoading => _isVaultListLoading;
  // vault_type_selection_screen, vault_name_and_icon_setup_screen, app_update_preparation_screen 에서 사용
  // 다음 버튼 클릭시 loadVaultList()가 아직 진행중인 경우 완료 시점을 캐치하기 위함
  final ValueNotifier<bool> isVaultListLoadingNotifier = ValueNotifier<bool>(false);
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

    if (_animatedVaultFlags.isNotEmpty && _animatedVaultFlags.first) {
      setAnimatedVaultFlags();
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

  List<VaultListItemBase> getVaultsByWalletType(WalletType walletType) {
    return vaultList.where((vault) => vault.vaultType == walletType).toList();
  }

  void setAnimatedVaultFlags() {
    _animatedVaultFlags = List.filled(_vaultList.length, false);
    _animatedVaultFlags[0] = true;
  }

  Future<void> addSingleSigVault(SinglesigWallet wallet) async {
    _setAddVaultCompleted(false);

    await _walletRepository.addSinglesigWallet(wallet);
    _vaultList = _walletRepository.vaultList;

    setAnimatedVaultFlags();
    _setAddVaultCompleted(true);
    await _updateWalletLength();

    notifyListeners();
    // vibrateLight();
  }

  Future<void> addMultisigVault(String name, int color, int icon, List<MultisigSigner> signers,
      int requiredSignatureCount) async {
    _setAddVaultCompleted(false);

    await _walletRepository.addMultisigWallet(
        MultisigWallet(null, name, icon, color, signers, requiredSignatureCount));

    _vaultList = _walletRepository.vaultList;
    setAnimatedVaultFlags();
    _setAddVaultCompleted(true);
    await _updateWalletLength();
    notifyListeners();
  }

  Future<void> importMultisigVault(MultisigImportDetail details, int walletId) async {
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
          signerBsms: linkedWalletList[i]!.signerBsms!,
          innerVaultId: linkedWalletList[i]!.id,
          keyStore: KeyStore.fromSignerBsms(linkedWalletList[i]!.signerBsms!),
          name: linkedWalletList[i]!.name,
          iconIndex: linkedWalletList[i]!.iconIndex,
          colorIndex: linkedWalletList[i]!.colorIndex,
        ));
      }
    }

    await addMultisigVault(details.name, details.colorIndex, details.iconIndex, signers,
        multisigVault.requiredSignature);

    _setAddVaultCompleted(true);
    notifyListeners();
  }

  /// [id]에 해당하는 지갑의 UI 정보 업데이트
  Future<void> updateVault(int id, String newName, int colorIndex, int iconIndex) async {
    await _walletRepository.updateWallet(id, newName, colorIndex, iconIndex);
    _vaultList = _walletRepository.vaultList;
    notifyListeners();
  }

  /// 다중서명 지갑의 [singerIndex]번째 키로 사용한 외부 지갑의 메모를 업데이트
  Future updateMemo(int id, int signerIndex, String? newMemo) async {
    int index = _vaultList.indexWhere((wallet) => wallet.id == id);
    _vaultList[index] = await _walletRepository.updateMemo(id, signerIndex, newMemo);
  }

  /// SiglesigVaultListItem의 seed 중복 여부 확인
  bool isSeedDuplicated(String secret, String passphrase) {
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
    final vaultIndex = _vaultList.indexWhere((element) =>
        (element is MultisigVaultListItem && element.coordinatorBsms == coordinatorBsms));

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
      _vaultList = _walletRepository.vaultList;
      notifyListeners();
      _updateWalletLength();
    }
  }

  Future<void> deleteAllWallets() async {
    await _walletRepository.deleteWallets();
    _vaultList = _walletRepository.vaultList;
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

  Future<String> getSecret(int id) async {
    return await _walletRepository.getSecret(id);
  }

  Future<String> createBackupData() async {
    final List<Map<String, dynamic>> backupData = [];

    for (final vault in _vaultList) {
      final vaultData = vault.toJson();

      if (vault.vaultType == WalletType.singleSignature) {
        final secret = await getSecret(vault.id);
        vaultData['secret'] = secret.mnemonic;
        vaultData['passphrase'] = secret.passphrase;
      }

      backupData.add(vaultData);
    }

    final jsonData = jsonEncode(backupData);

    return jsonData;
  }

  Future<void> restoreFromBackupData(String jsonData) async {
    final List<Map<String, dynamic>> backupDataMapList = jsonDecode(jsonData)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    await _walletRepository.restoreFromBackupData(backupDataMapList);
    _vaultList = _walletRepository.vaultList;

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
    _animatedVaultFlags = [];
    _waitingForSignaturePsbtBase64 = null;
    signedRawTx = null;
    super.dispose();
  }
}
