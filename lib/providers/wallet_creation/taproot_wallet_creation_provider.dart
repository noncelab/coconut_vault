import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:flutter/foundation.dart';

enum TaprootChildWalletSource { scanned, created }

class TaprootWalletCreationProvider extends ChangeNotifier {
  Uint8List _secret = Uint8List(0); // utf8.encode(mnemonicWordsString)
  Uint8List _passphrase = Uint8List(0); // utf8.encode(passphraseString)

  String? _childCreationOption;

  String? _qrData;
  String? _masterFingerprint;
  String? _externalMultisigParentSignerBsms;
  String? _externalMultisigParentMasterFingerprint;
  String? _childWalletDescriptor;
  String? _childWalletMasterFingerprint;
  Uint8List _childSecret = Uint8List(0);
  Uint8List _childPassphrase = Uint8List(0);
  TaprootChildWalletSource? _childWalletSource;
  DateTime? _timelockDateTime;

  Uint8List get secret => _secret;
  Uint8List? get passphrase => _passphrase.isNotEmpty ? _passphrase : null;
  String? get childCreationOption => _childCreationOption;
  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;
  String? get externalMultisigParentSignerBsms => _externalMultisigParentSignerBsms;
  String? get externalMultisigParentMasterFingerprint => _externalMultisigParentMasterFingerprint;
  String? get childWalletDescriptor => _childWalletDescriptor;
  String? get childWalletMasterFingerprint => _childWalletMasterFingerprint;
  Uint8List get childSecret => _childSecret;
  Uint8List? get childPassphrase => _childPassphrase.isNotEmpty ? _childPassphrase : null;
  TaprootChildWalletSource? get childWalletSource => _childWalletSource;
  DateTime? get timelockDateTime => _timelockDateTime;

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase, {bool useTaprootDescriptorQr = false}) {
    _secret = Uint8List.fromList(secret);
    _passphrase = passphrase == null ? Uint8List(0) : Uint8List.fromList(passphrase);

    try {
      final seed = Seed.fromMnemonic(_secret, passphrase: _passphrase.isNotEmpty ? _passphrase : null);

      final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);

      _masterFingerprint = keyStore.masterFingerprint;
      if (useTaprootDescriptorQr) {
        _qrData = TaprootVault.fromKeyStoreList([keyStore], []).descriptor;
      } else {
        _qrData = _getTaprootSignerBsms(seed.mnemonic, seed.passphrase);
      }
    } catch (e) {
      _masterFingerprint = '00000000';
      _qrData = '';
    }

    notifyListeners();
  }

  String _getTaprootSignerBsms(Uint8List mnemonic, Uint8List passphrase) {
    final seed = Seed.fromMnemonic(mnemonic, passphrase: passphrase.isNotEmpty ? passphrase : null);
    final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);
    final taprootVault = TaprootVault.fromKeyStoreList([keyStore], []);
    return taprootVault.getSignerBsms('');
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

  void setChildWallet({
    required String descriptor,
    required String masterFingerprint,
    required TaprootChildWalletSource source,
    Uint8List? secret,
    Uint8List? passphrase,
  }) {
    _childWalletDescriptor = descriptor;
    _childWalletMasterFingerprint = masterFingerprint;
    _childWalletSource = source;
    _childSecret.wipe();
    _childPassphrase.wipe();
    _childSecret = secret == null ? Uint8List(0) : Uint8List.fromList(secret);
    _childPassphrase = passphrase == null ? Uint8List(0) : Uint8List.fromList(passphrase);
    notifyListeners();
  }

  void resetChildWallet() {
    _childWalletDescriptor = null;
    _childWalletMasterFingerprint = null;
    _childWalletSource = null;
    _childSecret.wipe();
    _childPassphrase.wipe();
    _childSecret = Uint8List(0);
    _childPassphrase = Uint8List(0);
    notifyListeners();
  }

  void setTimelockDateTime(DateTime dateTime) {
    _timelockDateTime = dateTime;
    notifyListeners();
  }

  void resetTimelockDateTime() {
    _timelockDateTime = null;
    notifyListeners();
  }

  TaprootWalletCreateDto createWalletCreateDto({
    required String name,
    required int iconIndex,
    required int colorIndex,
  }) {
    final keyPathSeeds = <SeedSource>[];
    final keyPathSignerBsmses = <String>[];
    if (_secret.isNotEmpty) {
      keyPathSeeds.add(SeedSource(mnemonic: Uint8List.fromList(_secret), passphrase: Uint8List.fromList(_passphrase)));
    }
    final externalMultisigParentSignerBsms = _externalMultisigParentSignerBsms;
    if (externalMultisigParentSignerBsms != null) {
      keyPathSignerBsmses.add(externalMultisigParentSignerBsms);
    }
    if (keyPathSeeds.isEmpty && keyPathSignerBsmses.isEmpty) {
      throw StateError('Taproot key-path parent wallet is missing');
    }

    final timelockDateTime = _timelockDateTime;
    final childWalletDescriptor = _childWalletDescriptor;
    final childWalletSource = _childWalletSource;
    if (timelockDateTime == null) {
      throw StateError('Taproot timelock date is missing');
    }
    if (childWalletDescriptor == null) {
      throw StateError('Taproot child wallet descriptor is missing');
    }
    if (childWalletSource == TaprootChildWalletSource.created && _childSecret.isEmpty) {
      throw StateError('Taproot created child wallet seed is missing');
    }

    final inheritanceLeaves = <InheritanceLeaf>[
      if (_childSecret.isNotEmpty)
        InheritanceLeaf(
          secret: SeedSource(
            mnemonic: Uint8List.fromList(_childSecret),
            passphrase: Uint8List.fromList(_childPassphrase),
          ),
          lockTime: timelockDateTime.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond,
        )
      else
        InheritanceLeaf(
          descriptor: childWalletDescriptor,
          lockTime: timelockDateTime.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond,
        ),
    ];

    return TaprootWalletCreateDto(
      null,
      name,
      iconIndex,
      colorIndex,
      keyPathSeeds.isEmpty ? null : keyPathSeeds,
      keyPathSignerBsmses.isEmpty ? null : keyPathSignerBsmses,
      inheritanceLeaves,
    );
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
    _childWalletDescriptor = null;
    _childWalletMasterFingerprint = null;
    _childWalletSource = null;
    _childSecret.wipe();
    _childPassphrase.wipe();
    _childSecret = Uint8List(0);
    _childPassphrase = Uint8List(0);
    _timelockDateTime = null;
    notifyListeners();
  }

  void resetAll() {
    resetSecretAndPassphrase();
  }
}
