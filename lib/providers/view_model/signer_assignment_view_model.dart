import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
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
  }
  String get loadingMessage => _loadingMessage;
  int get totalSignatureCount => _totalSignatureCount;
  int get requiredSignatureCount => _requiredSignatureCount;
  MultisignatureVault? get newMultisigVault => _newMultisigVault;
  List<SignerOption> get unselectedSignerOptions => _unselectedSignerOptions;
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
    _walletCreationProvider.setSigners(signers);
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
          SignerBsms.parse(singlesigVaultList[i].signerBsmsByAddressType[AddressType.p2wsh]!),
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
