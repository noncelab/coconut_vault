import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';

class SingleSigSignViewModel extends ChangeNotifier {
  final int requiredSignatureCount = 1;
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;
  late final SingleSignatureVault _coconutVault;
  late final bool _isAlreadySigned;
  late bool _isSignerApproved = false;
  bool _hasPassphrase = false;
  final bool _isSigningOnlyMode;

  SingleSigSignViewModel(this._walletProvider, this._signProvider, this._isSigningOnlyMode) {
    _coconutVault = (_signProvider.vaultListItem! as SingleSigVaultListItem).coconutVault as SingleSignatureVault;

    _isAlreadySigned = _isSigned();
    if (_isAlreadySigned) {
      _signProvider.saveSignedPsbt(_signProvider.unsignedPsbtBase64!);
    }
    _checkPassphraseStatus();
  }

  Future<void> _checkPassphraseStatus() async {
    _hasPassphrase = await _walletProvider.hasPassphrase(_signProvider.walletId!);
  }

  bool get isAlreadySigned => _isAlreadySigned;
  String get walletName => _signProvider.vaultListItem!.name;
  bool get isSignerApproved => _isSignerApproved;
  int get walletIconIndex => _signProvider.vaultListItem!.iconIndex;
  int get walletColorIndex => _signProvider.vaultListItem!.colorIndex;
  String get firstRecipientAddress =>
      _signProvider.recipientAddress != null
          ? _signProvider.recipientAddress!
          : _signProvider.recipientAmounts!.keys.first;
  int get recipientCount => _signProvider.recipientAddress != null ? 1 : _signProvider.recipientAmounts!.length;
  int get sendingAmount => _signProvider.sendingAmount!;
  bool get hasPassphrase => _hasPassphrase;
  int get walletId => _signProvider.walletId!;
  bool get isSigningOnlyMode => _isSigningOnlyMode;

  bool _isSigned() {
    return _signProvider.psbt!.isSigned(_coconutVault.keyStore);
  }

  void updateSignState() {
    _isSignerApproved = true;
    notifyListeners();
  }

  Future<void> sign({required Uint8List passphrase}) async {
    Uint8List? mnemonicBytes;
    Seed? seed;

    try {
      mnemonicBytes = await _walletProvider.getSecret(_signProvider.walletId!);

      seed = Seed.fromMnemonic(mnemonicBytes, passphrase: passphrase);

      final signedTx = await compute(SignIsolates.addSignatureToPsbtWithSingleVault, [
        seed,
        _signProvider.unsignedPsbtBase64!,
      ]);
      _signProvider.saveSignedPsbt(signedTx);
      updateSignState();
    } finally {
      mnemonicBytes?.wipe();
      seed?.wipe();
    }
  }

  Future<void> signPsbtInSigningOnlyMode() async {
    assert(_isSigningOnlyMode);
    Seed? seed;
    try {
      seed = await _walletProvider.getSeedInSigningOnlyMode(_signProvider.walletId!);
      final signedTx = await compute(SignIsolates.addSignatureToPsbtWithSingleVault, [
        seed,
        _signProvider.unsignedPsbtBase64!,
      ]);
      _signProvider.saveSignedPsbt(signedTx);
      updateSignState();
    } finally {
      seed?.wipe();
    }
  }

  void resetSignProvider() {
    _signProvider.resetSignedPsbt();
  }
}
