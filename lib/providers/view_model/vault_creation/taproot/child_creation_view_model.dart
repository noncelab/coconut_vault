import 'package:flutter/foundation.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';

enum ChildKeyPreparationType { none, create, import }

enum ChildNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ChildExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

class ChildCreationViewModel extends ChangeNotifier {
  final TaprootWalletCreationProvider _taprootProvider;

  ChildKeyPreparationType _selectedKeyPreparationType = ChildKeyPreparationType.none;
  ChildNewKeyCreationType _selectedNewKeyCreationType = ChildNewKeyCreationType.none;
  ChildExistingKeyImportType _selectedExistingKeyImportType = ChildExistingKeyImportType.none;
  int? _selectedExistingVaultId;
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

  ChildKeyPreparationType get selectedKeyPreparationType => _selectedKeyPreparationType;
  ChildNewKeyCreationType get selectedNewKeyCreationType => _selectedNewKeyCreationType;
  ChildExistingKeyImportType get selectedExistingKeyImportType => _selectedExistingKeyImportType;
  int? get selectedExistingVaultId => _selectedExistingVaultId;
  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;

  bool get isCreateKeySelected => _selectedKeyPreparationType == ChildKeyPreparationType.create;
  bool get isImportKeySelected => _selectedKeyPreparationType == ChildKeyPreparationType.import;
  bool get isCoinFlipSelected => _selectedNewKeyCreationType == ChildNewKeyCreationType.coinFlip;
  bool get isDiceRollSelected => _selectedNewKeyCreationType == ChildNewKeyCreationType.diceRoll;
  bool get isAutoGenerateSelected => _selectedNewKeyCreationType == ChildNewKeyCreationType.autoGenerate;
  bool get isCurrentVaultSelected => _selectedExistingKeyImportType == ChildExistingKeyImportType.currentVault;
  bool get isMnemonicInputSelected => _selectedExistingKeyImportType == ChildExistingKeyImportType.mnemonicInput;
  bool get isSeedQrScanSelected => _selectedExistingKeyImportType == ChildExistingKeyImportType.seedQrScan;

  void setKeyPreparationType(ChildKeyPreparationType type) {
    _selectedKeyPreparationType = _selectedKeyPreparationType == type ? ChildKeyPreparationType.none : type;
    _resetKeyOptionSelection();
    notifyListeners();
  }

  void setNewKeyCreationType(ChildNewKeyCreationType type) {
    _selectedNewKeyCreationType = _selectedNewKeyCreationType == type ? ChildNewKeyCreationType.none : type;
    notifyListeners();
  }

  void setExistingKeyImportType(ChildExistingKeyImportType type) {
    _selectedExistingKeyImportType = _selectedExistingKeyImportType == type ? ChildExistingKeyImportType.none : type;
    _selectedExistingVaultId = null;
    notifyListeners();
  }

  void setSelectedExistingVaultId(int vaultId) {
    _selectedExistingVaultId = _selectedExistingVaultId == vaultId ? null : vaultId;
    notifyListeners();
  }

  void _resetKeyOptionSelection() {
    _selectedNewKeyCreationType = ChildNewKeyCreationType.none;
    _selectedExistingKeyImportType = ChildExistingKeyImportType.none;
    _selectedExistingVaultId = null;
  }
}
