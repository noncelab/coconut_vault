import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/core/wallet/taproot_validator.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/model/taproot/stored_taproot_seed_info.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

enum TaprootImportRole { none, signer, beneficiary }

enum ImportMode { enter, scan }

typedef TaprootWalletSyncDuplicateChecker = VaultListItemBase? Function(String descriptor);
typedef TaprootVaultAdder = Future<TaprootVaultListItem> Function(TaprootWalletCreateDto walletCreateDto);
typedef TaprootBackupUpdateNotifier = Future<void> Function(int walletId);

class TaprootImportParticipantCardState {
  final TaprootImportRole role;
  final String masterFingerprint;
  final String derivationPath;
  final int? lockTime;
  final int? signerIndex;
  final bool hasSingleParent;
  final bool hasBackgroundColor;
  final bool isMine;
  final bool isValid;
  final bool canAddExtra;

  const TaprootImportParticipantCardState({
    required this.role,
    required this.masterFingerprint,
    required this.derivationPath,
    required this.hasBackgroundColor,
    required this.isMine,
    required this.isValid,
    required this.canAddExtra,
    this.lockTime,
    this.signerIndex,
    this.hasSingleParent = false,
  });
}

class TaprootImportSaveResult {
  final int vaultId;
  final String? parentMasterFingerprint;
  final String? externalParentMasterFingerprint;
  final String? childMasterFingerprint;

  const TaprootImportSaveResult({
    required this.vaultId,
    this.parentMasterFingerprint,
    this.externalParentMasterFingerprint,
    this.childMasterFingerprint,
  });
}

class _DerivedTaprootImportSeed {
  final String extendedPublicKey;
  final String masterFingerprint;
  final bool isSelectedRoleMatch;
  final String importedSingleKeyDescriptor;
  final String importedSignerBsms;

  const _DerivedTaprootImportSeed({
    required this.extendedPublicKey,
    required this.masterFingerprint,
    required this.isSelectedRoleMatch,
    required this.importedSingleKeyDescriptor,
    required this.importedSignerBsms,
  });
}

class _ImportedTaprootSeed {
  final TaprootImportRole role;
  final String extendedPublicKey;
  final String masterFingerprint;
  final Uint8List secret;
  final Uint8List passphrase;
  final bool isMatched;

  _ImportedTaprootSeed({
    required this.role,
    required this.extendedPublicKey,
    required this.masterFingerprint,
    required Uint8List secret,
    required Uint8List? passphrase,
    required this.isMatched,
  }) : secret = Uint8List.fromList(secret),
       passphrase = Uint8List.fromList(passphrase ?? Uint8List(0));

  SeedSource toSeedSource() {
    return SeedSource(mnemonic: Uint8List.fromList(secret), passphrase: Uint8List.fromList(passphrase));
  }

  void wipe() {
    secret.fillRange(0, secret.length, 0);
    passphrase.fillRange(0, passphrase.length, 0);
  }
}

class TaprootImportViewModel extends ChangeNotifier {
  static const int _progressStepCount = 4;

  final TaprootWalletSyncDuplicateChecker _findWalletByDescriptor;
  final TaprootVaultAdder _addTaprootVault;
  final TaprootBackupUpdateNotifier _addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate;
  TaprootWalletSyncData? _walletSyncData;
  TaprootVaultListItem? _scannedVaultItem;
  TaprootVaultListItem? _scannedExtraVaultItem;
  TaprootImportRole _selectedRole = TaprootImportRole.none;
  ImportMode _currentImportMode = ImportMode.enter;
  String? _masterFingerprint;
  String? _selectedExtendedPublicKey;
  TaprootImportRole _extraImportRole = TaprootImportRole.none;
  String? _extraTargetMasterFingerprint;
  String? _extraMasterFingerprint;
  _ImportedTaprootSeed? _primaryImportedSeed;
  _ImportedTaprootSeed? _extraImportedSeed;
  bool _isImportingExtra = false;
  bool _isSelectedRoleMatch = true;
  bool _hasExtraImport = false;
  bool _isExtraImportMatched = false;

