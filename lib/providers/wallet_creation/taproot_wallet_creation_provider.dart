import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:flutter/foundation.dart';

class TaprootWalletCreationProvider extends ChangeNotifier {
  Uint8List _secret = Uint8List(0); // utf8.encode(mnemonicWordsString)
  Uint8List _passphrase = Uint8List(0); // utf8.encode(passphraseString)

  String? _childCreationOption;

  String? _qrData;
  String? _masterFingerprint;
  String? _externalMultisigParentSignerBsms;
  String? _externalMultisigParentMasterFingerprint;

  Uint8List get secret => _secret;
  Uint8List? get passphrase => _passphrase.isNotEmpty ? _passphrase : null;
  String? get childCreationOption => _childCreationOption;
  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;
  String? get externalMultisigParentSignerBsms => _externalMultisigParentSignerBsms;
  String? get externalMultisigParentMasterFingerprint => _externalMultisigParentMasterFingerprint;

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _secret = secret;
    _passphrase = passphrase ?? Uint8List(0);

    try {
      final seed = Seed.fromMnemonic(_secret, passphrase: _passphrase.isNotEmpty ? _passphrase : Uint8List(0));

      final keyStore = KeyStore.fromSeed(seed, AddressType.p2trKeyPathSpending);
      final signerKeyStore = KeyStore.fromSeed(seed, AddressType.p2wsh);

      _masterFingerprint = keyStore.masterFingerprint;
      final derivationPath = WalletUtility.getDerivationPath(AddressType.p2wsh, 0).replaceAll('m/', '');
      _qrData = SignerBsms(
        fingerprint: signerKeyStore.masterFingerprint,
        derivationPath: derivationPath,
        extendedKey: signerKeyStore.extendedPublicKey.serialize(),
      ).getSignerBsms(includesLabel: false);
    } catch (e) {
      _masterFingerprint = '00000000';
      _qrData = '';
    }

    notifyListeners();
  }

  void setChildCreationOption(String routeName) {
    _childCreationOption = routeName;
    notifyListeners();
  }

  void setExternalMultisigParent({required String signerBsms, required String masterFingerprint}) {
    _externalMultisigParentSignerBsms = signerBsms;
    _externalMultisigParentMasterFingerprint = masterFingerprint;
    notifyListeners();
  }

  void resetSecretAndPassphrase() {
    _secret.wipe();
    _passphrase.wipe();
    _secret = Uint8List(0);
    _passphrase = Uint8List(0);
    _childCreationOption = null;
    _qrData = null;
    _masterFingerprint = null;
    _externalMultisigParentSignerBsms = null;
    _externalMultisigParentMasterFingerprint = null;
    notifyListeners();
  }

  void resetAll() {
    resetSecretAndPassphrase();
  }
}
