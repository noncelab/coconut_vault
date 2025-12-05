import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class CoordinatorBsmsQrViewModel extends ChangeNotifier {
  late String qrData;

  CoordinatorBsmsQrViewModel(WalletProvider walletProvider, int id) {
    _init(walletProvider, id);
  }

  void _init(WalletProvider walletProvider, int id) {
    final vaultListItem = walletProvider.getVaultById(id) as MultisigVaultListItem;
    String coordinatorBsms =
        vaultListItem.coordinatorBsms ?? (vaultListItem.coconutVault as MultisignatureVault).getCoordinatorBsms();
    Map<String, dynamic> walletSyncString = jsonDecode(vaultListItem.getWalletSyncString());

    Map<String, String> namesMap = {};
    for (var signer in vaultListItem.signers) {
      if (signer.name == null) continue;
      namesMap[signer.keyStore.masterFingerprint] = signer.name!;
    }

    qrData = jsonEncode(
      MultisigImportDetail(
        name: walletSyncString['name'],
        colorIndex: walletSyncString['colorIndex'],
        iconIndex: walletSyncString['iconIndex'],
        namesMap: namesMap,
        coordinatorBsms: coordinatorBsms,
      ),
    );

    notifyListeners();
  }
}