  TaprootImportViewModel({
    required TaprootWalletSyncDuplicateChecker findWalletByDescriptor,
    required TaprootVaultAdder addTaprootVault,
    required TaprootBackupUpdateNotifier addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate,
  }) : _findWalletByDescriptor = findWalletByDescriptor,
       _addTaprootVault = addTaprootVault,
       _addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate = addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate;

  TaprootVaultListItem? get scannedVaultItem => _scannedVaultItem;
  TaprootVaultListItem? get scannedExtraVaultItem => _scannedExtraVaultItem;
  TaprootImportRole get selectedRole => _selectedRole;
  ImportMode get currentImportMode => _currentImportMode;
  String? get masterFingerprint => _masterFingerprint;
  TaprootImportRole get extraImportRole => _extraImportRole;
  String? get extraTargetMasterFingerprint => _extraTargetMasterFingerprint;
  String? get extraMasterFingerprint => _extraMasterFingerprint;
  bool get isSelectedRoleMatch => _isSelectedRoleMatch;
  bool get hasExtraImport => _hasExtraImport;
  bool get isExtraImportMatched => _isExtraImportMatched;
  int get progressTotalStep => _progressStepCount;

  bool isValidDescriptor(String descriptor) {
    try {
      TaprootValidator.parseInheritanceVaultDescriptor(descriptor);
      return true;
    } catch (e) {
      Logger.error(e);
      return false;
    }
  }

  String? findSameWalletName(String descriptor) {
    final wallet = _findWalletByDescriptor(descriptor);
    return wallet?.name;
  }

  void setWalletSyncData(TaprootWalletSyncData walletSyncData) {
    _walletSyncData = walletSyncData;
    if (scannedVaultItem == null) {
      _scannedVaultItem = _buildScannedVaultItem();
    } else {
      _scannedExtraVaultItem = _buildScannedVaultItem();
    }
    debugPrint('TaprootImportViewModel walletSyncData: ${walletSyncData.toJson()}');
    notifyListeners();
  }

  void setRole(TaprootImportRole role) {
    _selectedRole = _selectedRole == role ? TaprootImportRole.none : role;
    notifyListeners();
  }

  void reset() {
    _wipeImportedSeeds();
    _walletSyncData = null;
    _scannedVaultItem = null;
    _scannedExtraVaultItem = null;
    _selectedRole = TaprootImportRole.none;
    _masterFingerprint = null;
    _selectedExtendedPublicKey = null;
    _extraImportRole = TaprootImportRole.none;
    _extraTargetMasterFingerprint = null;
    _extraMasterFingerprint = null;
    _primaryImportedSeed = null;
    _extraImportedSeed = null;
    _isImportingExtra = false;
    _isSelectedRoleMatch = true;
    _hasExtraImport = false;
    _isExtraImportMatched = false;
    notifyListeners();
  }

  void setImportMode(ImportMode mode) {
    _currentImportMode = mode;
    notifyListeners();
  }

  void startExtraImport(TaprootImportRole role, {required String targetMasterFingerprint}) {
    _extraImportedSeed?.wipe();
    _extraImportRole = role;
    _extraTargetMasterFingerprint = targetMasterFingerprint;
    _extraMasterFingerprint = null;
    _extraImportedSeed = null;
    _isImportingExtra = true;
    _hasExtraImport = false;
    _isExtraImportMatched = false;
    _scannedExtraVaultItem = null;
    notifyListeners();
  }

  void resetExtraImport() {
    _extraImportedSeed?.wipe();
    _scannedExtraVaultItem = null;
    _extraImportRole = TaprootImportRole.none;
    _extraTargetMasterFingerprint = null;
    _extraMasterFingerprint = null;
    _extraImportedSeed = null;
    _isImportingExtra = false;
    _hasExtraImport = false;
    _isExtraImportMatched = false;
    notifyListeners();
  }

