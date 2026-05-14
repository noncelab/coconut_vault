import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/core/wallet/wallet_query_service.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_key_identifier.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/services/wallet/wallet_service.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

class WalletProvider extends ChangeNotifier {
  // 1) DI / 협력자
  late final WalletService _service;
  late final WalletQueryService _query;

  // 2) 생성자
  WalletProvider(VisibilityProvider visibility, PreferenceProvider preference, AppLifecycleStateProvider lifecycle) {
    _isSigningOnlyMode = preference.isSigningOnlyMode;
    final repo = WalletRepository(isSigningOnlyMode: _isSigningOnlyMode);
    _query = WalletQueryService(() => _vaultList);
    _service = WalletService(repo: repo, query: _query, pref: preference, lifecycle: lifecycle, visibility: visibility);

    if (_isSigningOnlyMode) {
      _service.reset();
    }
    vaultListNotifier = ValueNotifier(_vaultList);
  }

  // 3) 상태 필드
  List<VaultListItemBase> _vaultList = [];
  // 리스트 로딩중 여부 (indicator 표시 및 중복 방지)
  bool _isVaultListLoading = false;
  // vault_type_selection_screen, vault_name_and_icon_setup_screen, app_update_preparation_screen 에서 사용
  // 다음 버튼 클릭시 loadVaultList()가 아직 진행중인 경우 완료 시점을 캐치하기 위함
  final ValueNotifier<bool> isVaultListLoadingNotifier = ValueNotifier<bool>(false);
  // 리스트 로딩 완료 여부 (로딩작업 완료 후 바로 추가하기 표시)
  // 최초 한번 완료 후 재로드 없음
  bool _isVaultsLoaded = false;
  late final ValueNotifier<List<VaultListItemBase>> vaultListNotifier;
  bool _isDisposed = false;
  late bool _isSigningOnlyMode;

  // 4) Getter
  List<VaultListItemBase> get vaultList => vaultListNotifier.value;
  bool get isVaultListLoading => _isVaultListLoading;
  bool get isVaultsLoaded => _isVaultsLoaded;
  bool get isSigningOnlyMode => _isSigningOnlyMode;

  // 5-1) Query (WalletQueryService 위임)
  /// SinglesigVaultListItem의 seed 중복 여부 확인
  bool isSeedDuplicated(Uint8List secret, Uint8List passphrase) => _query.isSeedDuplicated(secret, passphrase);

  bool isNameDuplicated(String name) => _query.isNameDuplicated(name);

  MultisigVaultListItem? findSameMultisigWallet(NormalizedMultisigConfig config) =>
      _query.findSameMultisigWallet(config);

  /// MultisigVaultListItem의 coordinatorBsms 중복 여부 확인
  MultisigVaultListItem? findMultisigWalletByCoordinatorBsms(String coordinatorBsms) =>
      _query.findMultisigWalletByCoordinatorBsms(coordinatorBsms);

  VaultListItemBase? findWalletByDescriptor(String descriptor) => _query.findWalletByDescriptor(descriptor);

