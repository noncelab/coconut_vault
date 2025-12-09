import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/extended_public_key_not_found_exception.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';

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

  Future<Psbt> parseBase64EncodedToPsbt(int vaultId, String signedPsbtBase64Encoded) async {
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      await _walletProvider.loadVaultList();
    }
    _signProvider.setVaultListItem(_walletProvider.getVaultById(vaultId));
    final canSign = await _walletProvider.getVaultById(vaultId).canSign(signedPsbtBase64Encoded);
    if (!canSign) {
      throw VaultSigningNotAllowedException();
    }
    return Psbt.parse(signedPsbtBase64Encoded);
  }

  Future<void> setMatchingVault(String psbtBase64) async {
    if (!_walletProvider.isVaultsLoaded || _walletProvider.vaultList.isEmpty) {
      await _walletProvider.loadVaultList();
    }
    final parsedPsbt = _parseBase64EncodedToPsbt(psbtBase64);
    // parsedPsbt.extendedPublicKeyList가
    // 한 개만 있는 경우 - 싱글 시그 지갑이므로 vaultList에서 바로 찾기
    // 두 개 이상 있는 경우 - 멀티 시그 지갑이므로 스캔된 정보의 MFP set과 vaultList의 MFP set 비교, 일치 시 해당 멀티시그 지갑 선택

    int? matchingVaultId;
    bool isVaultSigningAllowed = false;

    if (parsedPsbt.addressType?.isSingleSignature ?? true) {
      // 싱글시그지갑
      // 싱글시그는 MFP 일치 여부로 판단
      final psbtMfp = parsedPsbt.extendedPublicKeyList.first.masterFingerprint;
      final vaultList = List<VaultListItemBase>.from(_walletProvider.vaultList);

      for (final vault in vaultList) {
        if (vault.vaultType == WalletType.singleSignature) {
          final singleSigVault = vault.coconutVault as SingleSignatureVault;
          if (singleSigVault.keyStore.masterFingerprint == psbtMfp) {
            matchingVaultId = vault.id;
            final canSign = await _walletProvider.getVaultById(matchingVaultId).canSign(psbtBase64);
            if (!canSign) {
              Logger.log('❌ 서명 불가능한 지갑 찾음 ${vault.name}');
              continue;
            }
            _signProvider.setVaultListItem(_walletProvider.getVaultById(matchingVaultId));
            isVaultSigningAllowed = true;
            Logger.log('✅ 서명 가능한 지갑 찾음 ${vault.name}');
            break;
          }
        }
      }
    } else {
      // 멀티시그지갑
      if (parsedPsbt.extendedPublicKeyList.isEmpty) {
        throw ExtendedPublicKeyNotFoundException();
      }
      final psbtMfpSet = parsedPsbt.extendedPublicKeyList.map((e) => e.masterFingerprint).toSet();
      for (final vault in _walletProvider.vaultList) {
        if (vault.vaultType == WalletType.multiSignature) {
          final multisigVault = vault.coconutVault as MultisignatureVault;
          final vaultMfpSet = multisigVault.keyStoreList.map((keyStore) => keyStore.masterFingerprint).toSet();

          // PSBT의 모든 MFP가 vault의 MFP set에 포함되어 있는지 확인
          if (psbtMfpSet.length == vaultMfpSet.length && psbtMfpSet.every((psbtMfp) => vaultMfpSet.contains(psbtMfp))) {
            matchingVaultId = vault.id;
            final canSign = await _walletProvider.getVaultById(matchingVaultId).canSign(psbtBase64);
            if (!canSign) {
              Logger.log('❌ 서명 불가능한 지갑 찾음 ${vault.name}');
              continue;
            }
            _signProvider.setVaultListItem(_walletProvider.getVaultById(matchingVaultId));
            isVaultSigningAllowed = true;
            Logger.log('✅ 서명 가능한 지갑 찾음 ${vault.name}');
            break;
          }
        }
      }
    }

    if (matchingVaultId == null) {
      throw VaultNotFoundException();
    } else if (!isVaultSigningAllowed) {
      throw VaultSigningNotAllowedException();
    }
  }

  Psbt _parseBase64EncodedToPsbt(String signedPsbtBase64Encoded) {
    return Psbt.parse(signedPsbtBase64Encoded);
  }
}
