import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';

enum ChildKeyPreparationType { none, create, import }

enum ChildNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ChildExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

class InheritanceVaultPolicy {
  static const int maxParents = 2;
  static const int minParents = 1;
  static const int requiredChildren = 1;
}

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

  bool get isBeneficiaryMatch {
    if (_scannedVaultItem == null || _masterFingerprint == null) return false;
    try {
      return _scannedVaultItem!.beneficiaries.any((b) => b.masterFingerprint == _masterFingerprint);
    } catch (e) {
      return false;
    }
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

  bool setScannedTaprootVault(String scannedData) {
    final trimmedData = scannedData.trim();
    if (trimmedData.isEmpty) return false;

    _scannedVaultItem = _tryParseVaultData(trimmedData);

    if (_scannedVaultItem == null || !_validateVault(_scannedVaultItem!)) {
      _scannedVaultItem = null;
      _scannedMasterFingerprint = null;
      notifyListeners();
      return false;
    }

    if (_scannedVaultItem!.owners.isNotEmpty) {
      _scannedMasterFingerprint = _scannedVaultItem!.owners.first.masterFingerprint;
    } else {
      _scannedMasterFingerprint = null;
    }

    notifyListeners();
    return true;
  }

  TaprootVaultListItem? _tryParseVaultData(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return TaprootVaultListItem.fromJson(decoded);
      }
    } catch (_) {
      try {
        return _parseRawDescriptorString(data);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _validateVault(TaprootVaultListItem item) {
    try {
      final String desc = item.descriptor.trim();
      final bool hasValidFormat = desc.isNotEmpty && desc.contains('tr(');
      final bool hasValidParents =
          item.owners.length >= InheritanceVaultPolicy.minParents &&
          item.owners.length <= InheritanceVaultPolicy.maxParents;
      final bool hasValidChildren = item.beneficiaries.length == InheritanceVaultPolicy.requiredChildren;

      return hasValidFormat && hasValidParents && hasValidChildren;
    } catch (e) {
      Logger.error('Vault validation error: $e');
      return false;
    }
  }

  TaprootVaultListItem _parseRawDescriptorString(String data) {
    String innerData = data.trim();
    if (innerData.startsWith('{') && innerData.endsWith('}')) {
      final content = innerData.substring(1, innerData.length - 1).trim();
      return TaprootVaultListItem(
        id: int.tryParse(_extractValue(content, 'id') ?? '') ?? -1,
        name: _extractValue(content, 'name') ?? '스캔된 부모 지갑',
        createdAt: DateTime.tryParse(_extractValue(content, 'createdAt') ?? '') ?? DateTime.now(),
        colorIndex: int.tryParse(_extractValue(content, 'colorIndex') ?? '') ?? 0,
        iconIndex: int.tryParse(_extractValue(content, 'iconIndex') ?? '') ?? 0,
        descriptor: _extractValue(content, 'descriptor') ?? innerData,
        keyPathSeedInfos: const [],
        scriptPathSeedInfos: const [],
      );
    }
    return TaprootVaultListItem(
      id: -1,
      name: '스캔된 부모 지갑',
      colorIndex: 0,
      iconIndex: 0,
      createdAt: DateTime.now(),
      descriptor: innerData,
      keyPathSeedInfos: const [],
      scriptPathSeedInfos: const [],
    );
  }

  String? _extractValue(String content, String key) {
    final match = RegExp('$key:\\s*(.*?)(?=\\s*(?:,\\s*[a-zA-Z0-9_]+:|\$))', dotAll: true).firstMatch(content);
    return match?.group(1)?.trim();
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
