import 'dart:convert';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:flutter/foundation.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';

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

  void setScannedTaprootVault(String scannedData) {
    try {
      final decoded = jsonDecode(scannedData);
      if (decoded is Map<String, dynamic>) {
        _scannedVaultItem = TaprootVaultListItem.fromJson(decoded);
      } else {
        _scannedVaultItem = _parseRawDescriptorString(scannedData);
      }
    } catch (e) {
      _scannedVaultItem = _parseRawDescriptorString(scannedData);
    }

    if (_scannedVaultItem != null && _scannedVaultItem!.owners.isNotEmpty) {
      _scannedMasterFingerprint = _scannedVaultItem!.owners.first.masterFingerprint;
    } else {
      _scannedMasterFingerprint = null;
    }

    notifyListeners();
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

  String get scannedParentMfps => _scannedVaultItem?.owners.map((o) => o.masterFingerprint).join(', ') ?? '000000';

  String getFormattedLockTime(String lang) {
    if (_scannedVaultItem == null || _masterFingerprint == null) return '';

    final matching = _scannedVaultItem!.beneficiaries.where((b) => b.masterFingerprint == _masterFingerprint);
    if (matching.isEmpty) return '';

    final lockTime = matching.first.lockTime;
    final date = DateTime.fromMillisecondsSinceEpoch(lockTime * 1000);
    final year = date.year;
    final month = date.month;
    final day = date.day;
    final hour24 = date.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final paddedHour = hour12.toString().padLeft(2, '0');

    if (lang == 'kr') {
      final amPm = hour24 >= 12 ? '오후' : '오전';
      return '$year년 $month월 $day일 $amPm $paddedHour:$minute';
    } else if (lang == 'jp') {
      final amPm = hour24 >= 12 ? '午後' : '午前';
      return '$year年 $month월 $day일 $amPm $paddedHour:$minute';
    } else {
      final amPm = hour24 >= 12 ? 'PM' : 'AM';
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[month - 1]} $day, $year $paddedHour:$minute $amPm';
    }
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

  Future<void> saveVault(WalletProvider walletProvider) async {
    try {
      final dto = createWalletCreateDto();
      Logger.log('[ChildCreationViewModel] Attempting to add taproot vault: ${dto.name}');

      final result = await walletProvider.addTaprootVault(dto);

      Logger.log(
        '[ChildCreationViewModel] Successfully added taproot vault: '
        'ID=${result.id}, '
        'Name=${result.name}, '
        'Owners=${result.owners.length}, '
        'Beneficiaries=${result.beneficiaries.length}',
      );

      dto.wipe();
    } catch (e) {
      Logger.error('[ChildCreationViewModel] saveVault error: $e');
      rethrow;
    }
  }

  TaprootWalletCreateDto createWalletCreateDto() {
    final String? myMfp = _masterFingerprint?.toUpperCase();
    final TaprootVaultListItem? scannedItem = _scannedVaultItem;

    if (scannedItem == null || myMfp == null) {
      throw StateError('Scanned vault or MFP is missing');
    }

    final vault = TaprootVault.fromDescriptor(scannedItem.descriptor);
    final mySeedSource = SeedSource(
      mnemonic: _taprootProvider.secret,
      passphrase: _taprootProvider.passphrase ?? Uint8List(0),
    );

    final (keyPathSeeds, keyPathSignerBsmses) = _mapKeyPathOwners(vault, myMfp, mySeedSource);
    final inheritanceLeaves = _mapInheritanceLeaves(vault, myMfp, mySeedSource);

    return TaprootWalletCreateDto(
      null,
      scannedItem.name,
      scannedItem.iconIndex,
      scannedItem.colorIndex,
      keyPathSeeds.isEmpty ? null : keyPathSeeds,
      keyPathSignerBsmses.isEmpty ? null : keyPathSignerBsmses,
      inheritanceLeaves.isEmpty ? null : inheritanceLeaves,
    );
  }

  (List<SeedSource>, List<String>) _mapKeyPathOwners(TaprootVault vault, String myMfp, SeedSource mySeedSource) {
    final seeds = <SeedSource>[];
    final bsmses = <String>[];

    for (final keyStore in vault.keyStoreList) {
      final mfp = keyStore.masterFingerprint.toUpperCase();
      if (mfp == myMfp) {
        seeds.add(mySeedSource);
      } else {
        final path = WalletUtility.getDerivationPath(AddressType.p2tr, 0).replaceAll('m/', '');
        final xpub = keyStore.extendedPublicKey.serialize();
        bsmses.add('BSMS 1.0\n00\n[$mfp/$path]$xpub');
      }
    }
    return (seeds, bsmses);
  }

  List<InheritanceLeaf> _mapInheritanceLeaves(TaprootVault vault, String myMfp, SeedSource mySeedSource) {
    final leaves = <InheritanceLeaf>[];

    for (final policy in vault.policyList) {
      if (policy is! InheritancePolicy) continue;

      final bMfp = policy.beneficiaryKeyStore.masterFingerprint.toUpperCase();
      if (bMfp == myMfp) {
        leaves.add(InheritanceLeaf(secret: mySeedSource, lockTime: policy.locktime));
      } else {
        leaves.add(
          InheritanceLeaf(
            descriptor: TaprootVault.fromKeyStoreList([policy.beneficiaryKeyStore], []).descriptor,
            lockTime: policy.locktime,
          ),
        );
      }
    }
    return leaves;
  }
}
