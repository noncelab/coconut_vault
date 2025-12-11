import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
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

  List<MultisigSigner>? _signers;
  bool _isInitializing = true;

  SignerAssignmentViewModel(this._walletProvider, this._walletCreationProvider) {
    _totalSignatureCount = _walletCreationProvider.totalSignatureCount!;
    _requiredSignatureCount = _walletCreationProvider.requiredSignatureCount!;
    _signerOptions = [];
    _assignedVaultList = List.generate(
      _totalSignatureCount,
      (index) => AssignedVaultListItem(item: null, index: index, importKeyType: null),
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
  String? findVaultNameByBsms(String signerBsms) {
    var mfp = Bsms.parseSigner(signerBsms).signer!.masterFingerPrint;

    int result = _signerOptions.indexWhere((element) {
      return element.masterFingerprint == mfp;
    });
    if (result == -1) return null;
    return _signerOptions[result].singlesigVaultListItem.name;
  }

  int getAssignedVaultListLength() {
    return assignedVaultList.where((e) => e.importKeyType != null).length;
  }

  bool isAllAssignedFromExternal() {
    return assignedVaultList.every(
          (vault) => vault.importKeyType == null || vault.importKeyType == ImportKeyType.external,
        ) &&
        getAssignedVaultListLength() >= totalSignatureCount - 1;
  }

  bool isAlreadyImported(String signerBsms) {
    List<String> splitedOne = signerBsms.split('\n');
    for (int i = 0; i < assignedVaultList.length; i++) {
      if (assignedVaultList[i].bsms == null) continue;
      List<String> splitedTwo = assignedVaultList[i].bsms!.split('\n');
      if (splitedOne[0] == splitedTwo[0] && splitedOne[1] == splitedTwo[1] && splitedOne[2] == splitedTwo[2]) {
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
      keyStores.add(KeyStore.fromSignerBsms(_assignedVaultList[i].bsms!));
      switch (_assignedVaultList[i].importKeyType!) {
        case ImportKeyType.internal:
          signers.add(
            MultisigSigner(
              id: i,
              innerVaultId: _assignedVaultList[i].item!.id,
              name: _assignedVaultList[i].item!.name,
              iconIndex: _assignedVaultList[i].item!.iconIndex,
              colorIndex: _assignedVaultList[i].item!.colorIndex,
              signerBsms: _assignedVaultList[i].bsms!,
              keyStore: keyStores[i],
            ),
          );
          break;
        case ImportKeyType.external:
          signers.add(
            MultisigSigner(
              id: i,
              signerBsms: _assignedVaultList[i].bsms!,
              name: _assignedVaultList[i].bsms?.split('\n')[3] ?? '',
              memo: _assignedVaultList[i].memo,
              signerSource: _assignedVaultList[i].signerSource,
              keyStore: keyStores[i],
            ),
          );
          break;
      }
    }

    assert(signers.length == _totalSignatureCount);
    // signer mfp 기준으로 재정렬하기
    List<int> indices = List.generate(keyStores.length, (i) => i);
    indices.sort((a, b) => keyStores[a].masterFingerprint.compareTo(keyStores[b].masterFingerprint));

    keyStores = [for (var i in indices) keyStores[i]];
    signers = [for (var i in indices) signers[i]]..asMap().forEach((i, signer) => signer.id = i);

    _assignedVaultList = [for (var i in indices) assignedVaultList[i]];

    for (int i = 0; i < assignedVaultList.length; i++) {
      assignedVaultList[i].index = i;
    }
    setLoadingMessage(t.assign_signers_screen.data_verifying);

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
    assignedVaultList[signerIndex]
      ..item = unselectedSignerOptions[vaultIndex].singlesigVaultListItem
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
    String bsms,
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
    assignedVaultList[index]
      ..importKeyType = importKeyType
      ..bsms = bsms
      ..memo = normalizedMemo
      ..signerSource = signerSource;

    notifyListeners();
  }

  void setSigners(List<MultisigSigner>? signers) {
    _signers = signers;
  }

  void saveSignersToProvider() {
    assert(_signers != null);
    _walletCreationProvider.setSigners(_signers!);
  }

  void resetWalletCreationProvider() {
    _walletCreationProvider.resetAll();
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
        SignerOption(singlesigVaultList[i], singlesigVaultList[i].signerBsmsByAddressType[AddressType.p2wsh]!),
      );
    }

    _unselectedSignerOptions = _signerOptions.toList();
  }

  String? getExternalSignerMemo(int index) {
    assert(assignedVaultList[index].importKeyType == ImportKeyType.external);
    assert(assignedVaultList[index].bsms != null);

    if (assignedVaultList[index].memo != null) {
      return assignedVaultList[index].memo;
    }

    var splited = assignedVaultList[index].bsms!.split('\n');
    if (splited.length >= 4) {
      return splited[3];
    }

    return null;
  }
}
