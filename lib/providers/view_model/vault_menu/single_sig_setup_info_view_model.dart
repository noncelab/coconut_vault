import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/vault_setup_info_view_model_base.dart';

class SingleSigSetupInfoViewModel extends VaultSetupInfoViewModelBase<SingleSigVaultListItem> {
  int get linkedMutlsigVaultCount => vaultItem.linkedMultisigInfo?.length ?? 0;
  bool get hasLinkedMultisigVault => vaultItem.linkedMultisigInfo?.entries.isNotEmpty == true;
  Map<int, int>? get linkedMultisigInfo => vaultItem.linkedMultisigInfo;
  bool get isLoadedVaultList => walletProvider.isVaultsLoaded;
  bool get isVaultListLoading => walletProvider.isVaultListLoading;

  SingleSigSetupInfoViewModel(super.walletProvider, super.id);

  VaultListItemBase getVaultById(int id) {
    return walletProvider.getVaultById(id);
  }

  bool existsLinkedMultisigVault(int id) {
    return walletProvider.vaultList.any((element) => element.id == id);
  }
}
