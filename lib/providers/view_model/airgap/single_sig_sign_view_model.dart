import 'package:coconut_lib/coconut_lib.dart';
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
  late final List<bool> _signersApproved =
      List<bool>.filled(requiredSignatureCount, false);

  SingleSigSignViewModel(this._walletProvider, this._signProvider) {
    _coconutVault = (_signProvider.vaultListItem! as SingleSigVaultListItem)
        .coconutVault as SingleSignatureVault;

    _isAlreadySigned = _isSigned();
    if (_isAlreadySigned) {
      _signProvider.saveSignedPsbt(_signProvider.unsignedPsbtBase64!);
    }
  }

  bool get isAlreadySigned => _isAlreadySigned;
  String get walletName => _signProvider.vaultListItem!.name;
  List<bool> get signersApproved => _signersApproved;
  int get walletIconIndex => _signProvider.vaultListItem!.iconIndex;
  int get walletColorIndex => _signProvider.vaultListItem!.colorIndex;
  List<String> get recipientAddress => _signProvider.recipientAddress != null
      ? [_signProvider.recipientAddress!]
      : _signProvider.recipientAmounts!.keys.toList();
  int get sendingAmount => _signProvider.sendingAmount!;

  bool _isSigned() {
    return _signProvider.psbt!.isSigned(_coconutVault.keyStore);
  }

  void updateSignState() {
    _signersApproved[0] = true;
    notifyListeners();
  }

  Future<void> sign() async {
    try {
      var secret = await _walletProvider.getSecret(_signProvider.walletId!);
      final seed =
          Seed.fromMnemonic(secret.mnemonic, passphrase: secret.passphrase);
      _coconutVault.keyStore.seed = seed;

      final signedTx =
          _coconutVault.addSignatureToPsbt(_signProvider.unsignedPsbtBase64!);

      _signProvider.saveSignedPsbt(signedTx);
    } finally {
      // unbind
      _coconutVault.keyStore.seed = null;
    }
  }

  void resetSignProvider() {
    _signProvider.resetSignedPsbt();
  }

  bool isApproved(int signerIndex) {
    return _signersApproved[signerIndex];
  }
}
