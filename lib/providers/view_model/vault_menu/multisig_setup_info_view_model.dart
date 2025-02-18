import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/singlesig/singlesig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/material.dart';

class MultisigSetupInfoViewModel extends ChangeNotifier {
  late final WalletProvider _walletProvider;
  late final MultisigVaultListItem _vaultListItem;
  late int signAvailableCount;

  MultisigVaultListItem get vaultItem => _vaultListItem;
  String get name => _vaultListItem.name;
  int get colorIndex => _vaultListItem.colorIndex;
  int get iconIndex => _vaultListItem.iconIndex;
  List<MultisigSigner> get signers => _vaultListItem.signers;
  int get requiredSignatureCount => _vaultListItem.requiredSignatureCount;

  MultisigSetupInfoViewModel(this._walletProvider, int id) {
    _vaultListItem = _walletProvider.getVaultById(id) as MultisigVaultListItem;
    _calculateSignAvailableCount();
  }

  void _calculateSignAvailableCount() {
    int innerVaultCount = _vaultListItem.signers
        .where((signer) => signer.innerVaultId != null)
        .length;
    signAvailableCount = innerVaultCount > _vaultListItem.requiredSignatureCount
        ? _vaultListItem.requiredSignatureCount
        : innerVaultCount;
  }

  Future<bool> updateVault(
      int id, String name, int colorIndex, int iconIndex) async {
    if (name == _vaultListItem.name &&
        colorIndex == _vaultListItem.colorIndex &&
        iconIndex == _vaultListItem.iconIndex) {
      return false;
    }

    if (name != _vaultListItem.name && _walletProvider.isNameDuplicated(name)) {
      Logger.log('Duplicated name');
      return false;
    }

    await _walletProvider.updateVault(id, name, colorIndex, iconIndex);
    notifyListeners();
    return true;
  }

  Future<void> updateOutsideVaultMemo(int signerIndex, String? memo) async {
    if (_vaultListItem.signers[signerIndex].memo != memo) {
      await _walletProvider.updateMemo(_vaultListItem.id, signerIndex, memo);
      notifyListeners();
    }
  }

  MultisigSigner getSignerInfo(int signerIndex) {
    return _vaultListItem.signers[signerIndex];
  }

  Future<void> deleteVault() async {
    await _walletProvider.deleteVault(_vaultListItem.id);
  }

  SinglesigVaultListItem getInnerVaultListItem(int index) {
    return _vaultListItem.signers[index] as SinglesigVaultListItem;
  }
}
