import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';

class MultisigSignerFactory {
  /// MultisigVault를 볼트 리스트에 추가하기 위해 Signer 리스트를 생성합니다.
  ///
  /// - **multisigVault**: MultisignatureVault 인스턴스. 새롭게 생성할 Signer들이 속할 다중서명 지갑입니다.
  /// - **vaultList**: VaultListItemBase 타입의 객체 리스트. 다중서명 지갑의 Signer와 비교할 기존 볼트 리스트입니다.
  ///
  /// 반환값은 생성된 `MultisigSigner`의 리스트입니다.
  static List<MultisigSigner> createSignersForMultisignatureVaultWhenImport({
    required MultisignatureVault multisigVault,
    required List<VaultListItemBase> vaultList,
  }) {
    List<KeyStore> keystoreList = multisigVault.keyStoreList;
    List<VaultListItemBase> singlesigVaults = vaultList
        .where((e) => e.vaultType == VaultType.singleSignature)
        .toList();

    List<MultisigSigner> signers = [];

    outerLoop:
    for (int i = 0; i < keystoreList.length; i++) {
      for (int j = 0; j < singlesigVaults.length; j++) {
        // 변수 정의
        SinglesigVaultListItem singlesigVaultListItem =
            singlesigVaults[j] as SinglesigVaultListItem;
        SingleSignatureVault singlesigVault =
            singlesigVaultListItem.coconutVault as SingleSignatureVault;
        // p2wsh용 keyStore 생성. 기존 SinglesigVaultListItem의 addressType은 p2wpkh여서 바로 사용하면 안됨.
        KeyStore wshKeyStore =
            KeyStore.fromSeed(singlesigVault.keyStore.seed, AddressType.p2wsh);

        // 1. 내부 지갑인 경우
        if (keystoreList[i].masterFingerprint ==
            singlesigVault.keyStore.masterFingerprint) {
          signers.add(MultisigSigner(
            id: i,
            signerBsms: singlesigVault.getSignerBsms(AddressType.p2wsh, ''),
            innerVaultId: singlesigVaults[j].id,
            keyStore: wshKeyStore, // AddressType.p2wsh로 설정해서 만든 KeyStore
            name: singlesigVaultListItem.name,
            iconIndex: singlesigVaultListItem.iconIndex,
            colorIndex: singlesigVaultListItem.colorIndex,
          ));
          continue outerLoop;
        }
      }
      // 2. 외부지갑인 경우
      signers
          .add(MultisigSigner(id: i, keyStore: multisigVault.keyStoreList[i]));
    }

    return signers;
  }
}
