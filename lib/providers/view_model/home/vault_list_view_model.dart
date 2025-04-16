import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';

class VaultListViewModel extends ChangeNotifier {
  late final AuthProvider _authProvider;
  late final WalletProvider _walletProvider;
  late final int _initialWalletCount;

  VaultListViewModel(this._authProvider, this._walletProvider, this._initialWalletCount) {
    _walletProvider.addListener(_onWalletProviderUpdate);
  }

  int get initialWalletCount => _initialWalletCount;
  bool get isPinSet => _authProvider.isPinSet;
  bool get isVaultInitialized => false;
  bool get isWalletsLoaded => _walletProvider.isWalletsLoaded;
  int get walletCount => _walletProvider.vaultList.length;

  List<VaultListItemBase> get wallets => _walletProvider.getVaults();

  @override
  void dispose() {
    _walletProvider.removeListener(_onWalletProviderUpdate);
    super.dispose();
  }

  void loadWallets() {
    _walletProvider.loadVaultList();
  }

  void _onWalletProviderUpdate() {
    notifyListeners();
  }
}
