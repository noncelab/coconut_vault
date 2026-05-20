import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';

enum ChildKeyPreparationType { none, create, import }

enum ChildNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ChildExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

class ChildCreationViewModel extends ChangeNotifier {
  ChildKeyPreparationType _selectedKeyPreparationType = ChildKeyPreparationType.none;
  ChildNewKeyCreationType _selectedNewKeyCreationType = ChildNewKeyCreationType.none;
  ChildExistingKeyImportType _selectedExistingKeyImportType = ChildExistingKeyImportType.none;
  int? _selectedExistingVaultId;
  String? _qrData;
  String? _masterFingerprint;
  TaprootVaultListItem? _scannedVaultItem;
  String? _scannedMasterFingerprint;

  ChildCreationViewModel();

  void generateKeyData(Uint8List secret, Uint8List? passphrase) {
    if (secret.isEmpty) return;

    try {
      final seed = Seed.fromMnemonic(
        secret,
        passphrase: (passphrase != null && passphrase.isNotEmpty) ? passphrase : Uint8List(0),
      );
      final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);

      _masterFingerprint = keyStore.masterFingerprint;
      _qrData = keyStore.extendedPublicKey.serialize();
    } catch (e) {
      Logger.error('Failed to generate key data: $e');
      _masterFingerprint = '00000000';
      _qrData = '';
    }
    notifyListeners();
  }

  void setScannedTaprootVault(String scannedData) {
    String descriptor = '';
    String name = '스캔된 부모 지갑';
    int colorIndex = 0;
    int iconIndex = 0;
    int id = -1;
    DateTime createdAt = DateTime.now();

    try {
      final decoded = jsonDecode(scannedData);
      if (decoded is Map<String, dynamic>) {
        descriptor = decoded['descriptor'] as String? ?? '';
        name = decoded['name'] as String? ?? name;
        colorIndex = decoded['colorIndex'] as int? ?? colorIndex;
        iconIndex = decoded['iconIndex'] as int? ?? iconIndex;
        id = decoded['id'] as int? ?? id;

        final createdAtStr = decoded['createdAt'] as String?;
        if (createdAtStr != null) {
          createdAt = DateTime.tryParse(createdAtStr) ?? createdAt;
        }
      }
    } catch (e) {
      String innerData = scannedData.trim();

      if (innerData.startsWith('{') && innerData.endsWith('}')) {
        innerData = innerData.substring(1, innerData.length - 1).trim();

        final nameMatch = RegExp(r'name:\s*(.*?)(?=\s*(?:,\s*[a-zA-Z0-9_]+:|$))').firstMatch(innerData);
        if (nameMatch != null) name = nameMatch.group(1)?.trim() ?? name;

        final colorMatch = RegExp(r'colorIndex:\s*(\d+)').firstMatch(innerData);
        if (colorMatch != null) colorIndex = int.tryParse(colorMatch.group(1)!) ?? colorIndex;

        final iconMatch = RegExp(r'iconIndex:\s*(\d+)').firstMatch(innerData);
        if (iconMatch != null) iconIndex = int.tryParse(iconMatch.group(1)!) ?? iconIndex;

        final idMatch = RegExp(r'id:\s*(\d+)').firstMatch(innerData);
        if (idMatch != null) id = int.tryParse(idMatch.group(1)!) ?? id;

        final createdAtMatch = RegExp(r'createdAt:\s*(.*?)(?=\s*(?:,\s*[a-zA-Z0-9_]+:|$))').firstMatch(innerData);
        if (createdAtMatch != null) {
          final parsed = DateTime.tryParse(createdAtMatch.group(1)?.trim() ?? '');
          if (parsed != null) createdAt = parsed;
        }

        final descriptorMatch = RegExp(
          r'descriptor:\s*(.*?)(?=\s*(?:,\s*[a-zA-Z0-9_]+:|$))',
          dotAll: true,
        ).firstMatch(innerData);
        if (descriptorMatch != null) {
          descriptor = descriptorMatch.group(1)?.trim() ?? '';
        } else {
          descriptor = scannedData.trim();
        }
      } else {
        descriptor = scannedData.trim();
      }
    }

    final mfpRegex = RegExp(r'tr\(\[([0-9a-fA-F]{8})\/.*');
    final match = mfpRegex.firstMatch(descriptor);
    if (match != null && match.groupCount >= 1) {
      _scannedMasterFingerprint = match.group(1);
    } else {
      _scannedMasterFingerprint = null;
    }

    try {
      _scannedVaultItem = TaprootVaultListItem(
        id: id,
        name: name,
        createdAt: createdAt,
        colorIndex: colorIndex,
        iconIndex: iconIndex,
        descriptor: descriptor,
        keyPathSeedInfos: const [],
        scriptPathSeedInfos: const [],
      );
    } catch (e) {
      Logger.error('Failed to create TaprootVaultListItem from descriptor: $e');
      _scannedVaultItem = null;
    }

    notifyListeners();
  }

  ChildKeyPreparationType get selectedKeyPreparationType => _selectedKeyPreparationType;
  ChildNewKeyCreationType get selectedNewKeyCreationType => _selectedNewKeyCreationType;
  ChildExistingKeyImportType get selectedExistingKeyImportType => _selectedExistingKeyImportType;
  int? get selectedExistingVaultId => _selectedExistingVaultId;
  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;
  TaprootVaultListItem? get scannedVaultItem => _scannedVaultItem;
  String? get scannedMasterFingerprint => _scannedMasterFingerprint;

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
