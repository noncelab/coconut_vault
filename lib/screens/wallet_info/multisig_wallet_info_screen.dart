import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/wallet_info_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/wallet_info/wallet_info_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MultisigWalletInfoScreen extends StatefulWidget {
  final int id;
  final String? entryPoint;
  const MultisigWalletInfoScreen({super.key, required this.id, this.entryPoint});

  @override
  State<MultisigWalletInfoScreen> createState() => _MultisigWalletInfoScreenState();
}

class _MultisigWalletInfoScreenState extends State<MultisigWalletInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) =>
              WalletInfoViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id, isMultisig: true),
      child: WalletInfoLayout(
        id: widget.id,
        isMultisig: true,
        entryPoint: widget.entryPoint,
        menuButtonDatas: [
          SingleButtonData(
            title: t.vault_menu_screen.title.multisig_sign,
            enableShrinkAnim: true,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.psbtScanner, arguments: {'id': widget.id}),
          ),
          SingleButtonData(
            title: t.view_address,
            enableShrinkAnim: true,
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.addressList,
                  arguments: {'id': widget.id, 'isSpecificVault': true},
                ),
          ),
          SingleButtonData(
            title: t.multi_sig_setting_screen.export_menu.export_wallet,
            enableShrinkAnim: true,
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.vaultExportOptions,
                  arguments: {'id': widget.id, 'walletType': WalletType.multiSignature},
                ),
          ),
        ],
      ),
    );
  }
}
