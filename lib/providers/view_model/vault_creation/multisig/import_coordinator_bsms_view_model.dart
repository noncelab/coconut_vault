import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/common/wallet_address.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:flutter/foundation.dart';

class ImportCoordinatorBsmsViewModel {
  final WalletProvider _walletProvider;
  final WalletCreationProvider _walletCreationProvider;

  ImportCoordinatorBsmsViewModel(this._walletProvider, this._walletCreationProvider);

  bool isCoconutMultisigConfig(dynamic multisigWalletInfo) {
    return multisigWalletInfo is Map<String, dynamic> &&
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
    );
  }
}
