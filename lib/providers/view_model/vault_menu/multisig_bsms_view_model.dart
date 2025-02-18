import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class MultisigBsmsViewModel extends ChangeNotifier {
  late String qrData;
  List<int> outsideWalletIdList = [];

  MultisigBsmsViewModel(WalletProvider walletProvider, int id) {
    _init(walletProvider, id);
  }

  void _init(WalletProvider walletProvider, int id) {
    final vaultListItem =
        walletProvider.getVaultById(id) as MultisigVaultListItem;
    String coordinatorBsms = vaultListItem.coordinatorBsms ??
        (vaultListItem.coconutVault as MultisignatureVault)
            .getCoordinatorBsms();
    Map<String, dynamic> walletSyncString =
        jsonDecode(vaultListItem.getWalletSyncString());

    Map<String, String> namesMap = {};
    for (var signer in vaultListItem.signers) {
      namesMap[signer.keyStore.masterFingerprint] = signer.name!;
    }

    qrData = jsonEncode(MultisigImportDetail(
      name: walletSyncString['name'],
      colorIndex: walletSyncString['colorIndex'],
      iconIndex: walletSyncString['iconIndex'],
      namesMap: namesMap,
      coordinatorBsms: coordinatorBsms,
    ));

    _getOutsideWalletIdList(vaultListItem);
    notifyListeners();
  }

  void _getOutsideWalletIdList(MultisigVaultListItem item) {
    for (MultisigSigner signer in item.signers) {
      if (signer.innerVaultId == null) {
        outsideWalletIdList.add(signer.id + 1);
      }
    }
  }

  String generateOutsideWalletDescription({bool isAnd = false}) {
    if (outsideWalletIdList.isEmpty) return '';
    if (outsideWalletIdList.length == 1) {
      return t.multi_sig_bsms_screen
          .first_key(first: outsideWalletIdList.first);
    }
    return t.multi_sig_bsms_screen.first_or_last_key(
        first: outsideWalletIdList.first, last: outsideWalletIdList.last);
  }
}
