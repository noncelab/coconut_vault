import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';

class MultisigUtils {
  /// Singlesig 지갑에서 Multisig 지갑 import를 시도할 때 몇 번째 Signer로 사용되고 있는지 반환합니다.
  /// 사용되지 않은 경우 -1이 반환됩니다.
  static int getSignerIndexUsedInMultisig(MultisignatureVault multisigVault,
      SinglesigVaultListItem singlesigVaultListItem) {
    return multisigVault.keyStoreList.indexWhere((keyStore) =>
        keyStore.masterFingerprint ==
        (singlesigVaultListItem.coconutVault as SingleSignatureVault)
            .keyStore
            .masterFingerprint);
  }

  // totalCount는 최대 3까지만 가능합니다.
  static bool validateQuoramRequirement(int requiredCount, int totalCount) {
    return requiredCount > 0 &&
        requiredCount <= totalCount &&
        totalCount > 1 &&
        totalCount <= 3;
  }
}
