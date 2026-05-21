import 'package:flutter/foundation.dart';

enum ParentWalletType { none, singleSig, multisig }

enum ParentKeyPreparationType { none, create, import }

enum ParentNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ParentExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

enum ParentAddScriptPathType { none, create, import }

enum ParentSelectionResetScope { walletType, keyPreparation, keyCreationOrImportOption }

enum ChildWalletSetupType { none, import, create }

class ParentCreationViewModel extends ChangeNotifier {
  ParentWalletType _selectedWalletType = ParentWalletType.none;
  ParentKeyPreparationType _selectedKeyPreparationType = ParentKeyPreparationType.none;
  ParentNewKeyCreationType _selectedNewKeyCreationType = ParentNewKeyCreationType.none;
  ParentExistingKeyImportType _selectedExistingKeyImportType = ParentExistingKeyImportType.none;
  ChildWalletSetupType _selectedChildWalletSetupType = ChildWalletSetupType.none;
  ParentNewKeyCreationType _selectedChildNewKeyCreationType = ParentNewKeyCreationType.none;
  int? _selectedExistingVaultId;
  DateTime? _selectedTimelockDateTime;

  ParentWalletType get selectedWalletType => _selectedWalletType;
  ParentKeyPreparationType get selectedKeyPreparationType => _selectedKeyPreparationType;
  ParentNewKeyCreationType get selectedNewKeyCreationType => _selectedNewKeyCreationType;
  ParentExistingKeyImportType get selectedExistingKeyImportType => _selectedExistingKeyImportType;
  ChildWalletSetupType get selectedChildWalletSetupType => _selectedChildWalletSetupType;
  ParentNewKeyCreationType get selectedChildNewKeyCreationType => _selectedChildNewKeyCreationType;
  int? get selectedExistingVaultId => _selectedExistingVaultId;
  DateTime? get selectedTimelockDateTime => _selectedTimelockDateTime;
  bool get hasSelectedKeyCreationOrImportOption {
    return switch (_selectedKeyPreparationType) {
      ParentKeyPreparationType.create => _selectedNewKeyCreationType != ParentNewKeyCreationType.none,
      ParentKeyPreparationType.import => _selectedExistingKeyImportType != ParentExistingKeyImportType.none,
      ParentKeyPreparationType.none => false,
    };
  }

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
    _selectedExistingVaultId = null;
    notifyListeners();
  }

  void setSelectedExistingVaultId(int vaultId) {
    _selectedExistingVaultId = _selectedExistingVaultId == vaultId ? null : vaultId;
    notifyListeners();
  }

  void resetSelection(ParentSelectionResetScope scope) {
    if (scope == ParentSelectionResetScope.walletType) {
      _selectedWalletType = ParentWalletType.none;
    }

    if (scope == ParentSelectionResetScope.walletType || scope == ParentSelectionResetScope.keyPreparation) {
      _selectedKeyPreparationType = ParentKeyPreparationType.none;
    }

    _resetKeyOptionSelection();
    notifyListeners();
  }

  void _resetKeyOptionSelection() {
    _selectedNewKeyCreationType = ParentNewKeyCreationType.none;
    _selectedExistingKeyImportType = ParentExistingKeyImportType.none;
    _selectedExistingVaultId = null;
  }

  void setChildWalletSetupType(ChildWalletSetupType type) {
    if (_selectedChildWalletSetupType == type) {
      return;
    }

    _selectedChildWalletSetupType = type;
    notifyListeners();
  }

  void setChildNewKeyCreationType(ParentNewKeyCreationType type) {
    _selectedChildNewKeyCreationType = _selectedChildNewKeyCreationType == type ? ParentNewKeyCreationType.none : type;
    notifyListeners();
  }

  void resetChildNewKeyCreationType() {
    _selectedChildNewKeyCreationType = ParentNewKeyCreationType.none;
    notifyListeners();
  }

  void setTimelockDateTime(DateTime dateTime) {
    _selectedTimelockDateTime = dateTime;
    notifyListeners();
  }

  void resetTimelockDateTime() {
    _selectedTimelockDateTime = null;
    notifyListeners();
  }
}
