import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/vault_setup_info_view_model_base.dart';

class MultisigSetupInfoViewModel extends VaultSetupInfoViewModelBase<MultisigVaultListItem> {
  late int signAvailableCount;
  List<MultisigSigner> get signers => vaultItem.signers;
  int get requiredSignatureCount => vaultItem.requiredSignatureCount;

  MultisigSetupInfoViewModel(super.walletProvider, super.id) {
    _calculateSignAvailableCount();
  }

  void _calculateSignAvailableCount() {
    int innerVaultCount = vaultItem.signers.where((signer) => signer.innerVaultId != null).length;
    signAvailableCount =
        innerVaultCount > vaultItem.requiredSignatureCount ? vaultItem.requiredSignatureCount : innerVaultCount;
  }

  Future<void> updateOutsideVaultMemo(int signerIndex, String? memo) async {
    if (vaultItem.signers[signerIndex].memo != memo) {
      await walletProvider.updateMemo(vaultItem.id, signerIndex, memo);
      notifyListeners();
    }
  }

  MultisigSigner getSignerInfo(int signerIndex) {
    return vaultItem.signers[signerIndex];
  }

  SingleSigVaultListItem getInnerVaultListItem(int index) {
    return vaultItem.signers[index] as SingleSigVaultListItem;
  }
}
