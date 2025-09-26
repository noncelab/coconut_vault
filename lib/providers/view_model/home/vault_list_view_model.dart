import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

class VaultListViewModel extends ChangeNotifier {
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> pinCheckNotifier = ValueNotifier(false);
  late final AuthProvider _authProvider;
  late final WalletProvider _walletProvider;
  late final int _initialVaultCount;
  late final PreferenceProvider _preferenceProvider;

  VaultListViewModel(this._authProvider, this._walletProvider, this._preferenceProvider, this._initialVaultCount) {
    _vaultOrder = List.from(_preferenceProvider.vaultOrder);
    _favoriteVaultIds = List.from(_preferenceProvider.favoriteVaultIds);
    _preferenceProvider.addListener(_onPreferenceChanged);
  }

  int get initialVaultCount => _initialVaultCount;
  bool get isPinSet => _authProvider.isPinSet;
  bool get isVaultsLoaded => _walletProvider.isVaultsLoaded;
  int get vaultCount => _walletProvider.vaultList.length;

  late List<int> _vaultOrder = [];
  List<int> get vaultOrder => _vaultOrder;
  // 임시 지갑 순서 ID 목록(편집용)
  List<int> tempVaultOrder = [];

  late List<int> _favoriteVaultIds = [];
  List<int> get favoriteVaultIds => _favoriteVaultIds;
  // 임시 즐겨찾기 지갑 ID 목록(편집용)
  List<int> tempFavoriteVaultIds = [];

  List<VaultListItemBase> get vaults {
    final vaultList = _walletProvider.vaultList;
    final order = _preferenceProvider.vaultOrder;

    if (order.isEmpty) {
      return vaultList;
    }

    final vaultMap = {for (var vault in vaultList) vault.id: vault};
    var orderedMap = order.map((id) => vaultMap[id]).whereType<VaultListItemBase>().toList();
    return orderedMap;
  }

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  bool get hasFavoriteChanged =>
      !const SetEquality().equals(tempFavoriteVaultIds.toSet(), _preferenceProvider.favoriteVaultIds.toSet());

  bool get hasVaultOrderChanged => !const ListEquality().equals(tempVaultOrder, _preferenceProvider.vaultOrder);

  void reorderTempVaultOrder(int oldIndex, int newIndex) {
    final item = tempVaultOrder.removeAt(oldIndex);
    tempVaultOrder.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    notifyListeners();
  }

