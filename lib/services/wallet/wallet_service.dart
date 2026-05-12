import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/core/wallet/wallet_query_service.dart';
import 'package:coconut_vault/core/wallet/wallet_validator.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:flutter/foundation.dart';

const int kMaxFavoriteWallets = 5;

/// Orchestrates wallet-related use cases across repository (persistence),
/// lifecycle gating (TEE operations), user preferences (ordering, favorites),
/// and visibility tracking (wallet count).
///
/// Owns the [WalletRepository] and exposes [vaultSnapshot] so a UI adapter
/// (e.g. `WalletProvider`) can sync its own observable state after each call.
/// Does not perform UI notifications; callers handle their own `notifyListeners`.
class WalletService {
  final WalletRepository _repo;
  final WalletQueryService _query;
  final PreferenceProvider _pref;
  final AppLifecycleStateProvider _lifecycle;
  final VisibilityProvider _visibility;

  WalletService({
    required WalletRepository repo,
    required WalletQueryService query,
    required PreferenceProvider pref,
    required AppLifecycleStateProvider lifecycle,
    required VisibilityProvider visibility,
  }) : _repo = repo,
       _query = query,
       _pref = pref,
       _lifecycle = lifecycle,
       _visibility = visibility;

  /// Current authoritative snapshot from the repository.
  /// Adapters should re-read this after each mutating call to stay in sync.
  List<VaultListItemBase> get vaultSnapshot => _repo.vaultList ?? const [];

  // ---- create ----

  Future<SingleSigVaultListItem> addSinglesig(SingleSigWalletCreateDto wallet) async {
    // HardwareBackedKeystorePlugin.encrypt 내부에서 AUTH_NEEDED 에러 발생 시 생체인증 시도
    // 하지만 ios에서도 지갑 저장 중 라이프사이클 이벤트 호출로 중단되는 것을 방지하기 위해 operation 등록
    _lifecycle.startOperation(AppLifecycleOperations.hwBasedEncryption);
    try {
      wallet.name = _query.getUnduplicatedName(wallet.name!);
      final vault = await _repo.addSinglesigWallet(wallet);
      await _syncAfterAdd(vault.id);
      return vault;
    } finally {
      _lifecycle.endOperation(AppLifecycleOperations.hwBasedEncryption);
    }
  }

  Future<MultisigVaultListItem> addMultisig({
    required String name,
    required int color,
    required int icon,
    required List<MultisigSigner> signers,
    required int requiredSignatureCount,
    bool isImported = false,
  }) async {
    WalletValidator.validateSigners(signers);

    final sanitizedSigners = _query.sanitizeSignerMfp(signers);

    final vault = await _repo.addMultisigWallet(
      MultisigWallet(null, _query.getUnduplicatedName(name), icon, color, sanitizedSigners, requiredSignatureCount),
      shouldAttachInnerVaultMetadata: isImported,
    );
    await _syncAfterAdd(vault.id);
    return vault;
  }

  /// [details]로부터 멀티시그 지갑을 생성하며, 내부 단일서명 지갑(MFP 일치)을 자동으로 연결.
  /// [walletId]에 해당하는 내부 지갑이 연결되지 않으면 [NotRelatedMultisigWalletException] 발생.
  Future<MultisigVaultListItem> importMultisig(MultisigImportDetail details, int walletId) async {
    final multisigVault = MultisignatureVault.fromCoordinatorBsms(details.coordinatorBsms);

    // 내부 지갑 매칭 (MFP 기준)
    final linkedWalletList = List<SingleSigVaultListItem?>.filled(multisigVault.keyStoreList.length, null);
    bool isRelated = false;

    outerLoop:
    for (final wallet in vaultSnapshot) {
      if (wallet.vaultType == WalletType.multiSignature) continue;

      final singleSig = wallet as SingleSigVaultListItem;
      final walletMfp = (singleSig.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
      for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
        if (walletMfp == multisigVault.keyStoreList[i].masterFingerprint) {
          linkedWalletList[i] = wallet;
          if (singleSig.id == walletId) isRelated = true;
          continue outerLoop;
        }
      }
    }

    if (!isRelated) throw NotRelatedMultisigWalletException();

    // MultisigImportDetail + 내부 지갑 매칭 결과로 MultisigSigner 생성
    final signers = <MultisigSigner>[];
    for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
      final linked = linkedWalletList[i];
      if (linked == null) {
        // 외부 지갑
        signers.add(
          MultisigSigner(
            id: i,
            name: details.namesMap[multisigVault.keyStoreList[i].masterFingerprint],
            keyStore: multisigVault.keyStoreList[i],
          ),
        );
      } else {
        // 내부 지갑
        signers.add(
          MultisigSigner(
            id: i,
            innerVaultId: linked.id,
            keyStore: KeyStore.fromSignerBsms(linked.getSignerBsmsByAddressType(AddressType.p2wsh)),
            name: linked.name,
            iconIndex: linked.iconIndex,
            colorIndex: linked.colorIndex,
          ),
        );
      }
    }