  // 5-2) 퍼블릭 메서드
  // Returns a copy of the list of vault list.
  List<VaultListItemBase> getVaults() {
    if (_vaultList.isEmpty) return [];
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

  Future<SingleSigVaultListItem> addSingleSigVault(SingleSigWalletCreateDto wallet) async {
    final vault = await _service.addSinglesig(wallet);
    _setVaultList(_service.vaultSnapshot);
    notifyListeners();
    return vault;
  }

  Future<MultisigVaultListItem> addMultisigVault(
    String name,
    int color,
    int icon,
    List<MultisigSigner> signers,
    int requiredSignatureCount, {
    bool isImported = false,
  }) async {
    final vault = await _service.addMultisig(
      name: name,
      color: color,
      icon: icon,
      signers: signers,
      requiredSignatureCount: requiredSignatureCount,
      isImported: isImported,
    );
    _setVaultList(_service.vaultSnapshot);
    notifyListeners();
    return vault;
  }

  Future<MultisigVaultListItem> importMultisigVault(MultisigImportDetail details, int walletId) async {
    final vault = await _service.importMultisig(details, walletId);
    _setVaultList(_service.vaultSnapshot);
    notifyListeners();
    return vault;
  }

  // TODO: TaprootWalletCreateDto 매개변수 넘겨준 곳에서 wipe 호출
  Future<TaprootVaultListItem> addTaprootVault(TaprootWalletCreateDto wallet) async {
    final vault = await _service.addTaproot(wallet);
    _setVaultList(_service.vaultSnapshot);
    notifyListeners();
    return vault;
  }

  Future<bool> hasPassphrase(int walletId) => _service.hasPassphrase(walletId);

  Future<void> updateSingleSigAccount(int id, int newAccountIndex, {Uint8List? passphrase}) async {
    try {
      await _service.updateSinglesigAccount(id, newAccountIndex, passphrase: passphrase);
      _setVaultList(List.from(_service.vaultSnapshot));

      Future.microtask(() {
        if (!_isDisposed) notifyListeners();
      });
    } catch (e) {
      Logger.error('[WalletProvider] updateSingleSigAccount error: $e');
      rethrow;
    }
  }

  /// [id]에 해당하는 지갑의 UI 정보 업데이트
  Future<void> updateVault(int id, String newName, int colorIndex, int iconIndex) async {
    await _service.updateWallet(id, newName, colorIndex, iconIndex);
    _setVaultList(_service.vaultSnapshot);
    notifyListeners();
  }

  /// 다중서명 지갑의 [signerIndex]번째 키로 사용한 외부 지갑의 이름을 업데이트
  Future updateExternalSignerMemo(int id, int signerIndex, String? newMemo) async {
    final index = _vaultList.indexWhere((wallet) => wallet.id == id);
    _vaultList[index] = await _service.updateExternalSignerMemo(id, signerIndex, newMemo);
  }

  /// 다중서명 지갑의 [signerIndex]번째 키로 사용한 외부 지갑의 출처를 업데이트
  Future updateExternalSignerSource(int id, int signerIndex, HardwareWalletType newSignerSource) async {
    final index = _vaultList.indexWhere((wallet) => wallet.id == id);
    _vaultList[index] = await _service.updateExternalSignerSource(id, signerIndex, newSignerSource);
  }

  Future<void> deleteWallet(int id) async {
    final deleted = await _service.deleteWallet(id);
    if (!deleted) return;
    _setVaultList(_service.vaultSnapshot);
    notifyListeners();
  }

  /// 모든 wallet 데이터(인메모리 + 영속)를 정리합니다.
  Future<void> reset() async {
    await _service.reset();
    _setVaultList(_service.vaultSnapshot);
    notifyListeners();
  }

  Future<void> loadVaultList() async {
    if (_isVaultListLoading) return;

    _isVaultListLoading = true;
    isVaultListLoadingNotifier.value = true;
    notifyListeners();

    try {
      _vaultList.clear();
      _setVaultList([]);

      await _service.loadVaults((wallet) {
        if (_isDisposed) return;
        _vaultList.add(wallet);
        notifyListeners();
      });

      if (_isDisposed) return;
      _isVaultsLoaded = true;
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
      notifyListeners();
    }
  }

  // TODO: rename to 'getSingleSigSecret'
  Future<Uint8List> getSecret(int id, {bool autoAuth = true}) => _service.getSingleSigSecret(id, autoAuth: autoAuth);

  // 서명 전용 모드
  // TODO: rename to 'getSingleSigSeedInSigningOnlyMode'
  Future<Seed> getSeedInSigningOnlyMode(int id) => _service.getSingleSigSeedInSigningOnlyMode(id);

  Future<Uint8List> getTaprootSecret(int id, TaprootSeedKeyIdentifier seedIdentifier, {bool autoAuth = true}) =>
      _service.getTaprootSecret(id, seedIdentifier, autoAuth: autoAuth);

  // 서명 전용 모드
  Future<Seed> getTaprootSeedInSigningOnlyMode(int id, TaprootSeedKeyIdentifier seedIdentifier) =>
      _service.getTaprootSeedInSigningOnlyMode(id, seedIdentifier);

  Future<void> updateIsSigningOnlyMode(bool isSigningOnlyMode) async {
    if (_isSigningOnlyMode == isSigningOnlyMode) return;
    await _service.updateIsSigningOnlyMode(isSigningOnlyMode);
    if (isSigningOnlyMode) {
      _setVaultList([]);
    }
    _isSigningOnlyMode = isSigningOnlyMode;
    notifyListeners();
  }

  Future<void> reloadRelatedToVault() async {
    _isVaultListLoading = false;
    _isVaultsLoaded = false;
    await loadVaultList();
  }

  // 6) 프라이빗 메서드
  void _setVaultList(List<VaultListItemBase> value) {
    _vaultList = value;
    vaultListNotifier.value = value;
  }

  // 7) 오버라이드/생명주기
  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _service.dispose();
    _vaultList.clear();
    super.dispose();
  }
}
