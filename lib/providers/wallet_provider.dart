import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:flutter/foundation.dart';

const kMaxStarLength = 5;

class WalletProvider extends ChangeNotifier {
  static List<AddressType> allowedMultisigAddressTypes = [AddressType.p2wsh];

  // 1) DI
  late final VisibilityProvider _visibilityProvider;
  late final WalletRepository _walletRepository;
  late final PreferenceProvider _preferenceProvider;
  late final AppLifecycleStateProvider _lifecycleProvider;

  // 2) 생성자
  WalletProvider(this._visibilityProvider, this._preferenceProvider, this._lifecycleProvider) {
    _isSigningOnlyMode = _preferenceProvider.isSigningOnlyMode;
    _walletRepository = WalletRepository(isSigningOnlyMode: _isSigningOnlyMode);

    if (_isSigningOnlyMode) {
      _walletRepository.resetAll();
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
  bool _isAddVaultCompleted = false;
  bool _isDisposed = false;
  late bool _isSigningOnlyMode;

  // 4) Getter
  List<VaultListItemBase> get vaultList => vaultListNotifier.value;
  bool get isVaultListLoading => _isVaultListLoading;
  bool get isVaultsLoaded => _isVaultsLoaded;
  bool get isAddVaultCompleted => _isAddVaultCompleted;
  bool get isSigningOnlyMode => _isSigningOnlyMode;

  // 5) 퍼블릭 메서드
  // Returns a copy of the list of vault list.
  List<VaultListItemBase> getVaults() {
    if (_vaultList.isEmpty) {
      return [];
    }

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
    _setAddVaultCompleted(false);

    // HardwareBackedKeystorePlugin.encrypt 내부에서 AUTH_NEEDED 에러 발생 시 생체인증 시도
    // 하지만 ios에서도 지갑 저장 중 라이프사이클 이벤트 호출로 중단되는 것을 방지하기 위해 operation 등록
    _lifecycleProvider.startOperation(AppLifecycleOperations.hwBasedEncryption);
    wallet.name = _getUnduplicatedName(wallet.name!);
    final vault = await _walletRepository.addSinglesigWallet(wallet);
    _setVaultList(_walletRepository.vaultList);
    await _preferenceProvider.setVaultOrder(_vaultList.map((e) => e.id).toList());
    _addToFavoriteWalletsIfAvailable(_vaultList.last.id);

    _setAddVaultCompleted(true);
    await _updateWalletLength();
    _lifecycleProvider.endOperation(AppLifecycleOperations.hwBasedEncryption);
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
    _setAddVaultCompleted(false);

    validateSigners(signers);

    final vault = await _walletRepository.addMultisigWallet(
      MultisigWallet(null, _getUnduplicatedName(name), icon, color, signers, requiredSignatureCount),
      shouldAttachInnerVaultMetadata: isImported,
    );
    _setVaultList(_walletRepository.vaultList);
    _preferenceProvider.setVaultOrder(_vaultList.map((e) => e.id).toList());
    _addToFavoriteWalletsIfAvailable(_vaultList.last.id);
    _setAddVaultCompleted(true);
    await _updateWalletLength();
    notifyListeners();
    return vault;
  }

  void validateSigners(List<MultisigSigner> signers) {
    String? firstPath;
    for (var signer in signers) {
      if (signer.signerBsms == null) ArgumentError('signerBsms is null');

      final signerBsms = SignerBsms.parse(signer.signerBsms!);
      final splitedPath = signerBsms.derivationPath.split('/');
      // purpose Index check
      try {
        final purposeIndex = int.parse(splitedPath[0].split("'")[0]);
        final isAllowedPurpose = allowedMultisigAddressTypes.any((addressType) {
          return addressType.purposeIndex == purposeIndex;
        });
        if (!isAllowedPurpose) {
          throw FormatException('Signer purpose index is not allowed : ${signerBsms.derivationPath}');
        }

        // coinType check
        final coinType = int.parse(splitedPath[1].split("'")[0]);
        final isAllowedCoinType = NetworkType.currentNetworkType.isTestnet ? coinType == 1 : coinType == 0;
        if (!isAllowedCoinType) {
          throw NetworkMismatchException(
            message:
                NetworkType.currentNetworkType.isTestnet
                    ? t.alert.bsms_network_mismatch.description_when_testnet
                    : t.alert.bsms_network_mismatch.description_when_mainnet,
          );
        }
      } catch (e) {
        if (e is Exception) rethrow;
        throw ArgumentError('Invalid derivation path: ${signerBsms.derivationPath} ${e.toString()}');
      }

      // path consistency check
      if (firstPath == null) {
        firstPath = signerBsms.derivationPath;
      } else {
        if (firstPath != signerBsms.derivationPath) {
          throw FormatException('Signer derivation path is not consistent : ${signerBsms.derivationPath}');
        }
      }
    }
  }

  Future<bool> hasPassphrase(int walletId) async {
    return await _walletRepository.hasPassphrase(walletId);
  }

  Future<MultisigVaultListItem> importMultisigVault(MultisigImportDetail details, int walletId) async {
    _setAddVaultCompleted(false);

    // 이 지갑이 위 멀티시그 지갑의 일부인지 확인하기
    MultisignatureVault multisigVault = MultisignatureVault.fromCoordinatorBsms(details.coordinatorBsms);

    // 중복 코드 확인
    List<SingleSigVaultListItem?> linkedWalletList = [];
    linkedWalletList.insertAll(0, List.filled(multisigVault.keyStoreList.length, null));
    bool isRelated = false;
    outerLoop:
    for (var wallet in _vaultList) {
      if (wallet.vaultType == WalletType.multiSignature) continue;

      var singleSigVaultListItem = wallet as SingleSigVaultListItem;
      var walletMfp = (singleSigVaultListItem.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
      for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
        if (walletMfp == multisigVault.keyStoreList[i].masterFingerprint) {
          linkedWalletList[i] = wallet;
          if (singleSigVaultListItem.id == walletId) {
            isRelated = true;
          }
          continue outerLoop;
        }
      }
    }

    if (!isRelated) {
      throw NotRelatedMultisigWalletException();
    }

    // MultisigImportDetail + vaultList를 이용하여 List<MultisigSigner>를 생성
    List<MultisigSigner> signers = [];
    for (int i = 0; i < multisigVault.keyStoreList.length; i++) {
      // 외부 지갑
      if (linkedWalletList[i] == null) {
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
            innerVaultId: linkedWalletList[i]!.id,
            keyStore: KeyStore.fromSignerBsms(linkedWalletList[i]!.getSignerBsmsByAddressType(AddressType.p2wsh)),
            name: linkedWalletList[i]!.name,
            iconIndex: linkedWalletList[i]!.iconIndex,
            colorIndex: linkedWalletList[i]!.colorIndex,
          ),
        );
      }
    }

    final vault = await addMultisigVault(
      details.name,
      details.colorIndex,
      details.iconIndex,
      signers,
      multisigVault.requiredSignature,
    );

    _setAddVaultCompleted(true);
    notifyListeners();
    return vault;
  }

