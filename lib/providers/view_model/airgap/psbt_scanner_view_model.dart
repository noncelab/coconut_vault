import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';

class PsbtScannerViewModel {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;

  PsbtScannerViewModel(this._walletProvider, this._signProvider) {
    _signProvider.resetAll();
  }

  Future<bool> canSign(String psbtBase64) async {
    if (_signProvider.vaultListItem == null) {
      return false;
    }
    return await _signProvider.vaultListItem!.canSign(psbtBase64);
  }

  void saveUnsignedPsbt(String psbtBase64) {
    _signProvider.saveUnsignedPsbt(psbtBase64);
  }

  Future<void> setVaultByPsbtBase64(String psbtBase64) async {
    final parsedPsbt = _parseBase64EncodedToPsbt(psbtBase64);
    // parsedPsbt.extendedPublicKeyList가
    // 한 개만 있는 경우 - 싱글 시그 지갑이므로 vaultList에서 바로 찾기
    // 두 개 이상 있는 경우 - 멀티 시그 지갑이므로 스캔된 정보의 MFP set과 vaultList의 MFP set 비교, 일치 시 해당 멀티시그 지갑 선택

    bool? hasMatchingMfp;
    int? matchingVaultId;
    bool isVaultSigningAllowed = false;

    if (parsedPsbt.addressType?.isSingleSignature ?? true) {
      // 싱글시그지갑
      for (final extendedKey in parsedPsbt.extendedPublicKeyList) {
        final psbtMfp = extendedKey.masterFingerprint;
        for (final vault in _walletProvider.vaultList) {
          if (vault.vaultType == WalletType.singleSignature) {
            final singleSigVault = vault.coconutVault as SingleSignatureVault;
            if (singleSigVault.keyStore.masterFingerprint == psbtMfp) {
              hasMatchingMfp = true;
              matchingVaultId = vault.id;
              _signProvider.setVaultListItem(_walletProvider.getVaultById(matchingVaultId));
              isVaultSigningAllowed = await canSign(psbtBase64);
              Logger.log('✅ 서명 가능한 지갑 찾음 ${vault.name}');
              break;
            }
          }
        }
        if (hasMatchingMfp == true) break;
      }
      hasMatchingMfp ??= false;
    } else {
      // 멀티시그지갑
      final psbtMfps = parsedPsbt.extendedPublicKeyList
          .map((extendedKey) => extendedKey.masterFingerprint)
          .toSet();

      for (final vault in _walletProvider.vaultList) {
        if (vault.vaultType == WalletType.multiSignature) {
          final multisigVault = vault.coconutVault as MultisignatureVault;
          final vaultMfps =
              multisigVault.keyStoreList.map((keyStore) => keyStore.masterFingerprint).toSet();

          // PSBT의 모든 MFP가 vault의 MFP set에 포함되어 있는지 확인
          if (psbtMfps.every((psbtMfp) => vaultMfps.contains(psbtMfp))) {
            hasMatchingMfp = true;
            matchingVaultId = vault.id;
            _signProvider.setVaultListItem(_walletProvider.getVaultById(matchingVaultId));
            isVaultSigningAllowed = await canSign(psbtBase64);
            if (isVaultSigningAllowed) {
              Logger.log('✅ 서명 가능한 지갑 찾음 ${vault.name}');
              break;
            } else {
              Logger.log('❌ 서명 불가능한 지갑 찾음 ${vault.name}');
            }
          }
        }
      }
      hasMatchingMfp ??= false;
    }

    if (!hasMatchingMfp) {
      throw VaultNotFoundException();
    } else if (!isVaultSigningAllowed) {
      throw VaultSigningNotAllowedException();
    }
  }

  Psbt _parseBase64EncodedToPsbt(String signedPsbtBase64Encoded) {
    return Psbt.parse(signedPsbtBase64Encoded);
  }
}
