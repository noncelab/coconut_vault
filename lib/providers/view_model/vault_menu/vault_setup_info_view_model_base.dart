import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

abstract class VaultSetupInfoViewModelBase<T extends VaultListItemBase> extends ChangeNotifier {
  final WalletProvider _walletProvider;
  @protected
  WalletProvider get walletProvider => _walletProvider;

  T? _vaultListItem;
  bool _isInitialized = false;

  T get vaultItem {
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

  VaultSetupInfoViewModelBase(this._walletProvider, int id) {
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      _initializeVaultItem(id);
    } else {
      _setVaultListItem(id);
      _isInitialized = true;
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
    _vaultListItem = _walletProvider.getVaultById(id) as T;
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
}