  void removeTempWalletOrderByWalletId(int vaultId) async {
    final orderIndex = tempVaultOrder.indexOf(vaultId);
    final starIndex = tempFavoriteVaultIds.indexOf(vaultId);
    if (orderIndex != -1) {
      tempVaultOrder.removeAt(orderIndex);
    }
    if (starIndex != -1) {
      tempFavoriteVaultIds.removeAt(starIndex);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _preferenceProvider.removeListener(_onPreferenceChanged);
    super.dispose();
  }

  void _onPreferenceChanged() {
    onPreferenceProviderUpdated();
  }

  void loadVaults() {
    _walletProvider.loadVaultList();
  }

  // void onWalletProviderUpdated(WalletProvider walletProvider) {
  //   _walletProvider = walletProvider;
  //   notifyListeners();
  // }

  void onPreferenceProviderUpdated() {
    /// 지갑 순서 변경 체크
    if (!const ListEquality().equals(_vaultOrder, _preferenceProvider.vaultOrder)) {
      _vaultOrder = _preferenceProvider.vaultOrder;
    }

    notifyListeners();
  }

  void setEditMode(bool isEditMode) {
    _isEditMode = isEditMode;
    if (isEditMode) {
      // 최신 favoriteVaultIds PreferenceProvider에서 다시 읽어옴
      _favoriteVaultIds = List.from(_preferenceProvider.favoriteVaultIds);

      tempFavoriteVaultIds = vaults.where((w) => favoriteVaultIds.contains(w.id)).map((w) => w.id).toList();

      tempVaultOrder = vaults.map((w) => w.id).toList();
    }
    notifyListeners();
  }

  VoidCallback? _pendingAuthCompleteCallback;

  Future<void> _handleAuthFlow({required VoidCallback onComplete, required bool hasVaultDeleted}) async {
    if (!hasVaultDeleted) {
      // 지갑이 삭제된 경우가 아니라면 pinCheck 생략
      onComplete();
      return;
    }
    if (!_authProvider.isPinSet) {
      onComplete();
      return;
    }

    if (await _authProvider.isBiometricsAuthValid()) {
      onComplete();
      return;
    }

    _pendingAuthCompleteCallback = onComplete;
    setPincheckNotifier(true);
    notifyListeners();
  }

  void handleAuthCompletion() {
    if (_pendingAuthCompleteCallback != null) {
      _pendingAuthCompleteCallback!();
      _pendingAuthCompleteCallback = null;
    }
  }

  void setPincheckNotifier(bool value) {
    pinCheckNotifier.value = value;
  }

  void toggleTempFavorite(int vaultId) {
    if (tempFavoriteVaultIds.contains(vaultId)) {
      tempFavoriteVaultIds = List.from(tempFavoriteVaultIds)..remove(vaultId);
    } else {
      if (tempFavoriteVaultIds.length < 5) {
        tempFavoriteVaultIds = List.from(tempFavoriteVaultIds)..add(vaultId);
      }
    }
    notifyListeners();
  }

  /// 임시값을 실제 vaultList에 반영
  Future<void> applyTempDatasToVaults() async {
    if (!hasVaultOrderChanged && !hasFavoriteChanged) return;

    // 삭제 예정 지갑 목록
    // 삭제 예정 지갑에 키로 사용된 SingleSigVaultListItem 이 있는 경우 연결된 MultisigVaultListItem 이 먼저 삭제되어야 하기 때문에 정렬
    final deletedVaultIds =
        _preferenceProvider.vaultOrder.where((id) => !tempVaultOrder.contains(id)).toList()..sort((a, b) {
          final aIsMultisig = _walletProvider.vaultListNotifier.value.any(
            (v) => v.id == a && v.vaultType == WalletType.multiSignature,
          );
          final bIsMultisig = _walletProvider.vaultListNotifier.value.any(
            (v) => v.id == b && v.vaultType == WalletType.multiSignature,
          );
          if (aIsMultisig == bIsMultisig) return 0;
          return aIsMultisig ? -1 : 1;
        });

    await _handleAuthFlow(
      onComplete: () async {
        if (hasVaultOrderChanged) {
          // 삭제 여부 판단
          if (tempVaultOrder.length != _preferenceProvider.vaultOrder.length) {
            setLoadingNotifier(true);

            await _deleteVaults(deletedVaultIds);
            setLoadingNotifier(false);
          }
          await _preferenceProvider.setVaultOrder(tempVaultOrder);

          final vaultMap = {for (var vault in vaults) vault.id: vault};
          _walletProvider.vaultListNotifier.value =
              tempVaultOrder.map((id) => vaultMap[id]).whereType<VaultListItemBase>().toList();
        }
        if (hasFavoriteChanged) {
          await _preferenceProvider.setFavoriteVaultIds(tempFavoriteVaultIds);
          _favoriteVaultIds = _preferenceProvider.favoriteVaultIds;
        }
        setEditMode(false);
        notifyListeners();
      },
      hasVaultDeleted: deletedVaultIds.isNotEmpty,
    );
  }

  Future<void> _deleteVaults(List<int> deletedVaultIds) async {
    debugPrint('deletedVaultIds: $deletedVaultIds');

    for (int i = 0; i < deletedVaultIds.length; i++) {
      int vaultId = deletedVaultIds[i];
      debugPrint('[delete] vaultId: $vaultId');
      debugPrint(
        '[delete] vaultsType: ${_walletProvider.vaultListNotifier.value.firstWhere((v) => v.id == vaultId).vaultType}',
      );
      await _walletProvider.deleteWallet(vaultId);
    }
    _walletProvider.notifyListeners();
  }

  void setLoadingNotifier(bool value) {
    loadingNotifier.value = value;
  }
}
