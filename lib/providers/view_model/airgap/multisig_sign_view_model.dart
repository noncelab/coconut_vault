import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/secret.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';

class MultisigSignViewModel extends ChangeNotifier {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;
  late final MultisigVaultListItem _vaultListItem;
  late final MultisignatureVault _coconutVault;
  late final List<bool> _signerApproved;
  List<bool>? _nonceInput;
  late String _psbtForSigning;
  bool _signStateInitialized = false;

  MultisigSignViewModel(this._walletProvider, this._signProvider) {
    _vaultListItem = _signProvider.vaultListItem! as MultisigVaultListItem;
    _coconutVault = _vaultListItem.coconutVault as MultisignatureVault;
    final signerCount = _vaultListItem.signers.length;
    _signerApproved = List<bool>.filled(signerCount, false);
    _nonceInput = List<bool>.filled(signerCount, false);
    _psbtForSigning = _signProvider.unsignedPsbtBase64!;
  }
  String get addressType => _vaultListItem.addressType;
  int get requiredSignatureCount => _vaultListItem.requiredSignatureCount;
  String get walletName => _signProvider.vaultListItem!.name;
  List<bool> get signersApproved => _signerApproved;
  List<bool> get nonceInput => _nonceInput ?? [];
  bool get isAllNonceInput => (_nonceInput ?? []).every((input) => input);
  String get firstRecipientAddress => _signProvider.recipientAddress != null
      ? _signProvider.recipientAddress!
      : _signProvider.recipientAmounts!.keys.first;
  int get recipientCount =>
      _signProvider.recipientAddress != null ? 1 : _signProvider.recipientAmounts!.length;
  int get sendingAmount => _signProvider.sendingAmount!;
  int get remainingSignatures =>
      _vaultListItem.requiredSignatureCount -
      _signerApproved.where((bool isApproved) => isApproved).length;
  bool get isSignatureComplete => remainingSignatures <= 0;
  List<MultisigSigner> get signers => _vaultListItem.signers;
  String get psbtForSigning => _psbtForSigning;

  void initPsbtSignState() {
    assert(!_signStateInitialized); // 오직 한번만 호출
    _signStateInitialized = true;

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

  Future<void> sign(int index) async {
    try {
      var secret = await _walletProvider.getSecret(_vaultListItem.signers[index].innerVaultId!);
      final seed = Seed.fromMnemonic(secret.mnemonic, passphrase: secret.passphrase);
      _coconutVault.bindSeedToKeyStore(seed);
      _psbtForSigning = _coconutVault.keyStoreList[index]
          .addSignatureToPsbt(_psbtForSigning, _coconutVault.addressType);
    } finally {
      // unbind
      _coconutVault.keyStoreList[index].seed = null;
    }
  }

  Future<void> addNonce(int index) async {
    try {
      var secret = await _walletProvider.getSecret(_vaultListItem.signers[index].innerVaultId!);
      final seed = Seed.fromMnemonic(secret.mnemonic, passphrase: secret.passphrase);
      _coconutVault.bindSeedToKeyStore(seed);

      _psbtForSigning =
          _coconutVault.keyStoreList[index].addMuSig2PublicNonceToPsbt(_psbtForSigning);

      // 논스 입력 상태 업데이트
      if (_nonceInput != null && index < _nonceInput!.length) {
        _nonceInput![index] = true;
        notifyListeners();
      }
    } finally {
      // unbind
      _coconutVault.keyStoreList[index].seed = null;
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
}
