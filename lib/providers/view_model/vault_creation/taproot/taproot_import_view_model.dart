import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/model/taproot/stored_taproot_seed_info.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:flutter/foundation.dart';

enum TaprootImportRole { none, signer, beneficiary }

enum ImportMode { enter, scan }

class TaprootImportViewModel extends ChangeNotifier {
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
  String? _selectedExtraExtendedPublicKey;
  bool _isImportingExtra = false;
  bool _isSelectedRoleMatch = true;
  bool _hasExtraImport = false;
  bool _isExtraImportMatched = false;

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
    _walletSyncData = null;
    _scannedVaultItem = null;
    _scannedExtraVaultItem = null;
    _selectedRole = TaprootImportRole.none;
    _masterFingerprint = null;
    _selectedExtendedPublicKey = null;
    _extraImportRole = TaprootImportRole.none;
    _extraTargetMasterFingerprint = null;
    _extraMasterFingerprint = null;
    _selectedExtraExtendedPublicKey = null;
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
    _extraImportRole = role;
    _extraTargetMasterFingerprint = targetMasterFingerprint;
    _extraMasterFingerprint = null;
    _selectedExtraExtendedPublicKey = null;
    _isImportingExtra = true;
    _hasExtraImport = false;
    _isExtraImportMatched = false;
    _scannedExtraVaultItem = null;
    notifyListeners();
  }

  void resetExtraImport() {
    _scannedExtraVaultItem = null;
    _extraImportRole = TaprootImportRole.none;
    _extraTargetMasterFingerprint = null;
    _extraMasterFingerprint = null;
    _selectedExtraExtendedPublicKey = null;
    _isImportingExtra = false;
    _hasExtraImport = false;
    _isExtraImportMatched = false;
    notifyListeners();
  }

  void resetImportedWalletData() {
    _selectedRole = TaprootImportRole.none;
    _masterFingerprint = null;
    _selectedExtendedPublicKey = null;
    _isSelectedRoleMatch = true;
    _scannedVaultItem = _buildScannedVaultItem();
    resetExtraImport();
  }

  Future<bool> setImportedSeed(
    TaprootWalletCreationProvider creationProvider, {
    required Uint8List secret,
    Uint8List? passphrase,
  }) async {
    final walletSyncData = _walletSyncData;
    if (walletSyncData == null) {
      throw StateError('Taproot wallet sync data is missing');
    }

    final importRole = _isImportingExtra ? _extraImportRole : _selectedRole;
    final result = await compute(WalletIsolates.deriveTaprootImportSeed, {
      'mnemonic': Uint8List.fromList(secret),
      'passphrase': passphrase == null ? null : Uint8List.fromList(passphrase),
      'descriptor': walletSyncData.descriptor,
      'selectedRoleName': importRole.name,
    });

    final extendedPublicKey = result['extendedPublicKey'] as String;
    final masterFingerprint = result['masterFingerprint'] as String;
    final isMatch = result['isSelectedRoleMatch'] as bool;

    if (_isImportingExtra) {
      final isTargetMatched = masterFingerprint == _extraTargetMasterFingerprint;
      _extraMasterFingerprint = masterFingerprint;
      _selectedExtraExtendedPublicKey = extendedPublicKey;
      _hasExtraImport = true;
      _isExtraImportMatched = isMatch && isTargetMatched;
      _isImportingExtra = false;

      if (_isExtraImportMatched) {
        switch (importRole) {
          case TaprootImportRole.signer:
            creationProvider.setParentWalletDerivedSeed(
              secret: secret,
              passphrase: passphrase,
              masterFingerprint: masterFingerprint,
              qrData: result['importedSignerBsms'] as String,
            );
            _scannedExtraVaultItem = _buildScannedVaultItem(matchedParentExtendedPublicKey: extendedPublicKey);
            break;
          case TaprootImportRole.beneficiary:
            creationProvider.setChildWallet(
              descriptor: result['importedSingleKeyDescriptor'] as String,
              masterFingerprint: masterFingerprint,
              source: TaprootChildWalletSource.scanned,
              secret: secret,
              passphrase: passphrase,
            );
            _scannedExtraVaultItem = _buildScannedVaultItem(matchedBeneficiaryExtendedPublicKey: extendedPublicKey);
            break;
          case TaprootImportRole.none:
            return false;
        }
      } else {
        _scannedExtraVaultItem = _buildScannedVaultItem();
      }

      return true;
    }

    _masterFingerprint = masterFingerprint;
    _selectedExtendedPublicKey = extendedPublicKey;
    _isSelectedRoleMatch = isMatch;

    switch (_selectedRole) {
      case TaprootImportRole.signer:
        creationProvider.setParentWalletDerivedSeed(
          secret: secret,
          passphrase: passphrase,
          masterFingerprint: masterFingerprint,
          qrData: result['importedSignerBsms'] as String,
        );
        _scannedVaultItem = _buildScannedVaultItem(matchedParentExtendedPublicKey: extendedPublicKey);
        return true;
      case TaprootImportRole.beneficiary:
        creationProvider.setChildWallet(
          descriptor: result['importedSingleKeyDescriptor'] as String,
          masterFingerprint: masterFingerprint,
          source: TaprootChildWalletSource.scanned,
          secret: secret,
          passphrase: passphrase,
        );
        _scannedVaultItem = _buildScannedVaultItem(matchedBeneficiaryExtendedPublicKey: extendedPublicKey);
        return true;
      case TaprootImportRole.none:
        return false;
    }
  }

  TaprootWalletCreateDto createWalletCreateDto(TaprootWalletCreationProvider creationProvider) {
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
      final isPrimarySignerSeed =
          _selectedRole == TaprootImportRole.signer && extendedPublicKey == selectedExtendedPublicKey;
      final isExtraSignerSeed =
          _isExtraImportMatched &&
          _extraImportRole == TaprootImportRole.signer &&
          extendedPublicKey == _selectedExtraExtendedPublicKey;
      if (isPrimarySignerSeed || isExtraSignerSeed) {
        keyPathSeeds.add(
          SeedSource(
            mnemonic: Uint8List.fromList(creationProvider.secret),
            passphrase: Uint8List.fromList(creationProvider.passphrase ?? Uint8List(0)),
          ),
        );
        continue;
      }

      keyPathSignerBsmses.add(_buildSignerBsms(keyStore, vault.derivationPath));
    }

    final inheritanceLeaves = <InheritanceLeaf>[];
    for (final policy in vault.policyList) {
      if (policy is! InheritancePolicy) continue;

      final beneficiaryExtendedPublicKey = policy.beneficiaryKeyStore.extendedPublicKey.serialize();
      final isPrimaryBeneficiarySeed =
          _selectedRole == TaprootImportRole.beneficiary && beneficiaryExtendedPublicKey == selectedExtendedPublicKey;
      final isExtraBeneficiarySeed =
          _isExtraImportMatched &&
          _extraImportRole == TaprootImportRole.beneficiary &&
          beneficiaryExtendedPublicKey == _selectedExtraExtendedPublicKey;
      if ((isPrimaryBeneficiarySeed || isExtraBeneficiarySeed) && creationProvider.childSecret.isNotEmpty) {
        inheritanceLeaves.add(
          InheritanceLeaf(
            secret: SeedSource(
              mnemonic: Uint8List.fromList(creationProvider.childSecret),
              passphrase: Uint8List.fromList(creationProvider.childPassphrase ?? Uint8List(0)),
            ),
            lockTime: policy.locktime,
          ),
        );
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
