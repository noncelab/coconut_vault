import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/coconut/extended_pubkey_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SignerAssignmentViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  final WalletCreationProvider _walletCreationProvider;

  late int _totalSignatureCount; // 전체 키의 수
  late int _requiredSignatureCount; // 필요한 서명 수
  late List<AssignedVaultListItem> _assignedVaultList; // 키 가져오기에서 선택 완료한 객체
  late List<SingleSigVaultListItem> _singlesigVaultList;
  late List<SignerOption> _signerOptions;
  late List<SignerOption> _unselectedSignerOptions;
  // 내부 지갑 중 Signer 선택하는 순간에만 사용함
  String _loadingMessage = '';
  MultisignatureVault? _newMultisigVault;
  bool _isInitializing = true;
  int? _pendingSignerIndex; // 단일 서명 지갑을 만들러 간 키 자리. 새 지갑이 추가되면 이 자리에 배정한다
  bool _isPendingSignerDuplicated = false; // 새 지갑이 다른 자리에 가져온 키와 같아 배정하지 못함

  SignerAssignmentViewModel(this._walletProvider, this._walletCreationProvider) {
    _totalSignatureCount = _walletCreationProvider.totalSignatureCount!;
    _requiredSignatureCount = _walletCreationProvider.requiredSignatureCount!;
    _signerOptions = [];
    _assignedVaultList = List.generate(
      _totalSignatureCount,
      (index) => AssignedVaultListItem(singleSigVaultListItem: null, index: index, importKeyType: null),
    );
    notifyListeners();

    _singlesigVaultList =
        _walletProvider
            .getVaults()
            .where((vault) => vault.vaultType == WalletType.singleSignature)
            .map((vault) => vault as SingleSigVaultListItem)
            .toList();

    _initSignerOptionList(_singlesigVaultList).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 1000));
        _isInitializing = false;
        notifyListeners();
      });
    });

    _walletProvider.addListener(_onVaultListChanged);
  }
  String get loadingMessage => _loadingMessage;
  int get totalSignatureCount => _totalSignatureCount;
  int get requiredSignatureCount => _requiredSignatureCount;
  MultisignatureVault? get newMultisigVault => _newMultisigVault;
  List<SignerOption> get unselectedSignerOptions => _unselectedSignerOptions;

  /// 다른 자리에 외부 키로 가져온 키를 뺀 선택지. 그 자리를 비우면 다시 고를 수 있다.
  List<SignerOption> get assignableSignerOptions =>
      _unselectedSignerOptions.where((option) => !isAlreadyImported(option.signerBsms)).toList();
  List<AssignedVaultListItem> get assignedVaultList => _assignedVaultList;
  List<SingleSigVaultListItem> get singlesigVaultList => _singlesigVaultList;
  bool get isInitializing => _isInitializing;

  /// bsms를 비교하여 이미 보유한 볼트 지갑 중 하나인 경우 이름을 반환
  String? findVaultNameByBsms(SignerBsms signerBsms) {
    String targetMfp = signerBsms.fingerprint;
    int result = _signerOptions.indexWhere((element) {
      return element.masterFingerprint.toLowerCase() == targetMfp.toLowerCase();
    });

    if (result == -1) return null;
    return _signerOptions[result].singlesigVaultListItem.name;
  }

  int getAssignedVaultListLength() {
    return _assignedVaultList.where((e) => e.importKeyType != null).length;
  }

  bool isAlreadyImported(SignerBsms signerBsms) {
    for (int i = 0; i < _assignedVaultList.length; i++) {
      if (_assignedVaultList[i].bsms == null) continue;
      if (isEquivalentExtendedPubKey(signerBsms.extendedKey, _assignedVaultList[i].bsms!.extendedKey)) {
        return true;
      }
    }

    return false;
  }

  bool isAssignedKeyCompletely() {
    int assignedCount = getAssignedVaultListLength();
    if (assignedCount >= _totalSignatureCount) {
      return true;
    }
    return false;
  }

  Future<List<MultisigSigner>> onSelectionCompleted() async {
    List<KeyStore> keyStores = [];
    List<MultisigSigner> signers = [];

    for (int i = 0; i < _assignedVaultList.length; i++) {
      keyStores.add(KeyStore.fromSignerBsms(_assignedVaultList[i].bsms!.getSignerBsms(includesLabel: false)));
      switch (_assignedVaultList[i].importKeyType!) {
        case ImportKeyType.internal:
          signers.add(
            MultisigSigner(
              id: i,
              innerVaultId: _assignedVaultList[i].singleSigVaultListItem!.id,
              name: _assignedVaultList[i].singleSigVaultListItem!.name,
              iconIndex: _assignedVaultList[i].singleSigVaultListItem!.iconIndex,
              colorIndex: _assignedVaultList[i].singleSigVaultListItem!.colorIndex,
              signerBsms: _assignedVaultList[i].bsms!.getSignerBsms(includesLabel: false),
              keyStore: keyStores[i],
            ),
          );
          break;
        case ImportKeyType.external:
          signers.add(
            MultisigSigner(
              id: i,
              name: null,
              signerBsms: _assignedVaultList[i].bsms!.getSignerBsms(includesLabel: false),
              memo: _assignedVaultList[i].memo,
              signerSource: _assignedVaultList[i].signerSource,
              keyStore: keyStores[i],
            ),
          );
          break;
      }
    }

    assert(signers.length == _totalSignatureCount);
    // 검증: 올바른 Signer 정보를 받았는지 확인합니다.
    try {
      _newMultisigVault = await _createMultisignatureVault(keyStores);
    } catch (error) {
      rethrow;
    }
    return signers;
  }

  void assignInternalSigner(int vaultIndex, int signerIndex) {
    // 같은 키가 두 자리에 배정되면 멀티시그 지갑을 만들 수 없다
    if (isAlreadyImported(unselectedSignerOptions[vaultIndex].signerBsms)) return;
    // 내부 지갑 선택 완료
    _assignedVaultList[signerIndex]
      ..singleSigVaultListItem = unselectedSignerOptions[vaultIndex].singlesigVaultListItem
      ..bsms = unselectedSignerOptions[vaultIndex].signerBsms
      ..importKeyType = ImportKeyType.internal;
    unselectedSignerOptions.removeAt(vaultIndex);

    notifyListeners();
  }

  void setLoadingMessage(String message) {
    _loadingMessage = message;
    notifyListeners();
  }

  void setAssignedVaultList(
    int index,
    ImportKeyType importKeyType,
    bool isExpanded,
    SignerBsms bsms,
    String? memo,
    HardwareWalletType? signerSource,
  ) {
    String? normalizedMemo;
    if (memo != null && memo.trim().isEmpty) {
      normalizedMemo = null;
    } else {
      normalizedMemo = memo;
    }
    // 외부 지갑 추가
    _assignedVaultList[index]
      ..importKeyType = importKeyType
      ..bsms = bsms
      ..memo = normalizedMemo
      ..signerSource = signerSource;

    notifyListeners();
  }

  void saveSignersToProvider(List<MultisigSigner> signers) {
    // 도중에 단일 서명 지갑을 만들었다면 생성 화면의 resetAll로 정족수가 지워져 있고, secret이 남아 있을 수 있다
    _walletCreationProvider
      ..resetSecretAndPassphrase()
      ..setQuorumRequirement(_requiredSignatureCount, _totalSignatureCount);
    _walletCreationProvider.setSigners(signers);
  }

  /// 키 자리 [signerIndex]에 쓸 단일 서명 지갑을 만들러 가기 전에 호출한다.
  void prepareSignerCreation(int signerIndex) {
    _pendingSignerIndex = signerIndex;
    _isPendingSignerDuplicated = false;
    _walletCreationProvider.resetAll();
    _walletCreationProvider.setCreatingSignerForMultisig(true);
  }

  /// 단일 서명 지갑 생성 화면에서 돌아오면 호출한다. 저장하지 않고 돌아온 경우에도 생성 상태를 남기지 않는다.
  /// 새 지갑이 다른 자리에 가져온 키와 같아 배정하지 못했으면 true를 반환한다.
  bool finishSignerCreation() {
    _pendingSignerIndex = null;
    _walletCreationProvider
      ..setCreatingSignerForMultisig(false)
      ..resetSecretAndPassphrase();
    final isDuplicated = _isPendingSignerDuplicated;
    _isPendingSignerDuplicated = false;
    return isDuplicated;
  }

  void _onVaultListChanged() {
    final knownIds = _signerOptions.map((option) => option.singlesigVaultListItem.id).toSet();
    final addedVaults =
        _walletProvider
            .getVaults()
            .where((vault) => vault.vaultType == WalletType.singleSignature && !knownIds.contains(vault.id))
            .map((vault) => vault as SingleSigVaultListItem)
            .toList();
    if (addedVaults.isEmpty) return;

    for (final vault in addedVaults) {
      final option = SignerOption(
        vault,
        SignerBsms.parse(vault.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false)),
      );
      _singlesigVaultList.add(vault);
      _signerOptions.add(option);
      _unselectedSignerOptions.add(option);
    }
    _assignPendingSigner(addedVaults.last);
    notifyListeners();
  }

  void _assignPendingSigner(SingleSigVaultListItem vault) {
    final signerIndex = _pendingSignerIndex;
    _pendingSignerIndex = null;
    if (signerIndex == null || _assignedVaultList[signerIndex].importKeyType != null) return;

    final optionIndex = _unselectedSignerOptions.indexWhere((option) => option.singlesigVaultListItem.id == vault.id);
    if (optionIndex == -1) return;
    // 같은 키를 다른 자리에 외부 키로 이미 가져온 경우에는 배정하지 않는다
    if (isAlreadyImported(_unselectedSignerOptions[optionIndex].signerBsms)) {
      _isPendingSignerDuplicated = true;
      return;
    }
    assignInternalSigner(optionIndex, signerIndex);
  }

  @override
  void dispose() {
    _walletProvider.removeListener(_onVaultListChanged);
    _walletCreationProvider.setCreatingSignerForMultisig(false);
    super.dispose();
  }

  void resetWalletCreationProvider() {
    _walletCreationProvider.resetAll();
  }

  MultisigVaultListItem? findSameWallet(NormalizedMultisigConfig config) {
    return _walletProvider.findSameMultisigWallet(config);
  }

  VaultListItemBase? getWalletByDescriptor() => _walletProvider.findWalletByDescriptor(newMultisigVault!.descriptor);

  Future<MultisignatureVault> _createMultisignatureVault(List<KeyStore> keyStores) async {
    Map<String, dynamic> data = {
      'keyStores': jsonEncode(keyStores.map((item) => item.toJson()).toList()),
      'requiredSignatureCount': requiredSignatureCount,
    };
    MultisignatureVault multisignatureVault = await compute(WalletIsolates.fromKeyStores, data);

    return multisignatureVault;
  }

  Future<void> _initSignerOptionList(List<SingleSigVaultListItem> singlesigVaultList) async {
    for (int i = 0; i < singlesigVaultList.length; i++) {
      _signerOptions.add(
        SignerOption(
          singlesigVaultList[i],
          SignerBsms.parse(singlesigVaultList[i].getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false)),
        ),
      );
    }

    _unselectedSignerOptions = _signerOptions.toList();
  }

  String? getExternalSignerMemo(int index) {
    assert(_assignedVaultList[index].importKeyType == ImportKeyType.external);
    assert(_assignedVaultList[index].bsms != null);

    if (_assignedVaultList[index].memo != null) {
      return _assignedVaultList[index].memo;
    }

    return _assignedVaultList[index].bsms!.label;
  }
}