    return addMultisig(
      name: details.name,
      color: details.colorIndex,
      icon: details.iconIndex,
      signers: signers,
      requiredSignatureCount: multisigVault.requiredSignature,
    );
  }

  Future<TaprootVaultListItem> addTaproot(TaprootWalletCreateDto wallet) async {
    // HardwareBackedKeystorePlugin.encrypt 내부에서 AUTH_NEEDED 에러 발생 시 생체인증 시도
    // 하지만 ios에서도 지갑 저장 중 라이프사이클 이벤트 호출로 중단되는 것을 방지하기 위해 operation 등록
    _lifecycle.startOperation(AppLifecycleOperations.hwBasedEncryption);
    try {
      wallet.name = _query.getUnduplicatedName(wallet.name!);
      final vault = await _repo.addTaprootWallet(wallet);
      await _syncAfterAdd(vault.id);
      return vault;
    } finally {
      _lifecycle.endOperation(AppLifecycleOperations.hwBasedEncryption);
    }
  }

  // ---- update ----

  Future<void> updateSinglesigAccount(int id, int newAccountIndex, {Uint8List? passphrase}) async {
    _lifecycle.startOperation(AppLifecycleOperations.hwBasedDecryption);
    try {
      await _repo.updateSingleSigAccountVault(id, newAccountIndex, inputPassphrase: passphrase);
    } finally {
      _lifecycle.endOperation(AppLifecycleOperations.hwBasedDecryption, delay: const Duration(milliseconds: 1500));
    }
  }

  Future<void> updateWallet(int id, String newName, int colorIndex, int iconIndex) async {
    await _repo.updateWallet(id, newName, colorIndex, iconIndex);
  }

  Future<VaultListItemBase> updateExternalSignerMemo(int id, int signerIndex, String? newMemo) {
    return _repo.updateExternalSignerMemo(id, signerIndex, newMemo);
  }

  Future<VaultListItemBase> updateExternalSignerSource(int id, int signerIndex, HardwareWalletType newSource) {
    return _repo.updateExternalSignerSource(id, signerIndex, newSource);
  }

  // ---- delete ----

  /// [id] 지갑 삭제 후 preferences 의 순서/즐겨찾기 목록에서도 제거.
  /// 실제 삭제 여부를 bool 로 반환.
  Future<bool> deleteWallet(int id) async {
    final existed = vaultSnapshot.indexWhere((e) => e.id == id) != -1;
    if (!existed) return false;

    final deleted = await _repo.deleteWallet(id);
    if (!deleted) return false;

    await _pref.removeVaultOrder(id);
    await _pref.removeFavoriteVaultId(id);
    await _visibility.saveWalletCount(vaultSnapshot.length);
    return true;
  }

  /// 인메모리 vault list와 모든 영속 데이터(SZR / FSS / SharedPrefs)를 정리합니다.
  ///
  /// repository가 정상 로드된 상태에서만 사용. repository 미준비 상태(앱 초기화 실패 등)에서는
  /// `WalletStorageCleaner.clearAll()`을 직접 호출하세요.
  Future<void> reset() async {
    await _repo.resetAll();
    await _visibility.saveWalletCount(0);
  }

  // ---- load ----

  /// 지갑 리스트를 스트리밍으로 로드. 각 지갑이 복원될 때마다 [onWallet] 호출.
  Future<void> loadVaults(void Function(VaultListItemBase wallet) onWallet) async {
    final jsonList = await _repo.loadVaultListJsonArrayString();
    if (jsonList != null) {
      await _repo.loadAndEmitEachWallet(jsonList, onWallet);
    }
  }

  // ---- secret / passphrase ----

  Future<Uint8List> getSecret(int id, {bool autoAuth = true}) async {
    // TEE 접근 시작 - inactive 상태 전환 무시
    _lifecycle.startOperation(AppLifecycleOperations.hwBasedDecryption);
    try {
      return await _repo.getSecret(id, autoAuth: autoAuth);
    } finally {
      // TEE 접근 완료 - inactive 상태 전환 허용
      // 작업 완료 후 지연을 두어 라이프사이클 이벤트와의 타이밍 조정
      _lifecycle.endOperation(AppLifecycleOperations.hwBasedDecryption, delay: const Duration(milliseconds: 1500));
    }
  }

  /// 서명 전용 모드 전용
  Future<Seed> getSeedInSigningOnlyMode(int id) async {
    _lifecycle.startOperation(AppLifecycleOperations.hwBasedDecryption);
    try {
      return await _repo.getSeedInSigningOnlyMode(id);
    } finally {
      _lifecycle.endOperation(AppLifecycleOperations.hwBasedDecryption, delay: const Duration(milliseconds: 1500));
    }
  }

  Future<bool> hasPassphrase(int walletId) => _repo.hasPassphrase(walletId);

  // ---- mode ----

  Future<void> updateIsSigningOnlyMode(bool isSigningOnlyMode) async {
    _lifecycle.startOperation(AppLifecycleOperations.hwBasedDecryption);
    try {
      await _repo.updateIsSigningOnlyMode(isSigningOnlyMode);
    } finally {
      _lifecycle.endOperation(AppLifecycleOperations.hwBasedDecryption);
    }
  }

  // ---- lifecycle ----

  void dispose() {
    _repo.dispose();
  }

  // ---- internal ----

  /// 지갑 추가 직후 preferences / favorites / visibility 동기화
  Future<void> _syncAfterAdd(int newWalletId) async {
    final ids = vaultSnapshot.map((e) => e.id).toList();
    await _pref.setVaultOrder(ids);
    await _addToFavoritesIfAvailable(newWalletId);
    await _visibility.saveWalletCount(vaultSnapshot.length);
  }

  /// 즐겨찾기된 지갑이 [kMaxFavoriteWallets] 개 미만이면 추가
  Future<void> _addToFavoritesIfAvailable(int walletId) async {
    final current = _pref.favoriteVaultIds;
    if (current.length >= kMaxFavoriteWallets || current.contains(walletId)) return;
    await _pref.setFavoriteVaultIds(<int>[...current, walletId]);
  }
}
