import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

abstract class VaultSetupInfoViewModelBase<T extends VaultListItemBase>
    extends ChangeNotifier {
  final WalletProvider _walletProvider;
  @protected
  WalletProvider get walletProvider => _walletProvider;

  late final T _vaultListItem;

  T get vaultItem => _vaultListItem;
  String get name => _vaultListItem.name;
  int get colorIndex => _vaultListItem.colorIndex;
  int get iconIndex => _vaultListItem.iconIndex;

  VaultSetupInfoViewModelBase(this._walletProvider, int id) {
    _vaultListItem = _walletProvider.getVaultById(id) as T;
  }

  Future<bool> updateVault(
      int id, String name, int colorIndex, int iconIndex) async {
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
    await _walletProvider.deleteOne(_vaultListItem.id);
  }
}
