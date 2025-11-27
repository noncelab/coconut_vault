import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class WalletInfoViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  @protected
  WalletProvider get walletProvider => _walletProvider;

  VaultListItemBase? _vaultListItem;
  bool _isInitialized = false;
  final bool _isMultisig;

  VaultListItemBase get vaultItem {
    if (_vaultListItem == null) {
      throw StateError('VaultListItem is not initialized yet');
    }
    return _vaultListItem!;
  }

  String get name => vaultItem.name;
  int get colorIndex => vaultItem.colorIndex;
  int get iconIndex => vaultItem.iconIndex;
  DateTime get createdAt => vaultItem.createdAt;
  bool get isSigningOnlyMode => _walletProvider.isSigningOnlyMode;
  bool get isInitialized => _isInitialized;
  bool get isMultisig => _isMultisig;

  /// SingleSigInfoScreen Only
  int get linkedMutlsigVaultCount =>
      vaultItem is SingleSigVaultListItem ? (vaultItem as SingleSigVaultListItem).linkedMultisigInfo?.length ?? 0 : 0;
  bool get hasLinkedMultisigVault =>
      vaultItem is SingleSigVaultListItem
          ? (vaultItem as SingleSigVaultListItem).linkedMultisigInfo?.entries.isNotEmpty == true
          : false;
  Map<int, int>? get linkedMultisigInfo =>
      vaultItem is SingleSigVaultListItem ? (vaultItem as SingleSigVaultListItem).linkedMultisigInfo : null;
  bool get isLoadedVaultList => walletProvider.isVaultsLoaded;
  bool get isVaultListLoading => walletProvider.isVaultListLoading;

  /// MultisigInfoScreen Only
  late int signAvailableCount;
  List<MultisigSigner> get signers => (vaultItem as MultisigVaultListItem).signers;
  int get requiredSignatureCount => (vaultItem as MultisigVaultListItem).requiredSignatureCount;

  WalletInfoViewModel(this._walletProvider, int id, {bool isMultisig = false}) : _isMultisig = isMultisig {
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      _initializeVaultItem(id);
    } else {
      _setVaultListItem(id);
      _isInitialized = true;
    }

    if (_isMultisig) {
      _calculateSignAvailableCount();
    }
  }

  /// vaultList가 로드되지 않았을 때 비동기로 초기화
  Future<void> _initializeVaultItem(int id) async {
    await _walletProvider.loadVaultList();
    _setVaultListItem(id);
    _isInitialized = true;
    // build 중이 아닐 때만 notifyListeners 호출하도록 첫 프레임 이후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setVaultListItem(int id) {
    _ensureVaultExists(id);
    _vaultListItem = _walletProvider.getVaultById(id);
  }

  void refreshVaultItem(int id) {
    _setVaultListItem(id);
    _isInitialized = true;
    if (_isMultisig) {
      _calculateSignAvailableCount();
    }
    notifyListeners();
  }

  void _ensureVaultExists(int id) {
    final vaultExists = _walletProvider.vaultList.any((vault) => vault.id == id);
    if (!vaultExists) {
      throw StateError('Vault with id $id does not exist in the vault list.');
    }
  }

  Future<bool> updateVault(int id, String name, int colorIndex, int iconIndex) async {
    if (_vaultListItem == null) {
      return false;
    }
    if (name == _vaultListItem!.name &&
        colorIndex == _vaultListItem!.colorIndex &&
        iconIndex == _vaultListItem!.iconIndex) {
      return false;
    }

    if (name != _vaultListItem!.name && _walletProvider.isNameDuplicated(name)) {
      return false;
    }

    await _walletProvider.updateVault(id, name, colorIndex, iconIndex);
    notifyListeners();
    return true;
  }

  Future<void> deleteVault() async {
    if (_vaultListItem == null) {
      return;
    }
    await _walletProvider.deleteWallet(_vaultListItem!.id);
  }

  /// SingleSigInfoScreen Only
  VaultListItemBase getVaultById(int id) {
    return walletProvider.getVaultById(id);
  }

  bool existsLinkedMultisigVault(int id) {
    return walletProvider.vaultList.any((element) => element.id == id);
  }

  ///----------------------------------------------------

  /// MultisigInfoScreen Only
  void _calculateSignAvailableCount() {
    int innerVaultCount =
        (vaultItem as MultisigVaultListItem).signers.where((signer) => signer.innerVaultId != null).length;
    signAvailableCount =
        innerVaultCount > (vaultItem as MultisigVaultListItem).requiredSignatureCount
            ? (vaultItem as MultisigVaultListItem).requiredSignatureCount
            : innerVaultCount;
  }

  Future<void> updateOutsideVaultName(int signerIndex, String? name) async {
    if ((vaultItem as MultisigVaultListItem).signers[signerIndex].signerName != name) {
      await walletProvider.updateExternalSignerName(vaultItem.id, signerIndex, name);
      notifyListeners();
    }
  }

  Future<void> updateSignerSource(int signerIndex, SignerSource source) async {
    if ((vaultItem as MultisigVaultListItem).signers[signerIndex].signerSource != source) {
      await walletProvider.updateExternalSignerSource(vaultItem.id, signerIndex, source);
      notifyListeners();
    }
  }

  MultisigSigner getSignerInfo(int signerIndex) {
    return (vaultItem as MultisigVaultListItem).signers[signerIndex];
  }

  SingleSigVaultListItem getInnerVaultListItem(int index) {
    return (vaultItem as MultisigVaultListItem).signers[index] as SingleSigVaultListItem;
  }

  ///----------------------------------------------------
}
