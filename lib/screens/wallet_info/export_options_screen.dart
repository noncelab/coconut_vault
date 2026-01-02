import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VaultExportOptionsScreen extends StatefulWidget {
  const VaultExportOptionsScreen({super.key, required this.id, required this.walletType});
  final int id;
  final WalletType walletType;

  @override
  State<VaultExportOptionsScreen> createState() => _VaultExportOptionsScreenState();
}

class _VaultExportOptionsScreenState extends State<VaultExportOptionsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onTapShareWithOtherVault() {
    Navigator.pushReplacementNamed(context, AppRoutes.multisigBsmsView, arguments: {'id': widget.id});
  }

  void onTapExportWatchOnlyWallet() {
    _showSyncOptionBottomSheet(widget.id, context);
  }

  void onTapBackupWalletData() {
    Navigator.pushReplacementNamed(context, AppRoutes.backupWalletData, arguments: {'id': widget.id});
  }

  void onTapUseAsMultisigSigner() {
    Navigator.pushReplacementNamed(context, AppRoutes.multisigSignerBsmsExport, arguments: {'id': widget.id});
  }

  void _showSyncOptionBottomSheet(int walletId, BuildContext context) {
    MyBottomSheet.showBottomSheet_ratio(
      context: context,
      ratio: 0.5,
      child: SelectSyncOptionBottomSheet(
        onSyncOptionSelected: (format) {
          if (!context.mounted) return;
          Navigator.pop(context);
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.syncToWallet,
            arguments: {'id': walletId, 'syncOption': format},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(title: t.multi_sig_setting_screen.export_menu.export_wallet, context: context),
          body: SafeArea(
            minimum: const EdgeInsets.only(top: 10, right: 16, left: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.walletType == WalletType.multiSignature) ...[
                    // 다른 볼트와 공유하기 (멀티시그)
                    _buildOption(
                      t.multi_sig_setting_screen.export_menu.share_bsms,
                      t.multi_sig_setting_screen.export_menu.share_bsms_description,
                      onTapShareWithOtherVault,
                      true,
                    ),
                  ],
                  if (widget.walletType == WalletType.singleSignature) ...[
                    // 다중 서명키로 사용하기 (싱글시그)
                    _buildOption(
                      t.vault_menu_screen.title.use_as_multisig_signer,
                      t.vault_menu_screen.description.use_as_multisig_signer,
                      onTapUseAsMultisigSigner,
                      true,
                    ),
                  ],
                  CoconutLayout.spacing_300h,
                  // 보기 전용 앱으로 내보내기 (공용)
                  _buildOption(
                    t.multi_sig_setting_screen.export_menu.export_watch_only_wallet,
                    t.multi_sig_setting_screen.export_menu.export_watch_only_wallet_description,
                    onTapExportWatchOnlyWallet,
                    true,
                  ),
                  CoconutLayout.spacing_300h,
                  if (widget.walletType == WalletType.multiSignature) ...[
                    // 지갑 데이터 백업하기 (멀티시그)
                    _buildOption(
                      t.multi_sig_setting_screen.export_menu.backup_wallet_data,
                      t.multi_sig_setting_screen.export_menu.backup_wallet_data_description,
                      onTapBackupWalletData,
                      true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(String title, String description, VoidCallback onPressed, bool isSelectable) {
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray500.withValues(alpha: 0.1),
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
                        letterSpacing: 0.2,
                      ),
                    ),
                    CoconutLayout.spacing_100h,
                    Flexible(
                      child: Text(
                        overflow: TextOverflow.visible,
                        description,
                        style: CoconutTypography.body2_14.copyWith(
                          color: isSelectable ? CoconutColors.gray700 : CoconutColors.gray400,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 10),
            SvgPicture.asset(
              'assets/svg/chevron-right.svg',
              colorFilter: ColorFilter.mode(
                isSelectable ? CoconutColors.black : CoconutColors.gray400,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
