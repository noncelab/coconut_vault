import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:flutter/foundation.dart';

class TaprootWalletCreationProvider extends ChangeNotifier {
  Uint8List _secret = Uint8List(0); // utf8.encode(mnemonicWordsString)
  Uint8List _passphrase = Uint8List(0); // utf8.encode(passphraseString)

  Uint8List get secret => _secret;
  Uint8List? get passphrase => _passphrase.isNotEmpty ? _passphrase : null;

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _secret = secret;
    _passphrase = passphrase ?? Uint8List(0);
    notifyListeners();
  }

  void setChildCreationOption(String routeName) {
    notifyListeners();
  }

  void resetSecretAndPassphrase() {
    _secret.wipe();
    _passphrase.wipe();
    _secret = Uint8List(0);
    _passphrase = Uint8List(0);
    notifyListeners();
  }

  void resetAll() {
    resetSecretAndPassphrase();
  }
}
