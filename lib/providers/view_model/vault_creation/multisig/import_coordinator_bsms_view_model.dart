import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
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

  void validateBsmsNetwork(String bsms) {
    /// Validates the network integrity of the BSMS data.
    /// 1. Internal Consistency: Detects mismatches between the Key network and Derivation Path network.
    /// 2. App Compliance: Ensures the data aligns with the current application network (Mainnet/Testnet).

    final bool isAppMainnet = NetworkType.currentNetworkType == NetworkType.mainnet;
    final String rawData = bsms.toLowerCase();

    final bool isKeyTestnet = rawData.contains('tpub') || rawData.contains('vpub') || rawData.contains('upub');
    final bool isKeyMainnet = rawData.contains('xpub') || rawData.contains('zpub') || rawData.contains('ypub');

    final bool isPathTestnet = RegExp(r"/(44|45|48|49|84|86)'?/1'?/").hasMatch(rawData);
    final bool isPathMainnet = RegExp(r"/(44|45|48|49|84|86)'?/0'?/").hasMatch(rawData);

    if (isKeyMainnet && isPathTestnet) {
      throw const FormatException('Mainnet key with Testnet derivation path');
    }
    if (isKeyTestnet && isPathMainnet) {
      throw const FormatException('Testnet key with Mainnet derivation path');
    }

    final bool isDataTestnet = isKeyTestnet || isPathTestnet;
    final bool isDataMainnet = isKeyMainnet || isPathMainnet;

    if (isAppMainnet && isDataTestnet) {
      throw NetworkMismatchException(message: t.alert.bsms_network_mismatch.description_when_mainnet);
    }

    if (!isAppMainnet && isDataMainnet) {
      throw NetworkMismatchException(message: t.alert.bsms_network_mismatch.description_when_testnet);
    }
  }
}
