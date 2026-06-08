import 'package:coconut_vault/core/wallet/taproot_validator.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/utils/date_format_util.dart';
import 'package:flutter/foundation.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';

enum ChildKeyPreparationType { none, create, import }

enum ChildNewKeyCreationType { none, coinFlip, diceRoll, autoGenerate }

enum ChildExistingKeyImportType { none, currentVault, mnemonicInput, seedQrScan }

typedef ChildWalletSyncDuplicateChecker = bool Function(String descriptor);

class ChildCreationViewModel extends ChangeNotifier {
  static const int _initialProgressExcludedStepCount = 1;
  static const int _keyPreparationProgressStepCount = 1;
  static const int _keyCreationOrImportOptionProgressStepCount = 1;
  static const int _currentVaultSelectionProgressStepCount = 1;
  static const int _childWalletQrProgressStepCount = 1;
  static const int _parentWalletScanProgressStepCount = 1;
  static const int _summaryProgressStepCount = 1;
  //static const int _timelineProgressStepCount = 1;

  final TaprootWalletCreationProvider _taprootProvider;
  final WalletProvider _walletProvider;

  ChildKeyPreparationType _keyPreparationType = ChildKeyPreparationType.none;
  ChildNewKeyCreationType _newKeyCreationType = ChildNewKeyCreationType.none;
  ChildExistingKeyImportType _existingKeyImportType = ChildExistingKeyImportType.none;
  int? _existingVaultId;
  String? _childDescriptor;
  String? _masterFingerprint;
  TaprootVaultListItem? _scannedVaultItem;
  TaprootVaultListItem? _addedWallet;

  ChildCreationViewModel(this._taprootProvider, this._walletProvider);

