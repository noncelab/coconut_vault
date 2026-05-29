import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/coconut/extended_pubkey_utils.dart';

/// Maintains the in-memory link relationships between singlesig and multisig wallets
/// that share the same underlying key.
///
/// A vault holds multiple wallets (singlesig / multisig). When a singlesig wallet's key
/// also appears as a signer inside a multisig wallet, the two representations are linked
/// bidirectionally:
///   - the multisig signer carries metadata of the singlesig wallet via
///     [MultisigSigner.linkInternalWallet]
///   - the singlesig wallet tracks the multisigs it participates in via
///     [SingleSigVaultListItem.linkedMultisigInfo]
///
/// All operations are pure in-memory mutations on the supplied wallet list;
/// persistence is the repository's responsibility.
class WalletLinker {
  final List<VaultListItemBase> _wallets;

  WalletLinker(this._wallets);

  /// Links a newly added singlesig wallet to every existing multisig signer whose
  /// (masterFingerprint, derivationPath, xpub) triple matches, updating both sides.
  ///
  /// 이 경로는 사용자가 시드로부터 직접 생성한 싱글시그를 추가하는 흐름이며, 양쪽 모두 앱이
  /// 일관된 형식으로 채운 메타데이터를 가진다고 가정할 수 있어 3중 비교로 정확히 매칭한다.
  /// 외부 import 흐름에서의 변형 흡수가 필요한 매칭은 [attachInnerWalletMetadata] 참고.
  void linkNewSinglesigWallet(SingleSigVaultListItem singlesig) {
    outerLoop:
    for (int i = 0; i < _wallets.length; i++) {
      VaultListItemBase wallet = _wallets[i];
      if (wallet is! MultisigVaultListItem) continue;

      List<MultisigSigner> signers = wallet.signers;
      String expectedMfp = (singlesig.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;

      final bsms = Bsms.parseSigner(singlesig.signerBsmsByAddressType[AddressType.p2wsh]!);
      String expectedDerivationPath = bsms.signer!.path;
      String expectedXpub = bsms.signer!.extendedPublicKey.serialize(toXpub: true);
      for (int j = 0; j < signers.length; j++) {
        String signerMfp = signers[j].keyStore.masterFingerprint;
        String signerDerivationPath = signers[j].getSignerDerivationPath();
        String signerXpub = Bsms.parseSigner(signers[j].signerBsms!).signer!.extendedPublicKey.serialize(toXpub: true);
        if (signerMfp.toUpperCase() == expectedMfp.toUpperCase() &&
            signerDerivationPath == expectedDerivationPath &&
            signerXpub == expectedXpub) {
          wallet.signers[j].linkInternalWallet(singlesig);
          final linkedMultisigInfo = {wallet.id: j};
          if (singlesig.linkedMultisigInfo == null) {
            singlesig.linkedMultisigInfo = linkedMultisigInfo;
          } else {
            singlesig.linkedMultisigInfo!.addAll(linkedMultisigInfo);
          }
          // 같은 singlesig 가 하나의 multisig 지갑에 2번 이상 signer 로 등록될 수 없으므로
          continue outerLoop;
        }
      }
    }
  }

  /// Registers back-references on existing singlesig wallets referenced by the new
  /// multisig wallet's signers (via [MultisigSigner.innerVaultId]).
  void linkNewMultisigWallet(int newMultisigId, List<MultisigSigner> signers) {
    for (int i = 0; i < signers.length; i++) {
      final signer = signers[i];
      if (signer.innerVaultId == null) continue;
      final ssv = _wallets.firstWhere((element) => element.id == signer.innerVaultId!) as SingleSigVaultListItem;

      final keyMap = {newMultisigId: i};
      if (ssv.linkedMultisigInfo != null) {
        ssv.linkedMultisigInfo!.addAll(keyMap);
      } else {
        ssv.linkedMultisigInfo = keyMap;
      }
    }
  }

  /// Rollback helper after a failed singlesig add: scans every multisig signer and
  /// unlinks any reference to [singlesigId]. Full O(N*M) scan; intended for paths
  /// where [SingleSigVaultListItem.linkedMultisigInfo] may not be trusted.
  void unlinkSinglesigWallet(int singlesigId) {
    outerLoop:
    for (int i = 0; i < _wallets.length; i++) {
      VaultListItemBase wallet = _wallets[i];
      if (wallet is! MultisigVaultListItem) continue;

      List<MultisigSigner> signers = wallet.signers;
      for (int j = 0; j < signers.length; j++) {
        if (signers[j].innerVaultId == singlesigId) {
          signers[j].unlinkInternalWallet();
          continue outerLoop;
        }
      }
    }
  }

  /// Rollback helper after a failed multisig add: strips [multisigId] from every
  /// singlesig wallet's [SingleSigVaultListItem.linkedMultisigInfo].
  void unlinkMultisigWallet(int multisigId) {
    for (int i = 0; i < _wallets.length; i++) {
      VaultListItemBase wallet = _wallets[i];
      if (wallet is! SingleSigVaultListItem) continue;
      wallet.linkedMultisigInfo?.remove(multisigId);
    }
  }

  /// Cleans up cross-references before [wallet] is removed from the list.
  ///
  /// - Singlesig: uses its own [SingleSigVaultListItem.linkedMultisigInfo] (O(k))
  ///   to unlink the matching multisig signers directly.
  /// - Multisig: scans its signers and removes its id from every referenced singlesig's
  ///   [SingleSigVaultListItem.linkedMultisigInfo].
  void unlinkOnDelete(VaultListItemBase wallet) {
    if (wallet is SingleSigVaultListItem) {
      final links = wallet.linkedMultisigInfo;
      if (links?.isNotEmpty == true) {
        for (var entry in links!.entries) {
          final linkedVault = _findById(entry.key);
          if (linkedVault is! MultisigVaultListItem) continue;

          final multisig = linkedVault;
          multisig.signers[entry.value].unlinkInternalWallet();
          assert(multisig.signers[entry.value].signerBsms != null);
        }
      }
      return;
    }
    if (wallet is MultisigVaultListItem) {
      for (var signer in wallet.signers) {
        if (signer.innerVaultId != null) {
          final ssv = _findById(signer.innerVaultId!);
          if (ssv is SingleSigVaultListItem) {
            ssv.linkedMultisigInfo?.remove(wallet.id);
          }
        }
      }
    }
  }

  /// For an externally-supplied multisig signer, finds a singlesig wallet whose p2wsh
  /// extended pubkey is equivalent to the signer's and copies the singlesig's metadata
  /// (id / name / color / icon) onto the signer.
  ///
  /// Matching uses [isEquivalentExtendedPubKey] (xpub-equivalence only), distinct from
  /// [linkNewSinglesigWallet]'s stricter MFP+path+xpub match, by design.
  ///
  /// 외부 소스에서 import 된 BSMS 는 MFP 가 placeholder(`00000000`) 이거나 derivationPath
  /// 표기(`m/...` 접두사, `'`/`h` 표기, ypub/zpub variant 등)가 앱 내부 규칙과 다를 수
  /// 있으므로, xpub 정규화 비교만으로 "같은 지갑" 여부를 판정한다. 메타데이터 부착은 라벨링
  /// 용도라 false positive 의 보안 영향이 없고, 엄격 매칭으로 인한 false negative("내 지갑이
  /// 외부 signer 로 표시") UX 비용을 피하기 위한 의도된 선택이다.
  void attachInnerWalletMetadata(MultisigSigner signer) {
    assert(signer.signerBsms != null && signer.signerBsms!.isNotEmpty);

    final parsedInputBsms = SignerBsms.parse(signer.signerBsms!);
    final inputKey = parsedInputBsms.extendedKey;

    final walletIndex = _wallets.indexWhere((element) {
      if (element is! SingleSigVaultListItem) return false;
      final String rawBsmsString = element.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false);
      try {
        final targetBsmsObj = SignerBsms.parse(rawBsmsString);
        final targetKey = targetBsmsObj.extendedKey;
        return isEquivalentExtendedPubKey(inputKey, targetKey);
      } catch (e) {
        return false;
      }
    });

    if (walletIndex == -1) return;

    final wallet = _wallets[walletIndex];
    signer.innerVaultId = wallet.id;
    signer.name = wallet.name;
    signer.colorIndex = wallet.colorIndex;
    signer.iconIndex = wallet.iconIndex;
  }

  VaultListItemBase? _findById(int id) {
    for (final w in _wallets) {
      if (w.id == id) return w;
    }
    return null;
  }
}
