import 'dart:io';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class VaultNameAndIconSetupViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  final WalletCreationProvider _walletCreationProvider;
  final AuthProvider _authProvider;
  final bool _isImported;

  String _inputText;
  int _selectedIconIndex;
  int _selectedColorIndex;
  bool _showLoading = false;
  bool _poppedByBack = false;

  VaultNameAndIconSetupViewModel(
    this._walletProvider,
    this._walletCreationProvider,
    this._authProvider, {
    required String initialName,
    required int initialIconIndex,
    required int initialColorIndex,
    required bool isImported,
  }) : _inputText = initialName,
       _selectedIconIndex = initialIconIndex,
       _selectedColorIndex = initialColorIndex,
       _isImported = isImported {
    _walletProvider.isVaultListLoadingNotifier.addListener(_onVaultListLoading);
  }

  String get inputText => _inputText;
  int get selectedIconIndex => _selectedIconIndex;
  int get selectedColorIndex => _selectedColorIndex;
  bool get showLoading => _showLoading;
  bool get isVaultListLoading => _walletProvider.isVaultListLoading;
  bool get isSaveEnabled => _inputText.trim().isNotEmpty && !_showLoading;

  void updateName(String name) {
    _inputText = name;
    notifyListeners();
  }

  void updateIcon(int index) {
    _selectedIconIndex = index;
    notifyListeners();
  }

  void updateColor(int index) {
    _selectedColorIndex = index;
    notifyListeners();
  }

  void setPoppedByBack(bool value) {
    _poppedByBack = value;
  }

  void setShowLoading(bool value) {
    _showLoading = value;
    notifyListeners();
  }

  void _trimInput() {
    _inputText = _inputText.trim();
  }

  void _onVaultListLoading() {
    if (!_walletProvider.isVaultListLoadingNotifier.value && _showLoading) {
      notifyListeners();
    }
  }

  Future<void> _authenticateForSingleSigIfNeeded() async {
    if (Platform.isIOS && _walletProvider.isSigningOnlyMode) {
      if (!_authProvider.hasAlreadyRequestedBioPermission && _authProvider.availableBiometrics.isNotEmpty) {
        await _authProvider.authenticateWithBiometrics(isSaved: true);
      }
    }
  }

  Future<VaultNameAndIconSetupSaveResult> _saveSingleSigVault() async {
    await _authenticateForSingleSigIfNeeded();

    final vault = await _walletProvider.addSingleSigVault(
      SingleSigWalletCreateDto(
        null,
        _inputText,
        _selectedIconIndex,
        _selectedColorIndex,
        _walletCreationProvider.secret,
        _walletCreationProvider.passphrase,
      ),
    );

    final MultisigSigner? externalSigner = _walletCreationProvider.externalSigner;
    if (externalSigner != null) {
      final multisigVaultId = _walletCreationProvider.multisigVaultIdOfExternalSigner;
      _walletCreationProvider.resetAll();
      return VaultNameAndIconSetupSaveResult.navigateToMultisigSetupInfo(multisigVaultId: multisigVaultId);
    }

    _walletCreationProvider.resetAll();
    return VaultNameAndIconSetupSaveResult.navigateToHome(addedWalletId: vault.id);
  }

  Future<VaultNameAndIconSetupSaveResult> _saveMultisigVault() async {
    final vault = await _walletProvider.addMultisigVault(
      _inputText,
      _selectedColorIndex,
      _selectedIconIndex,
      _walletCreationProvider.signers!,
      _walletCreationProvider.requiredSignatureCount!,
      isImported: _isImported,
    );

    _walletCreationProvider.resetAll();
    return VaultNameAndIconSetupSaveResult.navigateToHome(addedWalletId: vault.id);
  }

  Future<VaultNameAndIconSetupSaveResult> saveNewVault() async {
    try {
      setShowLoading(true);
      _trimInput();

      if (_walletProvider.isNameDuplicated(_inputText)) {
        setShowLoading(false);
        return const VaultNameAndIconSetupSaveResult.duplicateName();
      }

      switch (_walletCreationProvider.walletType) {
        case WalletType.singleSignature:
          return await _saveSingleSigVault();
        case WalletType.multiSignature:
          return await _saveMultisigVault();
        case WalletType.taproot:
          throw UnimplementedError(
            'Taproot vault creation is not supported in VaultNameAndIconSetupViewModel.saveNewVault',
          );
      }
    } finally {
      setShowLoading(false);
    }
  }

  void handleDisposeReset() {
    if (!_poppedByBack) {
      _walletCreationProvider.resetAll();
    } else if (_walletCreationProvider.walletType == WalletType.singleSignature &&
        _walletCreationProvider.singleSigCreationOption != AppRoutes.mnemonicAutoGen) {
      _walletCreationProvider.resetAll();
    } else if (_walletCreationProvider.walletType == WalletType.multiSignature) {
      _walletCreationProvider.resetSigner();
    }
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_onVaultListLoading);
    super.dispose();
  }
}

enum VaultNameAndIconSetupSaveStatus { duplicateName, navigateHome, navigateMultisigSetupInfo }

class VaultNameAndIconSetupSaveResult {
  final VaultNameAndIconSetupSaveStatus status;
  final int? addedWalletId;
  final int? multisigVaultId;

  const VaultNameAndIconSetupSaveResult._({required this.status, this.addedWalletId, this.multisigVaultId});

  const VaultNameAndIconSetupSaveResult.duplicateName() : this._(status: VaultNameAndIconSetupSaveStatus.duplicateName);

  const VaultNameAndIconSetupSaveResult.navigateToHome({required int addedWalletId})
    : this._(status: VaultNameAndIconSetupSaveStatus.navigateHome, addedWalletId: addedWalletId);

  const VaultNameAndIconSetupSaveResult.navigateToMultisigSetupInfo({required int? multisigVaultId})
    : this._(status: VaultNameAndIconSetupSaveStatus.navigateMultisigSetupInfo, multisigVaultId: multisigVaultId);
}