  void resetImportedWalletData() {
    _primaryImportedSeed?.wipe();
    _primaryImportedSeed = null;
    _selectedRole = TaprootImportRole.none;
    _masterFingerprint = null;
    _selectedExtendedPublicKey = null;
    _isSelectedRoleMatch = true;
    _scannedVaultItem = _buildScannedVaultItem();
    resetExtraImport();
  }

  Future<bool> setImportedSeed({required Uint8List secret, Uint8List? passphrase}) async {
    final walletSyncData = _walletSyncData;
    if (walletSyncData == null) {
      throw StateError('Taproot wallet sync data is missing');
    }

    final importRole = _isImportingExtra ? _extraImportRole : _selectedRole;
    if (importRole == TaprootImportRole.none) {
      return false;
    }

    final result = await _deriveImportedSeed(walletSyncData, importRole, secret, passphrase);

    if (_isImportingExtra) {
      return _applyExtraImportResult(result, secret, passphrase);
    }

    return _applyPrimaryImportResult(result, secret, passphrase);
  }

  Future<TaprootImportSaveResult> saveImportedWallet() async {
    final walletCreateDto = createWalletCreateDto();

    try {
      final vault = await _addTaprootVault(walletCreateDto);
      if (_walletSyncData?.wasMigratedFromOlderToAfter == true) {
        try {
          await _addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate(vault.id);
        } catch (error) {
          // Backup 안내 상태 저장 실패가 이미 완료된 지갑 추가를 실패로 만들지 않도록 무시한다.
          Logger.error('Failed to save Taproot backup update notice state: $error');
        }
      }
      return TaprootImportSaveResult(
        vaultId: vault.id,
        parentMasterFingerprint: _masterFingerprintForRole(TaprootImportRole.signer),
        childMasterFingerprint: _masterFingerprintForRole(TaprootImportRole.beneficiary),
      );
    } finally {
      walletCreateDto.wipe();
    }
  }

  TaprootWalletCreateDto createWalletCreateDto() {
    final walletSyncData = _walletSyncData;
    if (walletSyncData == null) {
      throw StateError('Taproot wallet sync data is missing');
    }

    final selectedExtendedPublicKey = _selectedExtendedPublicKey;
    if (selectedExtendedPublicKey == null) {
      throw StateError('Imported taproot seed is missing');
    }

    final vault = TaprootVault.fromDescriptor(walletSyncData.descriptor);
    final keyPathSeeds = <SeedSource>[];
    final keyPathSignerBsmses = <String>[];

    for (final keyStore in vault.keyStoreList) {
      final extendedPublicKey = keyStore.extendedPublicKey.serialize();
      final signerSeed = _matchedSeedFor(TaprootImportRole.signer, extendedPublicKey);
      if (signerSeed != null) {
        keyPathSeeds.add(signerSeed.toSeedSource());
        continue;
      }

      keyPathSignerBsmses.add(_buildSignerBsms(keyStore, vault.derivationPath));
    }

    final inheritanceLeaves = <InheritanceLeaf>[];
    for (final policy in vault.policyList) {
      if (policy is! InheritancePolicy) continue;

      final beneficiaryExtendedPublicKey = policy.beneficiaryKeyStore.extendedPublicKey.serialize();
      final beneficiarySeed = _matchedSeedFor(TaprootImportRole.beneficiary, beneficiaryExtendedPublicKey);
      if (beneficiarySeed != null) {
        inheritanceLeaves.add(InheritanceLeaf(secret: beneficiarySeed.toSeedSource(), lockTime: policy.locktime));
        continue;
      }

      inheritanceLeaves.add(
        InheritanceLeaf(
          descriptor: TaprootVault.fromKeyStoreList([policy.beneficiaryKeyStore], []).descriptor,
          lockTime: policy.locktime,
        ),
      );
    }

    return TaprootWalletCreateDto(
      null,
      walletSyncData.name,
      walletSyncData.iconIndex,
      walletSyncData.colorIndex,
      keyPathSeeds.isEmpty ? null : keyPathSeeds,
      keyPathSignerBsmses.isEmpty ? null : keyPathSignerBsmses,
      inheritanceLeaves.isEmpty ? null : inheritanceLeaves,
    );
  }

