import 'dart:typed_data';

import 'package:coconut_vault/extensions/uint8list_extensions.dart';

enum TaprootCreationType { parent, child }

class TaprootWalletCreationProvider {
  ({Uint8List secret, Uint8List? passphrase}) _parentKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
  ({Uint8List secret, Uint8List? passphrase}) _childKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));

  TaprootCreationType _creationType = TaprootCreationType.parent;

  TaprootCreationType get creationType => _creationType;

  Uint8List get secret => _creationType == TaprootCreationType.parent ? _parentKeyData.secret : _childKeyData.secret;

  Uint8List? get passphrase {
    final pass = _creationType == TaprootCreationType.parent ? _parentKeyData.passphrase : _childKeyData.passphrase;
    return pass != null && pass.isNotEmpty ? pass : null;
  }

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    if (_creationType == TaprootCreationType.parent) {
      _parentKeyData = (secret: secret, passphrase: passphrase ?? Uint8List(0));
    } else {
      _childKeyData = (secret: secret, passphrase: passphrase ?? Uint8List(0));
    }
  }

  void setCreationType(TaprootCreationType type) {
    _creationType = type;
  }

  void resetSecretAndPassphrase() {
    if (_creationType == TaprootCreationType.parent) {
      _parentKeyData.secret.wipe();
      _parentKeyData.passphrase?.wipe();
      _parentKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
    } else {
      _childKeyData.secret.wipe();
      _childKeyData.passphrase?.wipe();
      _childKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
    }
  }

  void resetAll() {
    _creationType = TaprootCreationType.parent;
    _parentKeyData.secret.wipe();
    _parentKeyData.passphrase?.wipe();
    _parentKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
    _childKeyData.secret.wipe();
    _childKeyData.passphrase?.wipe();
    _childKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
  }
}
