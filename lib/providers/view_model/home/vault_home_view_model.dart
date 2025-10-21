import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

class VaultHomeViewModel extends ChangeNotifier {
  late final AuthProvider _authProvider;
  late final WalletProvider _walletProvider;
  late final PreferenceProvider _preferenceProvider;
  late final int _initialVaultCount;

  VaultHomeViewModel(this._authProvider, this._walletProvider, this._preferenceProvider, this._initialVaultCount) {
    _walletProvider.addListener(_onWalletProviderUpdate);
    _walletProvider.vaultListNotifier.addListener(_onVaultListChanged);
    _favoriteVaultIds = _preferenceProvider.favoriteVaultIds;
    _preferenceProvider.addListener(_onPreferenceProviderUpdated);
  }

  List<int> _favoriteVaultIds = [];

  int get initialVaultCount => _initialVaultCount;
  bool get isPinSet => _authProvider.isPinSet;
  bool get isVaultInitialized => false;
  bool get isVaultsLoaded => _walletProvider.isVaultsLoaded;
  int get vaultCount => _walletProvider.vaultList.length;
  List<int> get favoriteVaultIds => _favoriteVaultIds;
  bool get isSigningOnlyMode => _preferenceProvider.isSigningOnlyMode;

  List<VaultListItemBase> get vaults {
    // 지갑 목록을 가져오고, 순서가 설정되어 있다면 그 순서대로 정렬
    // 홈에서는 즐겨찾기가 되어있는 지갑만 보여야 하기 때문에 필터링 작업도 수행
    final vaultList = _walletProvider.vaultListNotifier.value;
    final order = _preferenceProvider.vaultOrder;
    if (order.isEmpty) {
      return vaultList;
    }

    final vaultMap = {for (var vault in vaultList) vault.id: vault};
    var orderedMap = order.map((id) => vaultMap[id]).whereType<VaultListItemBase>().toList();
    return orderedMap;
  }

  @override
  void dispose() {
    _walletProvider.removeListener(_onWalletProviderUpdate);
    _walletProvider.vaultListNotifier.removeListener(_onVaultListChanged);
    _preferenceProvider.removeListener(_onPreferenceProviderUpdated);
    super.dispose();
  }

  Future<void> loadVaults() async {
    await _walletProvider.loadVaultList();
  }

  Future<bool> hasPassphrase(int id) async {
    return await _walletProvider.hasPassphrase(id);
  }

  void _onWalletProviderUpdate() {
    notifyListeners();
  }

  void _onVaultListChanged() {
    notifyListeners();
  }

  void _onPreferenceProviderUpdated() {
    /// 지갑 즐겨찾기 변동 체크
    if (favoriteVaultIds.toString() != _preferenceProvider.favoriteVaultIds.toString() && vaults.isNotEmpty) {
      loadFavoriteVaults();
    }

    notifyListeners();
  }

  Future<void> loadFavoriteVaults() async {
    if (_walletProvider.vaultList.isEmpty) return;

    final ids = _preferenceProvider.favoriteVaultIds;

    final vaults =
        ids
            .map((id) => _walletProvider.vaultListNotifier.value.firstWhereOrNull((w) => w.id == id))
            .whereType<VaultListItemBase>()
            .toList();

    _favoriteVaultIds = vaults.map((v) => v.id).toList();
    notifyListeners();
  }
}
