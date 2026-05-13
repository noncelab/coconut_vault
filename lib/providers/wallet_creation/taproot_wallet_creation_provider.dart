import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:flutter/foundation.dart';

class TaprootWalletCreationProvider extends ChangeNotifier {
  ({Uint8List secret, Uint8List? passphrase}) _keyData = (secret: Uint8List(0), passphrase: Uint8List(0));

  bool _isChildWalletCreation = false;

  Uint8List get secret => _keyData.secret;
  Uint8List? get passphrase =>
      _keyData.passphrase != null && _keyData.passphrase!.isNotEmpty ? _keyData.passphrase : null;
  bool get isChildWalletCreation => _isChildWalletCreation;

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _keyData = (secret: secret, passphrase: passphrase ?? Uint8List(0));
    notifyListeners();
  }

  void setIsChildWalletCreation(bool value) {
    _isChildWalletCreation = value;
    notifyListeners();
  }

  void resetSecretAndPassphrase() {
    _keyData.secret.wipe();
    _keyData.passphrase?.wipe();
    _keyData = (secret: Uint8List(0), passphrase: Uint8List(0));
    notifyListeners();
  }

  void resetAll() {
    _isChildWalletCreation = false;
    resetSecretAndPassphrase();
  }
}