  void setCreationTypeToChild() {
    _taprootProvider.setCreationType(TaprootCreationType.child);
  }

  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _taprootProvider.setSecretAndPassphrase(secret, passphrase);
  }

  bool get isBeneficiaryMatch {
    if (_scannedVaultItem == null || _childDescriptor == null) return false;
    try {
      return TaprootValidator.isBeneficiaryMatchedByDescriptor(
        inheritanceDescriptor: _scannedVaultItem!.descriptor,
        childDescriptor: _childDescriptor!,
      );
    } catch (e) {
      return false;
    }
  }

  ({KeyStore keyStore, String descriptor}) _generateKeyStoreAndDescriptor(Uint8List secret, Uint8List? passphrase) {
    final ks = KeyStore.fromSeed(Seed.fromMnemonic(secret, passphrase: passphrase), AddressType.p2tr);
    final descriptor = TaprootVault.fromKeyStoreList([ks], []).descriptor;
    return (keyStore: ks, descriptor: descriptor);
  }

  void setupChildWalletInfo() {
    final secret = _taprootProvider.secret;
    final passphrase = _taprootProvider.passphrase;

    if (secret.isEmpty) {
      throw StateError('child secret is empty');
    }

    final result = _generateKeyStoreAndDescriptor(secret, passphrase);
    _childDescriptor = result.descriptor;
    _masterFingerprint = result.keyStore.masterFingerprint;
    notifyListeners();
  }

  bool setScannedTaprootVault(TaprootWalletSyncData syncData) {
    final descriptor = syncData.descriptor.trim();
    if (descriptor.isEmpty) return false;

    final item = TaprootVaultListItem(
      id: -1,
      name: syncData.name,
      createdAt: DateTime.now(),
      colorIndex: syncData.colorIndex,
      iconIndex: syncData.iconIndex,
      descriptor: descriptor,
      keyPathSeedInfos: const [],
      scriptPathSeedInfos: const [],
    );

    if (!_validateVault(item)) {
      _scannedVaultItem = null;
      notifyListeners();
      return false;
    }

    _scannedVaultItem = item;
    notifyListeners();
    return true;
  }

  String? findSameWalletName(String descriptor) {
    final result = _walletProvider.findWalletByDescriptor(descriptor);
    return result?.name;
  }

  bool _validateVault(TaprootVaultListItem item) {
    try {
      TaprootValidator.parseInheritanceVaultDescriptor(item.descriptor);
      return true;
    } catch (e) {
      Logger.error('Vault validation error: $e');
      return false;
    }
  }

  String get scannedParentMfps => _scannedVaultItem?.owners.map((o) => o.masterFingerprint).join(', ') ?? '';

  String getFormattedLockTime(String lang) {
    if (_scannedVaultItem == null || _masterFingerprint == null) return '';

    final matching = _scannedVaultItem!.beneficiaries.where((b) => b.masterFingerprint == _masterFingerprint);
    if (matching.isEmpty) return '';

    final datetime = DateTime.fromMillisecondsSinceEpoch(matching.first.lockTime * 1000);
    return DateFormatUtil.formatLocalizedDateTime(datetime, lang);
  }

  ChildKeyPreparationType get keyPreparationType => _keyPreparationType;
  ChildNewKeyCreationType get newKeyCreationType => _newKeyCreationType;
  ChildExistingKeyImportType get existingKeyImportType => _existingKeyImportType;
  int? get existingVaultId => _existingVaultId;
  String? get qrData => _childDescriptor;
  String? get masterFingerprint => _masterFingerprint;
  TaprootVaultListItem? get scannedVaultItem => _scannedVaultItem;
  int? get addedWalletId => _addedWallet?.id;
  int get progressTotalStep {
    return _keyPreparationProgressStepCount +
        _keyCreationOrImportOptionProgressStepCount +
        (_usesCurrentVault ? _currentVaultSelectionProgressStepCount : 0) +
        _childWalletQrProgressStepCount +
        _parentWalletScanProgressStepCount +
        _summaryProgressStepCount;
  }

  int get visibleProgressStepCount => progressTotalStep + _initialProgressExcludedStepCount;

  bool get _usesCurrentVault => _existingKeyImportType == ChildExistingKeyImportType.currentVault;

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
    _childDescriptor = null;
    _masterFingerprint = null;
    notifyListeners();
  }

  Future<void> saveVault() async {
    TaprootWalletCreateDto? dto;
    try {
      dto = _createWalletCreateDto();
      Logger.log('[ChildCreationViewModel] Attempting to add taproot vault: ${dto.name}');

      _addedWallet = await _walletProvider.addTaprootVault(dto);
      Logger.log(
        '[ChildCreationViewModel] Successfully added taproot vault: '
        'ID=${_addedWallet?.id}, '
        'Name=${_addedWallet?.name}, '
        'Owners=${_addedWallet?.owners.length}, '
        'Beneficiaries=${_addedWallet?.beneficiaries.length}',
      );
    } catch (e) {
      Logger.error('[ChildCreationViewModel] saveVault error: $e');
      rethrow;
    } finally {
      dto?.wipe();
    }
  }

  TaprootWalletCreateDto _createWalletCreateDto() {
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

    final keyPathSignerBsmses = _mapKeyPathOwners(vault, myMfp);
    final inheritanceLeaf = _mapInheritanceLeaves(vault, myMfp, mySeedSource);

    return TaprootWalletCreateDto(
      null,
      scannedItem.name,
      scannedItem.iconIndex,
      scannedItem.colorIndex,
      null,
      keyPathSignerBsmses,
      inheritanceLeaf,
    );
  }

  List<String> _mapKeyPathOwners(TaprootVault vault, String myMfp) {
    return vault.keyStoreList.map((keyStore) {
      final mfp = keyStore.masterFingerprint.toUpperCase();
      if (mfp == myMfp) {
        throw StateError('Child MFP must not be included as a key-path owner');
      }

      return Bsms.fromSigner(
        mfp,
        vault.derivationPath.replaceAll('m/', ''),
        keyStore.extendedPublicKey.serialize(),
        '',
      ).serializeSigner();
    }).toList();
    // final bsmses = <String>[];

    // for (final keyStore in vault.keyStoreList) {
    //   final mfp = keyStore.masterFingerprint.toUpperCase();
    //   if (mfp == myMfp) {
    //     throw StateError('Child MFP must not be included as a key-path owner');
    //   } else {
    //     final path = WalletUtility.getDerivationPath(AddressType.p2tr, 0).replaceAll('m/', '');
    //     //final xpub = keyStore.extendedPublicKey.serialize();
    //     bsmses.add(Bsms.fromSigner(
    //       keyStore.masterFingerprint,
    //       path,
    //       keyStore.extendedPublicKey.serialize(),
    //       ''
    //     ).serializeSigner());
    //     //bsmses.add('BSMS 1.0\n00\n[$mfp/$path]$xpub');
    //   }
    // }
    // return bsmses;
  }

  List<InheritanceLeaf> _mapInheritanceLeaves(TaprootVault vault, String myMfp, SeedSource mySeedSource) {
    if (vault.policyList.length != 1) throw StateError('No policy in TaprootVault');
    if (vault.policyList.single is! InheritancePolicy) throw StateError('Only one inheritancePolicy required.');
    final inheritancePolicy = vault.policyList.single as InheritancePolicy;
    final bMfp = inheritancePolicy.beneficiaryKeyStore.masterFingerprint.toUpperCase();

    if (bMfp == myMfp) {
      return [InheritanceLeaf(secret: mySeedSource, lockTime: inheritancePolicy.locktime)];
    } else {
      throw StateError('InheritancePolicy was not made from my seed source');
      // InheritanceLeaf(
      //       descriptor: TaprootVault.fromKeyStoreList([policy.beneficiaryKeyStore], []).descriptor,
      //       lockTime: policy.locktime,
      //     ),
    }
  }
}
