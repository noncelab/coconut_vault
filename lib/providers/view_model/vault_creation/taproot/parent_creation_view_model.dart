import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';

enum ParentWalletType { none, singleSig, multisig }

enum ParentKeyPreparationType { none, create, import }

enum ParentNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ParentExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

enum ParentAddScriptPathType { none, create, import }

enum ParentSelectionResetScope { walletType, keyPreparation, keyCreationOrImportOption }

enum ChildWalletSetupType { none, import, create }

enum ParentChildWalletSource { scanned, created }

class ParentCreationSaveResult {
  final int vaultId;
  final TaprootVaultCreationTimelineInfo timelineInfo;

  const ParentCreationSaveResult({required this.vaultId, required this.timelineInfo});
}

class ParentCreationViewModel extends ChangeNotifier {
  static const int _walletTypeProgressStepCount = 1;
  static const int _singleSigParentProgressStepCount = 2;
  static const int _multisigParentProgressStepCount = 4;
  static const int _currentVaultSelectionProgressStepCount = 1;
  static const int _childWalletImportProgressStepCount = 4;
  static const int _childWalletCreateExtraProgressStepCount = 1;

  ParentWalletType _selectedWalletType = ParentWalletType.none;
  ParentKeyPreparationType _selectedKeyPreparationType = ParentKeyPreparationType.none;
  ParentNewKeyCreationType _selectedNewKeyCreationType = ParentNewKeyCreationType.none;
  ParentExistingKeyImportType _selectedExistingKeyImportType = ParentExistingKeyImportType.none;
  ChildWalletSetupType _selectedChildWalletSetupType = ChildWalletSetupType.none;
  ParentNewKeyCreationType _selectedChildNewKeyCreationType = ParentNewKeyCreationType.none;
  int? _selectedExistingVaultId;
  DateTime? _selectedTimelockDateTime;
  Uint8List _parentSecret = Uint8List(0);
  Uint8List _parentPassphrase = Uint8List(0);
  Uint8List _childSecret = Uint8List(0);
  Uint8List _childPassphrase = Uint8List(0);
  String? _parentWalletQrData;
  String? _parentMasterFingerprint;
  String? _externalParentSignerBsms;
  String? _externalParentMasterFingerprint;
  String? _childWalletDescriptor;
  String? _childWalletMasterFingerprint;

  ParentWalletType get selectedWalletType => _selectedWalletType;
  ParentKeyPreparationType get selectedKeyPreparationType => _selectedKeyPreparationType;
  ParentNewKeyCreationType get selectedNewKeyCreationType => _selectedNewKeyCreationType;
  ParentExistingKeyImportType get selectedExistingKeyImportType => _selectedExistingKeyImportType;
  ChildWalletSetupType get selectedChildWalletSetupType => _selectedChildWalletSetupType;
  ParentNewKeyCreationType get selectedChildNewKeyCreationType => _selectedChildNewKeyCreationType;
  int? get selectedExistingVaultId => _selectedExistingVaultId;
  DateTime? get selectedTimelockDateTime => _selectedTimelockDateTime;
  String? get parentWalletQrData => _parentWalletQrData;
  String? get parentMasterFingerprint => _parentMasterFingerprint;
  String? get externalParentSignerBsms => _externalParentSignerBsms;
  String? get externalParentMasterFingerprint => _externalParentMasterFingerprint;
  String? get childWalletMasterFingerprint => _childWalletMasterFingerprint;
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
  int get progressTotalStep {
    return _walletTypeProgressStepCount +
        _parentWalletProgressStepCount +
        (_usesCurrentVaultParentKey ? _currentVaultSelectionProgressStepCount : 0) +
        _childWalletImportProgressStepCount +
        (_usesCreatedChildWallet ? _childWalletCreateExtraProgressStepCount : 0);
  }

  int get _parentWalletProgressStepCount {
    return switch (_selectedWalletType) {
      ParentWalletType.multisig => _multisigParentProgressStepCount,
      ParentWalletType.none || ParentWalletType.singleSig => _singleSigParentProgressStepCount,
    };
  }

  bool get _usesCurrentVaultParentKey {
    return _selectedKeyPreparationType == ParentKeyPreparationType.import &&
        _selectedExistingKeyImportType == ParentExistingKeyImportType.currentVault;
  }

  bool get _usesCreatedChildWallet => _selectedChildWalletSetupType == ChildWalletSetupType.create;

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

  void setParentWalletSecret(Uint8List secret, {Uint8List? passphrase}) {
    _parentSecret.wipe();
    _parentPassphrase.wipe();
    _parentSecret = Uint8List.fromList(secret);
    _parentPassphrase = _copyPassphrase(passphrase);
    _updateParentWalletInfo();
    notifyListeners();
  }

  void setExternalParent({required String signerBsms, required String masterFingerprint}) {
    _externalParentSignerBsms = signerBsms;
    _externalParentMasterFingerprint = masterFingerprint;
    notifyListeners();
  }

