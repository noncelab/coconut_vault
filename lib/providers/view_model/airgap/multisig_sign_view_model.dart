import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:flutter/foundation.dart';

class MultisigSignViewModel extends ChangeNotifier {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;
  late final MultisigVaultListItem _vaultListItem;
  late final MultisignatureVault _coconutVault;
  late final List<bool> _signerApproved;
  late final List<bool> _hasPassphraseList;
  late String _psbtForSigning;
  bool _signStateInitialized = false;
  final bool _isSigningOnlyMode;

  MultisigSignViewModel(this._walletProvider, this._signProvider, this._isSigningOnlyMode) {
    _vaultListItem = _signProvider.vaultListItem! as MultisigVaultListItem;
    _coconutVault = _vaultListItem.coconutVault as MultisignatureVault;
    _signerApproved = List<bool>.filled(_vaultListItem.signers.length, false);
    _hasPassphraseList = List<bool>.filled(_vaultListItem.signers.length, false);

    _psbtForSigning = _signProvider.unsignedPsbtBase64!;
    if (!_isSigningOnlyMode) {
      _checkPassphraseStatus();
    }
  }

  Future<void> _checkPassphraseStatus() async {
    for (int i = 0; i < _vaultListItem.signers.length; ++i) {
      final innerVaultId = _vaultListItem.signers[i].innerVaultId;
      if (innerVaultId != null) {
        _hasPassphraseList[i] = await _walletProvider.hasPassphrase(innerVaultId);
      }
    }
  }

  int get requiredSignatureCount => _vaultListItem.requiredSignatureCount;
  String get walletName => _signProvider.vaultListItem!.name;
  List<bool> get signersApproved => _signerApproved;
  String get firstRecipientAddress =>
      _signProvider.recipientAddress != null
          ? _signProvider.recipientAddress!
          : _signProvider.recipientAmounts!.keys.first;
  int get recipientCount => _signProvider.recipientAddress != null ? 1 : _signProvider.recipientAmounts!.length;
  int get sendingAmount => _signProvider.sendingAmount!;
  int get remainingSignatures =>
      _vaultListItem.requiredSignatureCount - _signerApproved.where((bool isApproved) => isApproved).length;
  bool get isSignatureComplete => remainingSignatures <= 0;
  List<MultisigSigner> get signers => _vaultListItem.signers;
  String get psbtForSigning => _psbtForSigning;
  int getInnerVaultId(int index) => _vaultListItem.signers[index].innerVaultId!;
  bool getHasPassphrase(int index) => _hasPassphraseList[index];
  bool get isSigningOnlyMode => _isSigningOnlyMode;

  void initPsbtSignState() {
    assert(!_signStateInitialized); // 오직 한번만 호출
    _signStateInitialized = true;
    debugPrint('signnnnnnnnn: ${_signProvider.walletId}');

    final psbt = _signProvider.psbt!;
    for (var entry in _coconutVault.keyStoreList.asMap().entries) {
      if (psbt.isSigned(entry.value) && !_signerApproved[entry.key]) {
        updateSignState(entry.key);
      }
    }
  }

  void updateSignState(int index) {
    _signerApproved[index] = true;
    notifyListeners();
  }

  String getPsbtBase64() {
    return _signProvider.signedPsbtBase64 ?? _signProvider.unsignedPsbtBase64!;
  }

  Future<Uint8List> getSecret(int index) async {
    return await _walletProvider.getSecret(_vaultListItem.signers[index].innerVaultId!);
  }

  Future<void> sign(int index, Seed seed) async {
    try {
      _psbtForSigning = await compute(SignIsolates.addSignatureToPsbtWithMultisigVault, [seed, _psbtForSigning]);
      updateSignState(index);
    } finally {
      seed.wipe();
    }
  }

  Future<void> signPsbtInSigningOnlyMode(int index) async {
    assert(_isSigningOnlyMode);
    Seed? seed;
    try {
      seed = await _walletProvider.getSeedInSigningOnlyMode(_vaultListItem.signers[index].innerVaultId!);
      _psbtForSigning = await compute(SignIsolates.addSignatureToPsbtWithMultisigVault, [seed, _psbtForSigning]);
      updateSignState(index);
    } finally {
      seed?.wipe();
    }
  }

  void saveSignedPsbt() {
    _signProvider.saveSignedPsbt(_psbtForSigning);
  }

  void reset() {
    _signProvider.resetSignedPsbt();
  }

  void resetAll() {
    _signProvider.resetPsbt();
    _signProvider.resetRecipientAddress();
    _signProvider.resetRecipientAmounts();
    _signProvider.resetSendingAmount();
    _signProvider.resetSignedPsbt();
  }

  // TODO: signers[index]의 hww type 가져오기
  HardwareWalletType? getSignerHwwType(int index) {
    // return _vaultListItem.signers[index].hardwareWalletType ?? HarewareWalletType.vault;
    return null;
  }

  // TODO: signers[index]의 hww type에 따라 다른 정보를 반환하도록 구현
  String? getMultisigInfoQrData(int index, HardwareWalletType hwwType) {
    if (hwwType == HardwareWalletType.keystone3Pro) {
      return _getKeystoneMultisigInfoQrData(index);
    } else if (hwwType == HardwareWalletType.krux) {
      return _getKruxMultisigInfoQrData(index);
    }
    return null;
  }

  // {
  //   "label": "multisig2",
  //   "blockheight": 140309,
  //   "descriptor": "wsh(sortedmulti(2,[73c5da0a/48h/1h/0h/2h]tpubDFH9dgzveyD8zTbPUFuLrGmCydNvxehyNdUXKJAQN8x4aZ4j6UZqGfnqFrD4NqyaTVGKbvEW54tsvPTK2UoSbCC1PJY8iCNiwTL3RWZEheQ,[a0f6ba00/48h/1h/0h/2h]tpubDFX3DiBn9TanpuwxEbfBfPoRDtfGuwRNpkCFf4Yq22SMSGhr4zLhMBFSbTR7jFnLbNdqvtLUyuSAYk4jR8vSa4h2m8qL6zxwU4bYE1wGmDF,[a3b2eb70/48h/1h/0h/2h]tpubDFXHjN6AZbhZd5H6XhMWAKjoCn9r9Uj6sMtyXKTkN3HAaYEMEGKzU836gkxcF7PUT3BgMUj8KPmU447kzo1naMetkyWNRoBapfAbqWqUuzQ))#pmgfjdf3"
  // }
  String _getKruxMultisigInfoQrData(int index) {
    final name = _vaultListItem.name;
    final coordinatorBsms = _vaultListItem.coordinatorBsms;

    final lines = coordinatorBsms.split('\n');
    if (lines.length < 4) {
      throw FormatException('Coordinator BSMS block too short: ${lines.length}');
    }

    final descriptorLine = lines[1].replaceAll("'", "h");

    final coordinatorBsmsJson = {'label': name, 'blockheight': 0, 'descriptor': descriptorLine};

    return jsonEncode(coordinatorBsmsJson);
  }

  String _getKeystoneMultisigInfoQrData(int index) {
    final name = _vaultListItem.name;
    final config = NormalizedMultisigConfig(
      name: name,
      requiredCount: _vaultListItem.requiredSignatureCount,
      signerBsms: _vaultListItem.signers.map((signer) => signer.signerBsms!).toList(),
    );

    return config.getMultisigConfigString();
  }
}
