import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';

class SingleSigSignViewModel extends ChangeNotifier {
  final int requiredSignatureCount = 1;
  final WalletProvider _walletProvider;
  final SignProvider _signProvider;
  final bool _isSigningOnlyMode;

  late final SingleSignatureVault _coconutVault;
  late final bool _isAlreadySigned;

  bool _isSignerApproved = false;
  bool _hasPassphrase = false;

  SingleSigSignViewModel(this._walletProvider, this._signProvider, this._isSigningOnlyMode) {
    _coconutVault = _vaultListItem.coconutVault as SingleSignatureVault;

    _isAlreadySigned = _isSigned();
    if (_isAlreadySigned) {
      _signProvider.saveSignedPsbt(_signProvider.unsignedPsbtBase64!);
    }
    if (!_isSigningOnlyMode) {
      _checkPassphraseStatus();
    }
  }

  // MARK: - Getters

  SingleSigVaultListItem get _vaultListItem => _signProvider.vaultListItem! as SingleSigVaultListItem;

  bool get isAlreadySigned => _isAlreadySigned;
  String get walletName => _vaultListItem.name;
  bool get isSignerApproved => _isSignerApproved;
  int get walletIconIndex => _vaultListItem.iconIndex;
  int get walletColorIndex => _vaultListItem.colorIndex;

  String get firstRecipientAddress => _signProvider.recipientAddress ?? _signProvider.recipientAmounts!.keys.first;
  int get recipientCount => _signProvider.recipientAddress != null ? 1 : _signProvider.recipientAmounts!.length;
  int get sendingAmount => _signProvider.sendingAmount!;
  bool get hasPassphrase => _hasPassphrase;
  int get walletId => _signProvider.walletId!;
  bool get isSigningOnlyMode => _isSigningOnlyMode;

  // MARK: - Status Checking

  Future<void> _checkPassphraseStatus() async {
    _hasPassphrase = await _walletProvider.hasPassphrase(walletId);
    notifyListeners();
  }

  bool _isSigned() {
    return _signProvider.psbt!.isSigned(_coconutVault.keyStore);
  }

  void updateSignState() {
    _isSignerApproved = true;
    notifyListeners();
  }

  // MARK: - Signature Actions

  Future<void> sign({required Seed seed}) async {
    try {
      await _processSignature(seed);
    } finally {
      seed.wipe();
    }
  }

  Future<void> signPsbtInSigningOnlyMode() async {
    assert(_isSigningOnlyMode);
    Seed? seed;
    try {
      seed = await _walletProvider.getSeedInSigningOnlyMode(walletId);
      await _processSignature(seed);
    } finally {
      seed?.wipe();
    }
  }

  Future<void> _processSignature(Seed seed) async {
    final accountIndex = _vaultListItem.currentAccountIndex;

    final signedTx = await compute(SignIsolates.addSignatureToPsbtWithSingleVault, [
      seed,
      _signProvider.unsignedPsbtBase64!,
      accountIndex,
    ]);

    _signProvider.saveSignedPsbt(signedTx);
    updateSignState();
  }

  void resetSignProvider() {
    _signProvider.resetSignedPsbt();
  }

  Future<Uint8List> getSecret() async {
    return await _walletProvider.getSecret(walletId);
  }
}