  List<TaprootImportParticipantCardState> buildParticipantCardStates({required bool showSelectedRoleState}) {
    final scannedVaultItem = _scannedVaultItem;
    if (scannedVaultItem == null) {
      return [];
    }

    final bool hasStoredOwnerSeed = _hasStoredOwnerSeed;

    return [
      ...scannedVaultItem.owners.asMap().entries.map((entry) {
        final index = entry.key;
        final owner = entry.value;
        final isMatchedSigner =
            showSelectedRoleState &&
            ((_selectedRole == TaprootImportRole.signer && owner.isSeedStored) ||
                (_hasExtraImport &&
                    _extraImportRole == TaprootImportRole.signer &&
                    _isExtraImportMatched &&
                    _scannedExtraVaultItem?.owners.any(
                          (extraOwner) =>
                              extraOwner.masterFingerprint == owner.masterFingerprint && extraOwner.isSeedStored,
                        ) ==
                        true));
        final isExtraSignerTarget =
            showSelectedRoleState &&
            _extraImportRole == TaprootImportRole.signer &&
            _extraTargetMasterFingerprint == owner.masterFingerprint;
        final isInvalidExtraSigner = _hasExtraImport && !_isExtraImportMatched && isExtraSignerTarget;
        final canAddExtraSigner =
            showSelectedRoleState &&
            !_hasExtraImport &&
            _isSelectedRoleMatch &&
            _selectedRole == TaprootImportRole.beneficiary;

        return TaprootImportParticipantCardState(
          role: TaprootImportRole.signer,
          masterFingerprint: owner.masterFingerprint,
          derivationPath: scannedVaultItem.derivationPath,
          signerIndex: index,
          hasSingleParent: scannedVaultItem.owners.length == 1,
          hasBackgroundColor: isMatchedSigner,
          isMine: isMatchedSigner,
          isValid: !isInvalidExtraSigner,
          canAddExtra: canAddExtraSigner,
        );
      }),
      ...scannedVaultItem.beneficiaries.map((beneficiary) {
        final isBeneficiaryRole = showSelectedRoleState && _selectedRole == TaprootImportRole.beneficiary;
        final isMatchedBeneficiary =
            isBeneficiaryRole && (beneficiary.isSeedStored || beneficiary.masterFingerprint == _masterFingerprint);
        final isExtraBeneficiaryTarget =
            showSelectedRoleState &&
            _extraImportRole == TaprootImportRole.beneficiary &&
            _extraTargetMasterFingerprint == beneficiary.masterFingerprint;
        final isMatchedExtraBeneficiary =
            _hasExtraImport &&
            _extraImportRole == TaprootImportRole.beneficiary &&
            _isExtraImportMatched &&
            (_scannedExtraVaultItem?.beneficiaries.any(
                  (extraBeneficiary) =>
                      extraBeneficiary.masterFingerprint == beneficiary.masterFingerprint &&
                      extraBeneficiary.isSeedStored,
                ) ==
                true);
        final isInvalidExtraBeneficiary = _hasExtraImport && !_isExtraImportMatched && isExtraBeneficiaryTarget;
        final canAddExtraBeneficiary =
            showSelectedRoleState &&
            !_hasExtraImport &&
            _isSelectedRoleMatch &&
            _selectedRole == TaprootImportRole.signer;

        return TaprootImportParticipantCardState(
          role: TaprootImportRole.beneficiary,
          masterFingerprint: beneficiary.masterFingerprint,
          derivationPath: scannedVaultItem.derivationPath,
          lockTime: beneficiary.lockTime,
          hasBackgroundColor: isMatchedBeneficiary || isMatchedExtraBeneficiary,
          isMine: !hasStoredOwnerSeed && (isMatchedBeneficiary || isMatchedExtraBeneficiary),
          isValid:
              isInvalidExtraBeneficiary
                  ? false
                  : !isBeneficiaryRole || beneficiary.masterFingerprint == _masterFingerprint,
          canAddExtra: canAddExtraBeneficiary,
        );
      }),
    ];
  }

