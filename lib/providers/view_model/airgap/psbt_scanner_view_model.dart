import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/wallet_not_identifiable_from_psbt_exception.dart';
import 'package:coconut_vault/model/exception/needs_multisig_setup_exception.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:ur/ur.dart';
import 'package:cbor/cbor.dart';

class PsbtScannerViewModel {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;

  PsbtScannerViewModel(this._walletProvider, this._signProvider, {bool shouldResetAll = true}) {
    if (shouldResetAll) {
      _signProvider.resetAll();
    }
  }

  void saveUnsignedPsbt(String psbtBase64) {
    _signProvider.saveUnsignedPsbt(psbtBase64);
  }

  String getScanErrorMessage(Object error) {
    return switch (error) {
      VaultNotFoundException(:final message) => message,
      VaultSigningNotAllowedException(:final message) => message,
      WalletNotIdentifiableFromPsbtException(:final message) => message,
      NeedsMultisigSetupException(:final message) => message,
      _ => t.errors.invalid_qr,
    };
  }

  String normalizePsbtToBase64(dynamic psbt) {
    if (psbt is UR) {
      final ur = psbt;
      final cborBytes = ur.cbor;
      final decodedCbor = cbor.decode(cborBytes) as CborBytes;
      return base64Encode(decodedCbor.bytes);
    } else if (psbt is String) {
      // BBQR (base64 문자열) or RawSignedTransaction
      return psbt;
    } else {
      throw FormatException('Unsupported PSBT format: ${psbt.runtimeType}');
    }
  }

  /// wallet_info_screen > sign
  Future<Psbt> preparePsbtForVault(int vaultId, String psbtBase64Encoded, {bool hasDerivationPath = false}) async {
    final Psbt parsedPsbt = Psbt.parse(psbtBase64Encoded);

    // Krux, SeedSigner는 derivation path를 넘기지 않기 때문에, canSign 검사 불가
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      await _walletProvider.loadVaultList();
    }

    final vault = _walletProvider.getVaultById(vaultId);
    final canSign = hasDerivationPath ? await vault.canSign(psbtBase64Encoded) : true;
    if (!canSign) {
      if (parsedPsbt.addressType!.isMultisignature && vault.vaultType == WalletType.singleSignature) {
        final mfp = (vault.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
        if (parsedPsbt.extendedPublicKeyList.map((e) => e.masterFingerprint).contains(mfp)) {
          throw NeedsMultisigSetupException(singleSigWalletName: vault.name);
        }
      }

      throw VaultSigningNotAllowedException();
    }

    _signProvider.setVaultListItem(vault);

    return parsedPsbt;
  }

  Future<void> _ensureVaultsLoaded() async {
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      await _walletProvider.loadVaultList();
    }
  }

  Future<VaultListItemBase?> _findMatchingVault(Psbt parsedPsbt, String psbtBase64) async {
    if (parsedPsbt.addressType?.isSingleSignature ?? true) {
      return _findSingleSignatureVault(parsedPsbt, psbtBase64);
    }

    if (parsedPsbt.addressType!.isTaproot) {
      return _findTaprootVault(parsedPsbt);
    }

    return _findMultisigVault(parsedPsbt, psbtBase64);
  }

  Future<VaultListItemBase?> _findSingleSignatureVault(Psbt parsedPsbt, String psbtBase64) async {
    final psbtMfp = parsedPsbt.extendedPublicKeyList.first.masterFingerprint;
    var foundMatchingMfp = false;

    for (final vault in _walletProvider.vaultList) {
      if (vault.vaultType != WalletType.singleSignature) {
        continue;
      }

      final singleSigVault = vault.coconutVault as SingleSignatureVault;
      if (singleSigVault.keyStore.masterFingerprint != psbtMfp) {
        continue;
      }

      foundMatchingMfp = true;

      final canSign = await vault.canSign(psbtBase64);
      if (canSign) {
        return vault;
      }
    }

    if (foundMatchingMfp) {
      throw VaultSigningNotAllowedException();
    }

    return null;
  }

  VaultListItemBase? _findTaprootVault(Psbt parsedPsbt) {
    for (final vault in _walletProvider.vaultList) {
      if (vault.vaultType != WalletType.taproot) {
        continue;
      }

      if (parsedPsbt.isForVault(vault.coconutVault)) {
        return vault;
      }
    }

    return null;
  }

  Future<VaultListItemBase?> _findMultisigVault(Psbt parsedPsbt, String psbtBase64) async {
    if (parsedPsbt.extendedPublicKeyList.isEmpty) {
      throw WalletNotIdentifiableFromPsbtException();
    }

    String? sameMfpSingleSigWalletName;
    final psbtMfpSet = parsedPsbt.extendedPublicKeyList.map((e) => e.masterFingerprint).toSet();

    for (final vault in _walletProvider.vaultList) {
      if (vault.vaultType == WalletType.singleSignature) {
        sameMfpSingleSigWalletName ??= _getSameMfpSingleSigWalletName(vault, psbtMfpSet);
        continue;
      }

      if (vault.vaultType != WalletType.multiSignature) {
        continue;
      }

      if (!_hasSameMfpSet(vault, psbtMfpSet)) {
        continue;
      }

      final canSign = await vault.canSign(psbtBase64);
      if (canSign) {
        return vault;
      }
    }

    if (sameMfpSingleSigWalletName != null) {
      throw NeedsMultisigSetupException(singleSigWalletName: sameMfpSingleSigWalletName);
    }

    return null;
  }

  String? _getSameMfpSingleSigWalletName(VaultListItemBase vault, Set<String> psbtMfpSet) {
    final singleSigVault = vault.coconutVault as SingleSignatureVault;
    final walletMfp = singleSigVault.keyStore.masterFingerprint;

    return psbtMfpSet.contains(walletMfp) ? vault.name : null;
  }

  bool _hasSameMfpSet(VaultListItemBase vault, Set<String> psbtMfpSet) {
    final multisigVault = vault.coconutVault as MultisignatureVault;
    final walletMfpSet = multisigVault.keyStoreList.map((keyStore) => keyStore.masterFingerprint).toSet();

    return psbtMfpSet.length == walletMfpSet.length && psbtMfpSet.every(walletMfpSet.contains);
  }

  Future<void> setMatchingVault(String psbtBase64) async {
    await _ensureVaultsLoaded();

    final parsedPsbt = Psbt.parse(psbtBase64);
    final matchingVault = await _findMatchingVault(parsedPsbt, psbtBase64);

    if (matchingVault == null) {
      throw VaultNotFoundException();
    }

    _signProvider.setVaultListItem(matchingVault);
  }
}