  void setChildWallet({
    required String descriptor,
    required String masterFingerprint,
    required ParentChildWalletSource source,
    Uint8List? secret,
    Uint8List? passphrase,
  }) {
    _childWalletDescriptor = descriptor;
    _childWalletMasterFingerprint = masterFingerprint;
    _childSecret.wipe();
    _childPassphrase.wipe();
    _childSecret = secret == null ? Uint8List(0) : Uint8List.fromList(secret);
    _childPassphrase = _copyPassphrase(passphrase);
    notifyListeners();
  }

  void resetChildWallet() {
    _childWalletDescriptor = null;
    _childWalletMasterFingerprint = null;
    _childSecret.wipe();
    _childPassphrase.wipe();
    _childSecret = Uint8List(0);
    _childPassphrase = Uint8List(0);
    notifyListeners();
  }

  void resetParentWalletData() {
    _parentSecret.wipe();
    _parentPassphrase.wipe();
    _parentSecret = Uint8List(0);
    _parentPassphrase = Uint8List(0);
    _parentWalletQrData = null;
    _parentMasterFingerprint = null;
    _externalParentSignerBsms = null;
    _externalParentMasterFingerprint = null;
    notifyListeners();
  }

  bool isSameAsParentWallet(String masterFingerprint) {
    final parentMasterFingerprints = [_parentMasterFingerprint, _externalParentMasterFingerprint];
    return parentMasterFingerprints.whereType<String>().any(
      (parentMasterFingerprint) => parentMasterFingerprint.toLowerCase() == masterFingerprint.toLowerCase(),
    );
  }

  Future<ParentCreationSaveResult> saveVault(
    WalletProvider walletProvider, {
    required String name,
    required int iconIndex,
    required int colorIndex,
  }) async {
    TaprootWalletCreateDto? walletCreateDto;
    try {
      walletCreateDto = createWalletCreateDto(name: name, iconIndex: iconIndex, colorIndex: colorIndex);
      final timelineInfo = TaprootVaultCreationTimelineInfo(
        parentMasterFingerprint: _parentMasterFingerprint,
        externalParentMasterFingerprint: _externalParentMasterFingerprint,
        childMasterFingerprint: _childWalletMasterFingerprint,
      );
      final vault = await walletProvider.addTaprootVault(walletCreateDto);
      resetAllWalletData();
      return ParentCreationSaveResult(vaultId: vault.id, timelineInfo: timelineInfo);
    } finally {
      walletCreateDto?.wipe();
    }
  }

  TaprootWalletCreateDto createWalletCreateDto({
    required String name,
    required int iconIndex,
    required int colorIndex,
  }) {
    final keyPathSeeds = <SeedSource>[];
    final keyPathSignerBsmses = <String>[];
    if (_parentSecret.isNotEmpty) {
      keyPathSeeds.add(
        SeedSource(mnemonic: Uint8List.fromList(_parentSecret), passphrase: Uint8List.fromList(_parentPassphrase)),
      );
    }

    final externalParentSignerBsms = _externalParentSignerBsms;
    if (externalParentSignerBsms != null) {
      keyPathSignerBsmses.add(externalParentSignerBsms);
    }

    if (keyPathSeeds.isEmpty && keyPathSignerBsmses.isEmpty) {
      throw StateError('Taproot key-path parent wallet is missing');
    }

    final timelockDateTime = _selectedTimelockDateTime;
    final childWalletDescriptor = _childWalletDescriptor;
    if (timelockDateTime == null) {
      throw StateError('Taproot timelock date is missing');
    }
    if (childWalletDescriptor == null) {
      throw StateError('Taproot child wallet descriptor is missing');
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

  void resetAllWalletData() {
    resetParentWalletData();
    resetChildWallet();
    _selectedTimelockDateTime = null;
  }

  @override
  void dispose() {
    _parentSecret.wipe();
    _parentPassphrase.wipe();
    _childSecret.wipe();
    _childPassphrase.wipe();
    super.dispose();
  }

  void _updateParentWalletInfo() {
    if (_parentSecret.isEmpty) {
      _parentMasterFingerprint = null;
      _parentWalletQrData = null;
      return;
    }

    try {
      final seed = Seed.fromMnemonic(
        _parentSecret,
        passphrase: _parentPassphrase.isNotEmpty ? _parentPassphrase : null,
      );
      final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);
      _parentMasterFingerprint = keyStore.masterFingerprint;
      _parentWalletQrData = TaprootVault.fromKeyStoreList([keyStore], []).descriptor;
    } catch (_) {
      _parentMasterFingerprint = '00000000';
      _parentWalletQrData = '';
    }
  }

  Uint8List _copyPassphrase(Uint8List? passphrase) {
    return passphrase == null ? Uint8List(0) : Uint8List.fromList(passphrase);
  }
}