  /// [id]에 해당하는 지갑의 UI 정보 업데이트
  Future<void> updateVault(int id, String newName, int colorIndex, int iconIndex) async {
    await _walletRepository.updateWallet(id, newName, colorIndex, iconIndex);
    _setVaultList(_walletRepository.vaultList);
    notifyListeners();
  }

  /// 다중서명 지갑의 [singerIndex]번째 키로 사용한 외부 지갑의 이름을 업데이트
  Future updateExternalSignerMemo(int id, int signerIndex, String? newMemo) async {
    int index = _vaultList.indexWhere((wallet) => wallet.id == id);
    _vaultList[index] = await _walletRepository.updateExternalSignerMemo(id, signerIndex, newMemo);
  }

  /// 다중서명 지갑의 [singerIndex]번째 키로 사용한 외부 지갑의 출처를 업데이트
  Future updateExternalSignerSource(int id, int signerIndex, HardwareWalletType newSignerSource) async {
    int index = _vaultList.indexWhere((wallet) => wallet.id == id);
    _vaultList[index] = await _walletRepository.updateExternalSignerSource(id, signerIndex, newSignerSource);
  }

  /// SiglesigVaultListItem의 seed 중복 여부 확인
  bool isSeedDuplicated(Uint8List secret, Uint8List passphrase) {
    var coconutVault = SingleSignatureVault.fromMnemonic(
      secret,
      addressType: AddressType.p2wpkh,
      passphrase: passphrase,
    );
    final vaultIndex = _vaultList.indexWhere((element) {
      if (element is SingleSigVaultListItem) {
        return (element.coconutVault as SingleSignatureVault).descriptor == coconutVault.descriptor;
      }

      return false;
    });

    return vaultIndex != -1;
  }

  MultisigVaultListItem? findSameMultisigWallet(NormalizedMultisigConfig config) {
    final vaultIndex = _vaultList.indexWhere((element) {
      if (element is SingleSigVaultListItem) return false;
      final wallet = element as MultisigVaultListItem;
      return wallet.requiredSignatureCount == config.requiredCount &&
          wallet.signers.length == config.totalSigners &&
          setEquals(wallet.signerFingerprints, config.signerFingerprints);
    });

    return vaultIndex != -1 ? _vaultList[vaultIndex] as MultisigVaultListItem : null;
  }

  /// MultisigVaultListItem의 coordinatorBsms 중복 여부 확인
  MultisigVaultListItem? findMultisigWalletByCoordinatorBsms(String coordinatorBsms) {
    final vaultIndex = _vaultList.indexWhere((element) {
      return (element is MultisigVaultListItem && element.coordinatorBsms == coordinatorBsms);
    });

    return vaultIndex != -1 ? _vaultList[vaultIndex] as MultisigVaultListItem : null;
  }

