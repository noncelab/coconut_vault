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

  Future<void> updateOutsideVaultName(int signerIndex, String? name) async {
    if (vaultItem.signers[signerIndex].signerName != name) {
      await walletProvider.updateExternalSignerName(vaultItem.id, signerIndex, name);
      notifyListeners();
    }
  }

  Future<void> updateSignerSource(int signerIndex, SignerSource source) async {
    if (vaultItem.signers[signerIndex].signerSource != source) {
      await walletProvider.updateExternalSignerSource(vaultItem.id, signerIndex, source);
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
