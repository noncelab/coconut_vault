import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
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
  TaprootVaultListItem? _scannedVaultItem;
  String? _scannedMasterFingerprint;

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

  ChildKeyPreparationType get keyPreparationType => _keyPreparationType;
  ChildNewKeyCreationType get newKeyCreationType => _newKeyCreationType;
  ChildExistingKeyImportType get existingKeyImportType => _existingKeyImportType;
  int? get existingVaultId => _existingVaultId;
  String? get qrData => _qrData;
  String? get masterFingerprint => _masterFingerprint;
  TaprootVaultListItem? get scannedVaultItem => _scannedVaultItem;
  String? get scannedMasterFingerprint => _scannedMasterFingerprint;

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

  void resetChildWalletData() {
    _taprootProvider.setCreationType(TaprootCreationType.child);
    _taprootProvider.resetSecretAndPassphrase();
    _qrData = null;
    _masterFingerprint = null;
    notifyListeners();
  }
}