  bool get _hasStoredOwnerSeed {
    return (_scannedVaultItem?.owners.any((owner) => owner.isSeedStored) ?? false) ||
        (_scannedExtraVaultItem?.owners.any((owner) => owner.isSeedStored) ?? false);
  }

  @override
  void dispose() {
    _wipeImportedSeeds();
    super.dispose();
  }

  Future<_DerivedTaprootImportSeed> _deriveImportedSeed(
    TaprootWalletSyncData walletSyncData,
    TaprootImportRole importRole,
    Uint8List secret,
    Uint8List? passphrase,
  ) async {
    final result = await compute(WalletIsolates.deriveTaprootImportSeed, {
      'mnemonic': Uint8List.fromList(secret),
      'passphrase': passphrase == null ? null : Uint8List.fromList(passphrase),
      'descriptor': walletSyncData.descriptor,
      'selectedRoleName': importRole.name,
    });

    return _DerivedTaprootImportSeed(
      extendedPublicKey: result['extendedPublicKey'] as String,
      masterFingerprint: result['masterFingerprint'] as String,
      isSelectedRoleMatch: result['isSelectedRoleMatch'] as bool,
      importedSingleKeyDescriptor: result['importedSingleKeyDescriptor'] as String,
      importedSignerBsms: result['importedSignerBsms'] as String,
    );
  }

  bool _applyPrimaryImportResult(_DerivedTaprootImportSeed result, Uint8List secret, Uint8List? passphrase) {
    final selectedRole = _selectedRole;
    if (selectedRole == TaprootImportRole.none) {
      return false;
    }

    _primaryImportedSeed?.wipe();
    _masterFingerprint = result.masterFingerprint;
    _selectedExtendedPublicKey = result.extendedPublicKey;
    _isSelectedRoleMatch = result.isSelectedRoleMatch;
    _primaryImportedSeed = _ImportedTaprootSeed(
      role: selectedRole,
      extendedPublicKey: result.extendedPublicKey,
      masterFingerprint: result.masterFingerprint,
      secret: secret,
      passphrase: passphrase,
      isMatched: result.isSelectedRoleMatch,
    );

    _scannedVaultItem = switch (selectedRole) {
      TaprootImportRole.signer => _buildScannedVaultItem(matchedParentExtendedPublicKey: result.extendedPublicKey),
      TaprootImportRole.beneficiary => _buildScannedVaultItem(
        matchedBeneficiaryExtendedPublicKey: result.extendedPublicKey,
      ),
      TaprootImportRole.none => _scannedVaultItem,
    };

    return true;
  }

