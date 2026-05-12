import 'package:flutter/foundation.dart';

enum ParentWalletType { none, singleSig, multisig }

enum ParentKeyPreparationType { none, create, import }

enum ParentNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ParentExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

class ParentCreationViewModel extends ChangeNotifier {
  ParentWalletType _selectedWalletType = ParentWalletType.none;
  ParentKeyPreparationType _selectedKeyPreparationType = ParentKeyPreparationType.none;
  ParentNewKeyCreationType _selectedNewKeyCreationType = ParentNewKeyCreationType.none;
  ParentExistingKeyImportType _selectedExistingKeyImportType = ParentExistingKeyImportType.none;

  ParentWalletType get selectedWalletType => _selectedWalletType;
  ParentKeyPreparationType get selectedKeyPreparationType => _selectedKeyPreparationType;
  ParentNewKeyCreationType get selectedNewKeyCreationType => _selectedNewKeyCreationType;
  ParentExistingKeyImportType get selectedExistingKeyImportType => _selectedExistingKeyImportType;
  bool get isSingleSigSelected => _selectedWalletType == ParentWalletType.singleSig;
  bool get isMultisigSelected => _selectedWalletType == ParentWalletType.multisig;
  bool get isCreateKeySelected => _selectedKeyPreparationType == ParentKeyPreparationType.create;
  bool get isImportKeySelected => _selectedKeyPreparationType == ParentKeyPreparationType.import;
  bool get isCoinFlipSelected => _selectedNewKeyCreationType == ParentNewKeyCreationType.coinFlip;
  bool get isDiceRollSelected => _selectedNewKeyCreationType == ParentNewKeyCreationType.diceRoll;
  bool get isAutoGenerateSelected => _selectedNewKeyCreationType == ParentNewKeyCreationType.autoGenerate;
  bool get isCurrentVaultSelected => _selectedExistingKeyImportType == ParentExistingKeyImportType.currentVault;
  bool get isMnemonicInputSelected => _selectedExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput;
  bool get isSeedQrScanSelected => _selectedExistingKeyImportType == ParentExistingKeyImportType.seedQrScan;

  void setWalletType(ParentWalletType type) {
    _selectedWalletType = _selectedWalletType == type ? ParentWalletType.none : type;
    _selectedKeyPreparationType = ParentKeyPreparationType.none;
    _resetKeyOptionSelection();
    notifyListeners();
  }

  void setKeyPreparationType(ParentKeyPreparationType type) {
    _selectedKeyPreparationType = _selectedKeyPreparationType == type ? ParentKeyPreparationType.none : type;
    _resetKeyOptionSelection();
    notifyListeners();
  }

  void setNewKeyCreationType(ParentNewKeyCreationType type) {
    _selectedNewKeyCreationType = _selectedNewKeyCreationType == type ? ParentNewKeyCreationType.none : type;
    notifyListeners();
  }

  void setExistingKeyImportType(ParentExistingKeyImportType type) {
    _selectedExistingKeyImportType = _selectedExistingKeyImportType == type ? ParentExistingKeyImportType.none : type;
    notifyListeners();
  }

  void _resetKeyOptionSelection() {
    _selectedNewKeyCreationType = ParentNewKeyCreationType.none;
    _selectedExistingKeyImportType = ParentExistingKeyImportType.none;
  }
}
