import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/wallet_info_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_vault_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class TaprootWalletInfoScreen extends StatefulWidget {
  final int id;
  final String? entryPoint;
  const TaprootWalletInfoScreen({super.key, required this.id, this.entryPoint});

  @override
  State<TaprootWalletInfoScreen> createState() => _TaprootWalletInfoScreenState();
}

class _TaprootWalletInfoScreenState extends State<TaprootWalletInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final vault = walletProvider.getVaultById(widget.id);

    return ChangeNotifierProvider(
      create:
          (context) =>
              WalletInfoViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id, isMultisig: false),
      child: Consumer<WalletInfoViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              context: context,
              title: vault.name,
              actionButtonList: [
                IconButton(
                  onPressed: () {
                    // TODO: 삭제 팝업 로직 구현 (필요 시 WalletInfoLayout의 _showDeleteDialog 로직 이식)
                  },
                  icon: SvgPicture.asset(
                    'assets/svg/trash.svg',
                    width: 20,
                    colorFilter: const ColorFilter.mode(CoconutColors.red, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CoconutLayout.spacing_500h,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TaprootVaultItemCard(vaultItem: vault, showTaprootWalletInfo: true),
                    ),
                    CoconutLayout.spacing_500h,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ButtonGroup(
                        buttons: [
                          SingleButton(
                            title: t.vault_home_screen.action_items.sign,
                            onPressed:
                                () => Navigator.pushNamed(context, AppRoutes.psbtScanner, arguments: {'id': widget.id}),
                          ),
                          SingleButton(
                            title: t.view_address,
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.addressList,
                                  arguments: {'id': widget.id, 'isSpecificVault': true},
                                ),
                          ),
                          SingleButton(
                            title: t.vault_home_screen.action_items.export_wallet,
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.vaultExportOptions,
                                  arguments: {'id': widget.id, 'walletType': WalletType.taproot},
                                ),
                          ),
                        ],
                      ),
                    ),
                    CoconutLayout.spacing_500h,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
