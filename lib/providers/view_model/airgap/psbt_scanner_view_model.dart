import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/extended_public_key_not_found_exception.dart';
import 'package:coconut_vault/model/exception/needs_multisig_setup_exception.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
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

  String normalizePsbtToBase64(dynamic psbt) {
    if (psbt is UR) {
      final ur = psbt;
      final cborBytes = ur.cbor;
      final decodedCbor = cbor.decode(cborBytes) as CborBytes;
      return base64Encode(decodedCbor.bytes);
    } else if (psbt is String) {
      // BBQR (base64 문자열)
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

  /// vault_home > sign
  Future<void> setMatchingVault(String psbtBase64) async {
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      await _walletProvider.loadVaultList();
    }
    final Psbt parsedPsbt = Psbt.parse(psbtBase64);
    // parsedPsbt.extendedPublicKeyList가
    // 한 개만 있는 경우 - 싱글 시그 지갑이므로 vaultList에서 바로 찾기
    // 두 개 이상 있는 경우 - 멀티 시그 지갑이므로 스캔된 정보의 MFP set과 vaultList의 MFP set 비교, 일치 시 해당 멀티시그 지갑 선택

    int? matchingVaultId;
    bool isVaultSigningAllowed = false;

    final vaultList = _walletProvider.vaultList;

    if (parsedPsbt.addressType?.isSingleSignature ?? true) {
      // 싱글시그지갑
      // 싱글시그는 MFP 일치 여부로 판단
      final psbtMfp = parsedPsbt.extendedPublicKeyList.first.masterFingerprint;
      for (final vault in vaultList) {
        if (vault.vaultType == WalletType.singleSignature) {
          final singleSigVault = vault.coconutVault as SingleSignatureVault;
          if (singleSigVault.keyStore.masterFingerprint == psbtMfp) {
            matchingVaultId = vault.id;
            final canSign = await _walletProvider.getVaultById(matchingVaultId).canSign(psbtBase64);
            if (!canSign) {
              continue;
            }
            _signProvider.setVaultListItem(_walletProvider.getVaultById(matchingVaultId));
            isVaultSigningAllowed = true;
            break;
          }
        }
      }
    } else {
      String? sameMfpSingleSigWalletName;
      // 멀티시그지갑
      if (parsedPsbt.extendedPublicKeyList.isEmpty) {
        throw ExtendedPublicKeyNotFoundException();
      }
      final psbtMfpSet = parsedPsbt.extendedPublicKeyList.map((e) => e.masterFingerprint).toSet();
      for (final vault in vaultList) {
        if (vault.vaultType == WalletType.singleSignature && sameMfpSingleSigWalletName == null) {
          final singleSigVault = vault.coconutVault as SingleSignatureVault;
          if (psbtMfpSet.contains(singleSigVault.keyStore.masterFingerprint)) {
            sameMfpSingleSigWalletName = vault.name;
          }
          continue;
        }

        if (vault.vaultType == WalletType.multiSignature) {
          final multisigVault = vault.coconutVault as MultisignatureVault;
          final walletMfpSet = multisigVault.keyStoreList.map((keyStore) => keyStore.masterFingerprint).toSet();

          // PSBT의 모든 MFP가 vault의 MFP set에 포함되어 있는지 확인
          if (psbtMfpSet.length == walletMfpSet.length &&
              psbtMfpSet.every((psbtMfp) => walletMfpSet.contains(psbtMfp))) {
            final canSign = await vault.canSign(psbtBase64);
            if (!canSign) {
              continue;
            }
            matchingVaultId = vault.id;
            _signProvider.setVaultListItem(vault);
            isVaultSigningAllowed = true;
            break;
          }
        }
      }

      if (matchingVaultId == null && sameMfpSingleSigWalletName != null) {
        throw NeedsMultisigSetupException(singleSigWalletName: sameMfpSingleSigWalletName);
      }
    }

    if (matchingVaultId == null) {
      throw VaultNotFoundException();
    } else if (!isVaultSigningAllowed) {
      throw VaultSigningNotAllowedException();
    }
  }
}
