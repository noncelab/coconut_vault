import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';

class ImportCoordinatorBsmsViewModel {
  final WalletProvider _walletProvider;

  ImportCoordinatorBsmsViewModel(this._walletProvider);

  bool isCoconutMultisigConfig(dynamic multisigWalletInfo) {
    return multisigWalletInfo is Map<String, dynamic> &&
        multisigWalletInfo.containsKey(VaultListItemBase.fieldName) &&
        multisigWalletInfo.containsKey(VaultListItemBase.fieldColorIndex) &&
        multisigWalletInfo.containsKey(VaultListItemBase.fieldIconIndex);
  }

  String? findSameWalletName(NormalizedMultisigConfig multisigConfig) {
    final result = _walletProvider.findSameMultisigWallet(multisigConfig);
    return result?.name;
  }

  Future<MultisigVaultListItem> addMultisigVault(
    NormalizedMultisigConfig multisigConfig,
    int color,
    int icon,
    List<MultisigSigner> signers,
  ) async {
    return await _walletProvider.addMultisigVault(
      multisigConfig.name,
      color,
      icon,
      signers,
      multisigConfig.requiredCount,
      isImported: true,
    );
  }

  List<MultisigSigner> getMultisigSignersFromMultisigConfig(NormalizedMultisigConfig multisigConfig) {
    return multisigConfig.signerBsms.asMap().entries.map((entry) {
      int index = entry.key;
      String signerBsms = entry.value.toString();
      KeyStore keystore = KeyStore.fromSignerBsms(signerBsms);

      return MultisigSigner(
        id: index,
        keyStore: keystore,
        signerBsms: signerBsms,
        innerVaultId: null,
        memo: entry.value.label,
      );
    }).toList();
  }
}
