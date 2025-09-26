import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VaultTypeSelectionScreen extends StatefulWidget {
  const VaultTypeSelectionScreen({super.key});

  @override
  State<VaultTypeSelectionScreen> createState() => _VaultTypeSelectionScreenState();
}

class _VaultTypeSelectionScreenState extends State<VaultTypeSelectionScreen> {
  String? nextPath;
  bool _showLoading = false;
  List<String> routesOptions = [AppRoutes.vaultCreationOptions, AppRoutes.multisigQuorumSelection];
  late final WalletProvider _walletProvider;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletProvider.isVaultListLoadingNotifier.addListener(_loadingListener);
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_loadingListener);
    super.dispose();
  }

  void _loadingListener() {
    if (!mounted) return;

    if (!_walletProvider.isVaultListLoadingNotifier.value) {
      if (_showLoading && nextPath != null) {
        setState(() {
          _showLoading = false;
        });

        Navigator.pushNamed(context, nextPath!);
      }
    }
  }

  void onTapSinglesigWallet() {
    Navigator.pushNamed(context, routesOptions[0]);
  }

  void onTapMultisigWallet() {
    if (_walletProvider.vaultList.isNotEmpty) {
      Navigator.pushNamed(context, routesOptions[1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(
            title: t.select_vault_type_screen.title,
            context: context,
          ),
          body: SafeArea(
            minimum: const EdgeInsets.only(top: 10, right: 16, left: 16),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildOption(t.single_sig_wallet, t.select_vault_type_screen.single_sig,
                        onTapSinglesigWallet, true),
                    CoconutLayout.spacing_300h,
                    _buildOption(t.multisig_wallet, t.select_vault_type_screen.multisig,
                        onTapMultisigWallet, _walletProvider.vaultList.isNotEmpty),
                  ],
                ),
                Visibility(
                  visible: _showLoading,
                  child: Container(
                    decoration: BoxDecoration(color: CoconutColors.black.withOpacity(0.3)),
                    child: Center(
                        child: MessageActivityIndicator(
                            message: t.select_vault_type_screen.loading_keys)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(String title, String description, VoidCallback onPressed, bool isSelectable) {
    return ShrinkAnimationButton(
        defaultColor: CoconutColors.gray150,
        pressedColor: CoconutColors.gray500.withOpacity(0.1),
        onPressed: isSelectable ? onPressed : () {},
        isActive: isSelectable,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: CoconutTypography.body1_16_Bold.copyWith(
                                color: isSelectable ? CoconutColors.black : CoconutColors.gray400,
                                letterSpacing: 0.2),
                          ),
                          CoconutLayout.spacing_100h,
                          Flexible(
                            child: Text(
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              description,
                              style: CoconutTypography.body3_12.copyWith(
                                  color:
                                      isSelectable ? CoconutColors.gray700 : CoconutColors.gray400,
                                  letterSpacing: 0.2,
                                  height: 1.2),
                            ),
                          ),
                        ],
                      )),
                ),
                Container(width: 10),
                SvgPicture.asset('assets/svg/chevron-right.svg',
                    colorFilter: ColorFilter.mode(
                        isSelectable ? CoconutColors.black : CoconutColors.gray400,
                        BlendMode.srcIn))
              ],
            )));
  }
}
