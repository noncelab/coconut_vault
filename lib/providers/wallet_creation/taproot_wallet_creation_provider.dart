import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:flutter/foundation.dart';

class TaprootWalletCreationProvider extends ChangeNotifier {
  Uint8List _secret = Uint8List(0); // utf8.encode(mnemonicWordsString)
  Uint8List _passphrase = Uint8List(0); // utf8.encode(passphraseString)

  String? _childCreationOption;

  String? _qrData;
  String? _masterFingerprint;

  Uint8List get secret => _secret;
  Uint8List? get passphrase => _passphrase.isNotEmpty ? _passphrase : null;
  String? get childCreationOption => _childCreationOption;
  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _secret = secret;
    _passphrase = passphrase ?? Uint8List(0);

    try {
      final seed = Seed.fromMnemonic(_secret, passphrase: _passphrase.isNotEmpty ? _passphrase : Uint8List(0));

      final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);

      _masterFingerprint = keyStore.masterFingerprint;
      _qrData = keyStore.extendedPublicKey.serialize();
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

  void resetSecretAndPassphrase() {
    _secret.wipe();
    _passphrase.wipe();
    _secret = Uint8List(0);
    _passphrase = Uint8List(0);
    _childCreationOption = null;
    _qrData = null;
    _masterFingerprint = null;
    notifyListeners();
  }

  void resetAll() {
    resetSecretAndPassphrase();
  }
}
