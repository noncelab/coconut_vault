import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/coconut/extended_pubkey_utils.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

/// Read-only domain queries over the in-memory vault list.
///
/// Pure (no Flutter / IO / repository dependency). Reads the current snapshot
/// via the injected [snapshot] callback so callers can keep ownership of the
/// list and mutations remain elsewhere.
class WalletQueryService {
  final List<VaultListItemBase> Function() _snapshot;

  WalletQueryService(this._snapshot);

  List<VaultListItemBase> get _vaults => _snapshot();

  /// 이름 중복이면 겹치지 않게 숫자 접미사를 붙여서 반환
  String getUnduplicatedName(String name) {
    String target = name.trim();
    int count = 2;
    while (isNameDuplicated(target)) {
      target = '$name $count';
      count++;
    }
    return target;
  }

  bool isNameDuplicated(String name) {
    return _vaults.indexWhere((element) => element.name == name) != -1;
  }

  /// SinglesigVaultListItem 의 seed 중복 여부 확인
  bool isSeedDuplicated(Uint8List secret, Uint8List passphrase) {
    final coconutVault = SingleSignatureVault.fromMnemonic(
      secret,
      addressType: AddressType.p2wpkh,
      passphrase: passphrase,
    );
    final vaultIndex = _vaults.indexWhere((element) {
      if (element is SingleSigVaultListItem) {
        return (element.coconutVault as SingleSignatureVault).descriptor == coconutVault.descriptor;
      }
      return false;
    });
    return vaultIndex != -1;
  }

  /// 동일한 멀티시그 지갑 (xpub 집합 + 임계치 일치) 검색
  MultisigVaultListItem? findSameMultisigWallet(NormalizedMultisigConfig config) {
    final vaultIndex = _vaults.indexWhere((element) {
      if (element is! MultisigVaultListItem) return false;

      final wallet = element;

      if (wallet.requiredSignatureCount != config.requiredCount || wallet.signers.length != config.totalSigners) {
        return false;
      }

      try {
        final Set<String> existingWalletXpubs =
            wallet.signers.map((signer) {
              final bsmsToCheck = signer.signerBsms ?? "";
              final keyStore = KeyStore.fromSignerBsms(bsmsToCheck);

              return keyStore.extendedPublicKey.serialize(toXpub: true);
            }).toSet();

        final Set<String> newConfigXpubs =
            config.signerBsms.map((bsmsEntry) {
              final bsmsString = bsmsEntry.toString();
              final keyStore = KeyStore.fromSignerBsms(bsmsString);

              return keyStore.extendedPublicKey.serialize(toXpub: true);
            }).toSet();

        return setEquals(existingWalletXpubs, newConfigXpubs);
      } catch (e) {
        return false;
      }
    });

    return vaultIndex != -1 ? _vaults[vaultIndex] as MultisigVaultListItem : null;
  }

  /// MultisigVaultListItem 의 coordinatorBsms 중복 여부 확인
  MultisigVaultListItem? findMultisigWalletByCoordinatorBsms(String coordinatorBsms) {
    final vaultIndex = _vaults.indexWhere((element) {
      return (element is MultisigVaultListItem && element.coordinatorBsms == coordinatorBsms);
    });

    return vaultIndex != -1 ? _vaults[vaultIndex] as MultisigVaultListItem : null;
  }

  VaultListItemBase? findWalletByDescriptor(String descriptor) {
    final vaultIndex = _vaults.indexWhere((element) => element.coconutVault.descriptor == descriptor);

    return vaultIndex != -1 ? _vaults[vaultIndex] : null;
  }

  /// "내부 지갑"과 xpub 이 일치하는 경우에만 잘못된 MFP 를 내부 지갑의 올바른 MFP 로 교정한 새 [MultisigSigner] 리스트 반환.
  /// 매칭 실패 / 입력 BSMS 가 비어있으면 원본 signer 그대로.
  List<MultisigSigner> sanitizeSignerMfp(List<MultisigSigner> signers) {
    if (_vaults.isEmpty) return signers;

    return signers.map((signer) {
      if (signer.signerBsms == null || signer.signerBsms!.isEmpty) return signer;

      try {
        final inputKey = signer.keyStore.extendedPublicKey.toString();
        final inputMfp = signer.keyStore.masterFingerprint;

        final matchedVaultIndex = _vaults.indexWhere((v) {
          if (v is! SingleSigVaultListItem) return false;

          final String rawBsmsString = v.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false);
          try {
            final targetBsmsObj = SignerBsms.parse(rawBsmsString);
            final targetKey = targetBsmsObj.extendedKey;
            return isEquivalentExtendedPubKey(inputKey, targetKey);
          } catch (e) {
            return false;
          }
        });

        // replace MFP
        if (matchedVaultIndex != -1) {
          final matchedVault = _vaults[matchedVaultIndex];
          final correctMfp = (matchedVault.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
          bool isMfpMismatch = correctMfp.toUpperCase() != inputMfp.toUpperCase();

          if (!isMfpMismatch) {
            return signer;
          }

          final sanitizedBsms = signer.signerBsms!.replaceFirstMapped(
            RegExp(r'\[([0-9a-fA-F]{8})'),
            (match) => '[$correctMfp',
          );

          final sanitizedKeystore = KeyStore.fromSignerBsms(sanitizedBsms);
          return MultisigSigner(
            id: signer.id,
            keyStore: sanitizedKeystore,
            signerBsms: sanitizedBsms,
            innerVaultId: signer.innerVaultId,
            name: signer.name,
            colorIndex: signer.colorIndex,
            iconIndex: signer.iconIndex,
            signerSource: signer.signerSource,
            memo: signer.memo,
          );
        }
      } catch (e) {
        Logger.error('Error sanitizing signer MFP: $e');
      }

      return signer;
    }).toList();
  }
}