  VaultListItemBase? findWalletByDescriptor(String descriptor) {
    final vaultIndex = _vaultList.indexWhere((element) => element.coconutVault.descriptor == descriptor);

    return vaultIndex != -1 ? _vaultList[vaultIndex] : null;
  }

  bool isNameDuplicated(String name) {
    final vaultIndex = _vaultList.indexWhere((element) => element.name == name);

    return vaultIndex != -1;
  }

  Future<void> deleteWallet(int id) async {
    if (await _walletRepository.deleteWallet(id)) {
      _setVaultList(_walletRepository.vaultList);
      await _preferenceProvider.removeVaultOrder(id);
      await _preferenceProvider.removeFavoriteVaultId(id);
      notifyListeners();
      _updateWalletLength();
    }
  }

  Future<void> deleteAllWallets() async {
    await _walletRepository.deleteWallets();
    _setVaultList(_walletRepository.vaultList);
    notifyListeners();
    _updateWalletLength();
  }

  Future<void> loadVaultList() async {
    if (_isVaultListLoading) return;

    _isVaultListLoading = true;
    isVaultListLoadingNotifier.value = true;
    notifyListeners();

    try {
      _vaultList.clear();
      _setVaultList([]);

      // []일 때도 null이 반환됨. []가 반환되는 경우가 없음
      final jsonList = await _walletRepository.loadVaultListJsonArrayString();
      if (jsonList != null) {
        await _walletRepository.loadAndEmitEachWallet(jsonList, (VaultListItemBase wallet) {
          if (_isDisposed) {
            return;
          }
          _vaultList.add(wallet);
          notifyListeners();
        });
      }

      if (_isDisposed) {
        return;
      }

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
    return;
  }

  Future<Uint8List> getSecret(int id, {bool autoAuth = true}) async {
    // TEE 접근 시작 - inactive 상태 전환 무시
    _lifecycleProvider.startOperation(AppLifecycleOperations.hwBasedDecryption);
    try {
      final result = await _walletRepository.getSecret(id, autoAuth: autoAuth);

      return result;
    } finally {
      // TEE 접근 완료 - inactive 상태 전환 허용
      // 작업 완료 후 지연을 두어 라이프사이클 이벤트와의 타이밍 조정
      await Future.delayed(const Duration(milliseconds: 500));
      _lifecycleProvider.endOperation(AppLifecycleOperations.hwBasedDecryption);
    }
  }

  // 서명 전용 모드
  Future<Seed> getSeedInSigningOnlyMode(int id) async {
    _lifecycleProvider.startOperation(AppLifecycleOperations.hwBasedDecryption);
    try {
      return await _walletRepository.getSeedInSigningOnlyMode(id);
    } finally {
      // TEE 접근 완료 - inactive 상태 전환 허용
      // 작업 완료 후 지연을 두어 라이프사이클 이벤트와의 타이밍 조정
      await Future.delayed(const Duration(milliseconds: 500));
      _lifecycleProvider.endOperation(AppLifecycleOperations.hwBasedDecryption);
    }
  }

  Future<void> updateIsSigningOnlyMode(bool isSigningOnlyMode) async {
    if (_isSigningOnlyMode == isSigningOnlyMode) return;
    _lifecycleProvider.startOperation(AppLifecycleOperations.hwBasedDecryption);
    await _walletRepository.updateIsSigningOnlyMode(isSigningOnlyMode);
    _lifecycleProvider.endOperation(AppLifecycleOperations.hwBasedDecryption);
    if (isSigningOnlyMode) {
      _setVaultList([]);
    }
    _isSigningOnlyMode = isSigningOnlyMode;
    notifyListeners();
  }

  // 6) 프라이빗 메서드
  void _setVaultList(List<VaultListItemBase> value) {
    _vaultList = value;
    vaultListNotifier.value = value;
  }

  Future<void> _addToFavoriteWalletsIfAvailable(int walletId) async {
    final currentIds = _preferenceProvider.favoriteVaultIds;

    // 즐겨찾기된 지갑이 5개이상이면 등록안함
    if (currentIds.length >= kMaxStarLength || currentIds.contains(walletId)) return;

    final updateIds = <int>[...currentIds, walletId];
    await _preferenceProvider.setFavoriteVaultIds(updateIds);
  }

  void _setAddVaultCompleted(bool value) {
    _isAddVaultCompleted = value;
    notifyListeners();
  }

  Future<void> _updateWalletLength() async {
    await _visibilityProvider.saveWalletCount(_vaultList.length);
  }

  /// 이름 중복이면 겹치지 않게 숫자 접미사를 붙여서 반환
  String _getUnduplicatedName(String name) {
    String target = name.trim();
    int count = 2;
    while (isNameDuplicated(target)) {
      target = '$name $count';
      count++;
    }
    return target;
  }

  // 7) 오버라이드/생명주기
  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    // stop if loading
    _walletRepository.dispose();

    _vaultList.clear();
    super.dispose();
  }
}
