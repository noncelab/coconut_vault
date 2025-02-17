import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';

class VaultListViewModel extends ChangeNotifier {
  late final AuthProvider _authProvider;
  late final WalletProvider _walletProvider;
  late final VisibilityProvider _visibilityProvider;

  VaultListViewModel(this._authProvider);

  bool get isVaultInitialized => false;
  bool get isWalletLoadDone => false;
  bool get isPinSet => _authProvider.isPinSet;
  bool get isLoadWalletsDone => _walletProvider.isLoadWalletsDone;

  int get walletCount => _visibilityProvider.walletCount;
}
