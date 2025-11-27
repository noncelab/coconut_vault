import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/qr_with_copy_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExtendedPubKeyScreen extends StatelessWidget {
  final int id;

  const ExtendedPubKeyScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final vault = walletProvider.getVaultById(id) as SingleSigVaultListItem;
    final singleSigVault = vault.coconutVault as SingleSignatureVault;

    // KeyStore의 extendedPublicKey를 직렬화해서 xpub 문자열로 사용
    final xpub = singleSigVault.keyStore.extendedPublicKey.serialize();

    return QrWithCopyTextScreen(title: t.extended_public_key, qrData: xpub);
  }
}
