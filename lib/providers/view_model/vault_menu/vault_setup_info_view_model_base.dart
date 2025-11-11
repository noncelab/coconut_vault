import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

abstract class VaultSetupInfoViewModelBase<T extends VaultListItemBase> extends ChangeNotifier {
  final WalletProvider _walletProvider;
  @protected
  WalletProvider get walletProvider => _walletProvider;

  late final T _vaultListItem;

  T get vaultItem => _vaultListItem;
  String get name => _vaultListItem.name;
  int get colorIndex => _vaultListItem.colorIndex;
  int get iconIndex => _vaultListItem.iconIndex;
  DateTime get createdAt => _vaultListItem.createdAt;
  bool get isSigningOnlyMode => _walletProvider.isSigningOnlyMode;

  VaultSetupInfoViewModelBase(this._walletProvider, int id) {
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      _initializeVaultItem(id);
    } else {
      _setVaultListItem(id);
    }
  }

  /// vaultList가 로드되지 않았을 때 비동기로 초기화
  Future<void> _initializeVaultItem(int id) async {
    await _walletProvider.loadVaultList();
    _setVaultListItem(id);
  }

  void _setVaultListItem(int id) {
    _ensureVaultExists(id);
    _vaultListItem = _walletProvider.getVaultById(id) as T;
  }

  void _ensureVaultExists(int id) {
    final vaultExists = _walletProvider.vaultList.any((vault) => vault.id == id);
    if (!vaultExists) {
      throw StateError('Vault with id $id does not exist in the vault list.');
    }
  }

  Future<bool> updateVault(int id, String name, int colorIndex, int iconIndex) async {
    if (name == _vaultListItem.name &&
        colorIndex == _vaultListItem.colorIndex &&
        iconIndex == _vaultListItem.iconIndex) {
      return false;
    }

    if (name != _vaultListItem.name && _walletProvider.isNameDuplicated(name)) {
      return false;
    }

    await _walletProvider.updateVault(id, name, colorIndex, iconIndex);
    notifyListeners();
    return true;
  }

  Future<void> deleteVault() async {
    await _walletProvider.deleteWallet(_vaultListItem.id);
  }
}