  bool _applyExtraImportResult(_DerivedTaprootImportSeed result, Uint8List secret, Uint8List? passphrase) {
    final importRole = _extraImportRole;
    if (importRole == TaprootImportRole.none) {
      _isImportingExtra = false;
      return false;
    }

    final isTargetMatched = result.masterFingerprint == _extraTargetMasterFingerprint;
    _extraImportedSeed?.wipe();
    _extraMasterFingerprint = result.masterFingerprint;
    _hasExtraImport = true;
    _isExtraImportMatched = result.isSelectedRoleMatch && isTargetMatched;
    _isImportingExtra = false;
    _extraImportedSeed = _ImportedTaprootSeed(
      role: importRole,
      extendedPublicKey: result.extendedPublicKey,
      masterFingerprint: result.masterFingerprint,
      secret: secret,
      passphrase: passphrase,
      isMatched: _isExtraImportMatched,
    );

    if (!_isExtraImportMatched) {
      _scannedExtraVaultItem = _buildScannedVaultItem();
      return true;
    }

    _scannedExtraVaultItem = switch (importRole) {
      TaprootImportRole.signer => _buildScannedVaultItem(matchedParentExtendedPublicKey: result.extendedPublicKey),
      TaprootImportRole.beneficiary => _buildScannedVaultItem(
        matchedBeneficiaryExtendedPublicKey: result.extendedPublicKey,
      ),
      TaprootImportRole.none => _buildScannedVaultItem(),
    };

    return true;
  }

  _ImportedTaprootSeed? _matchedSeedFor(TaprootImportRole role, String extendedPublicKey) {
    for (final importedSeed in [_primaryImportedSeed, _extraImportedSeed]) {
      if (importedSeed == null) continue;
      if (!importedSeed.isMatched) continue;
      if (importedSeed.role != role) continue;
      if (importedSeed.extendedPublicKey != extendedPublicKey) continue;
      return importedSeed;
    }

    return null;
  }

  String? _masterFingerprintForRole(TaprootImportRole role) {
    for (final importedSeed in [_primaryImportedSeed, _extraImportedSeed]) {
      if (importedSeed == null) continue;
      if (!importedSeed.isMatched) continue;
      if (importedSeed.role == role) {
        return importedSeed.masterFingerprint;
      }
    }

    return null;
  }

  void _wipeImportedSeeds() {
    _primaryImportedSeed?.wipe();
    _extraImportedSeed?.wipe();
  }

  String _buildSignerBsms(KeyStore keyStore, String derivationPath) {
    return Bsms.fromSigner(
      keyStore.masterFingerprint,
      derivationPath.replaceAll('m/', ''),
      keyStore.extendedPublicKey.serialize(),
      '',
    ).serializeSigner();
  }

  TaprootVaultListItem? _buildScannedVaultItem({
    String? matchedParentExtendedPublicKey,
    String? matchedBeneficiaryExtendedPublicKey,
  }) {
    final walletSyncData = _walletSyncData;
    if (walletSyncData == null) {
      return null;
    }

    final vault = TaprootVault.fromDescriptor(walletSyncData.descriptor);
    final keyPathSeedInfos = [
      if (matchedParentExtendedPublicKey != null)
        StoredTaprootSeedInfo(extendedPublicKey: matchedParentExtendedPublicKey, isPassphraseSet: false),
    ];

    final scriptPathSeedInfos = <ScriptPathSeedInfo>[];
    for (final policy in vault.policyList) {
      if (policy is! InheritancePolicy) continue;

      if (matchedBeneficiaryExtendedPublicKey == null ||
          policy.beneficiaryKeyStore.extendedPublicKey.serialize() != matchedBeneficiaryExtendedPublicKey) {
        continue;
      }

      scriptPathSeedInfos.add(
        ScriptPathSeedInfo(
          key: ScriptPathSeedInfo.generateKey(policy),
          role: ScriptPathRole.beneficiary,
          seedInfos: [
            StoredTaprootSeedInfo(extendedPublicKey: matchedBeneficiaryExtendedPublicKey, isPassphraseSet: false),
          ],
        ),
      );
    }

    return TaprootVaultListItem(
      id: 0,
      name: walletSyncData.name,
      colorIndex: walletSyncData.colorIndex,
      iconIndex: walletSyncData.iconIndex,
      createdAt: DateTime.now(),
      descriptor: walletSyncData.descriptor,
      keyPathSeedInfos: keyPathSeedInfos,
      scriptPathSeedInfos: scriptPathSeedInfos,
    );
  }
}
