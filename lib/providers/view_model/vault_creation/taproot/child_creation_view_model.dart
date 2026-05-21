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

  void generateKeyData() {
    final secret = _taprootProvider.secret;
    final passphrase = _taprootProvider.passphrase;

    if (secret.isEmpty) return;

    try {
      final seed = Seed.fromMnemonic(
        secret,
        passphrase: (passphrase != null && passphrase.isNotEmpty) ? passphrase : Uint8List(0),
      );
      final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);

      _masterFingerprint = keyStore.masterFingerprint;

      final coinIndex = NetworkType.currentNetworkType == NetworkType.mainnet ? 0 : 1;
      final xpub = keyStore.extendedPublicKey.serialize();
      _qrData = "tr([$_masterFingerprint/86'/$coinIndex'/0']$xpub/<0;1>/*)";
    } catch (e) {
      Logger.error('Failed to generate key data: $e');
    }
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
