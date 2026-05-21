import 'package:flutter/foundation.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';

enum ChildKeyPreparationType { none, create, import }

enum ChildNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ChildExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

class ChildCreationViewModel extends ChangeNotifier {
  final TaprootWalletCreationProvider _taprootProvider;

  ChildKeyPreparationType _keyPreparationType = ChildKeyPreparationType.none;
  ChildNewKeyCreationType _newKeyCreationType = ChildNewKeyCreationType.none;
  ChildExistingKeyImportType _existingKeyImportType = ChildExistingKeyImportType.none;
  int? _existingVaultId;
  String? _qrData;
  String? _masterFingerprint;

  ChildCreationViewModel(this._taprootProvider);

  void setCreationTypeToChild() {
    _taprootProvider.setCreationType(TaprootCreationType.child);
  }

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _taprootProvider.setSecretAndPassphrase(secret, passphrase);
  }

  void setupChildWalletInfo() {
    final secret = _taprootProvider.secret;
    final passphrase = _taprootProvider.passphrase;

    if (secret.isEmpty) return;

    try {
      final result = _generateKeyStoreAndDescriptor(secret, passphrase);
      _setQrDataAndFingerprint(result.descriptor, result.keyStore.masterFingerprint);
    } catch (e) {
      Logger.error('Failed to setup child wallet info: $e');
    }
  }

  ({KeyStore keyStore, String descriptor}) _generateKeyStoreAndDescriptor(Uint8List secret, Uint8List? passphrase) {
    final ks = KeyStore.fromSeed(Seed.fromMnemonic(secret, passphrase: passphrase), AddressType.p2tr);
    final descriptor = TaprootVault.fromKeyStoreList([ks], []).descriptor;
    return (keyStore: ks, descriptor: descriptor);
  }

  void _setQrDataAndFingerprint(String qrData, String masterFingerprint) {
    _qrData = qrData;
    _masterFingerprint = masterFingerprint;
    notifyListeners();
  }

  ChildKeyPreparationType get keyPreparationType => _keyPreparationType;
  ChildNewKeyCreationType get newKeyCreationType => _newKeyCreationType;
  ChildExistingKeyImportType get existingKeyImportType => _existingKeyImportType;
  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;

  void setKeyPreparationType(ChildKeyPreparationType type) {
    _keyPreparationType = _keyPreparationType == type ? ChildKeyPreparationType.none : type;
    _resetKeyOptionSelection();
    notifyListeners();
  }

  void setNewKeyCreationType(ChildNewKeyCreationType type) {
    _newKeyCreationType = _newKeyCreationType == type ? ChildNewKeyCreationType.none : type;
    notifyListeners();
  }

  void setExistingKeyImportType(ChildExistingKeyImportType type) {
    _existingKeyImportType = _existingKeyImportType == type ? ChildExistingKeyImportType.none : type;
    _existingVaultId = null;
    notifyListeners();
  }

  void setExistingVaultId(int vaultId) {
    _existingVaultId = _existingVaultId == vaultId ? null : vaultId;
    notifyListeners();
  }

  void _resetKeyOptionSelection() {
    _newKeyCreationType = ChildNewKeyCreationType.none;
    _existingKeyImportType = ChildExistingKeyImportType.none;
    _existingVaultId = null;
  }
}
