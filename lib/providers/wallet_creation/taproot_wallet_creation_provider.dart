import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:flutter/foundation.dart';

enum TaprootCreationType { parent, child }

class TaprootWalletCreationProvider extends ChangeNotifier {
  ({Uint8List secret, Uint8List? passphrase}) _parentKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
  ({Uint8List secret, Uint8List? passphrase}) _childKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));

  TaprootCreationType _creationType = TaprootCreationType.parent;

  TaprootCreationType get creationType => _creationType;
  String? _qrData;
  String? _masterFingerprint;
  String? _externalMultisigParentSignerBsms;
  String? _externalMultisigParentMasterFingerprint;

  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;
  String? get externalMultisigParentSignerBsms => _externalMultisigParentSignerBsms;
  String? get externalMultisigParentMasterFingerprint => _externalMultisigParentMasterFingerprint;

  Uint8List get secret => _creationType == TaprootCreationType.parent ? _parentKeyData.secret : _childKeyData.secret;

  Uint8List? get passphrase {
    final pass = _creationType == TaprootCreationType.parent ? _parentKeyData.passphrase : _childKeyData.passphrase;
    return pass != null && pass.isNotEmpty ? pass : null;
  }

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    if (_creationType == TaprootCreationType.parent) {
      _parentKeyData = (secret: secret, passphrase: passphrase ?? Uint8List(0));
      _updateQrData();
    } else {
      _childKeyData = (secret: secret, passphrase: passphrase ?? Uint8List(0));
    }
    notifyListeners();
  }

  void _updateQrData() {
    final currentSecret = _parentKeyData.secret;
    final currentPassphrase = _parentKeyData.passphrase ?? Uint8List(0);

    if (currentSecret.isEmpty) return;

    try {
      final seed = Seed.fromMnemonic(currentSecret, passphrase: currentPassphrase);

      final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);
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
  }

  void setCreationType(TaprootCreationType type) {
    _creationType = type;
  }

  void setExternalMultisigParent({required String signerBsms, required String masterFingerprint}) {
    _externalMultisigParentSignerBsms = signerBsms;
    _externalMultisigParentMasterFingerprint = masterFingerprint;
    notifyListeners();
  }

  void resetSecretAndPassphrase() {
    if (_creationType == TaprootCreationType.parent) {
      _parentKeyData.secret.wipe();
      _parentKeyData.passphrase?.wipe();
      _parentKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
      _qrData = null;
      _masterFingerprint = null;
      _externalMultisigParentSignerBsms = null;
      _externalMultisigParentMasterFingerprint = null;
    } else {
      _childKeyData.secret.wipe();
      _childKeyData.passphrase?.wipe();
      _childKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
    }
    notifyListeners();
  }

  void resetAll() {
    _creationType = TaprootCreationType.parent;
    _parentKeyData.secret.wipe();
    _parentKeyData.passphrase?.wipe();
    _parentKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
    _childKeyData.secret.wipe();
    _childKeyData.passphrase?.wipe();
    _childKeyData = (secret: Uint8List(0), passphrase: Uint8List(0));
    _qrData = null;
    _masterFingerprint = null;
    _externalMultisigParentSignerBsms = null;
    _externalMultisigParentMasterFingerprint = null;
    notifyListeners();
  }
}
