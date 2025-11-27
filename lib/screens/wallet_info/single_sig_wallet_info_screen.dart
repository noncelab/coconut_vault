import 'dart:async';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/wallet_info_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/wallet_info/wallet_info_layout.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:provider/provider.dart';

class SingleSigWalletInfoScreen extends StatelessWidget {
  final int id;
  // 서명 전용 모드에서는 항상 false입니다.
  final bool shouldShowPassphraseVerifyMenu;
  final String? entryPoint;
  const SingleSigWalletInfoScreen({
    super.key,
    required this.id,
    required this.shouldShowPassphraseVerifyMenu,
    this.entryPoint,
  });

  Future<void> _authenticateWithBiometricOrPin(
    BuildContext context,
    PinCheckContextEnum pinCheckContext,
    VoidCallback onSuccess,
  ) async {
    final authProvider = context.read<AuthProvider>();

    final isBiometricValid =
        pinCheckContext == PinCheckContextEnum.sensitiveAction
            ? await authProvider.isBiometricsAuthValidToAvoidDoubleAuth()
            : await authProvider.isBiometricsAuthValid();

    if (isBiometricValid && context.mounted) {
      onSuccess();
      return;
    }

    if (!context.mounted) return;
    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: pinCheckContext,
          onSuccess: () async {
            Navigator.pop(context);
            onSuccess();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => WalletInfoViewModel(Provider.of<WalletProvider>(context, listen: false), id, isMultisig: false),
      child: WalletInfoLayout(
        id: id,
        shouldShowPassphraseVerifyMenu: shouldShowPassphraseVerifyMenu,
        isMultisig: false,
        menuButtonDatas: [
          SingleButtonData(
            title: t.vault_menu_screen.title.single_sig_sign,
            enableShrinkAnim: true,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.psbtScanner, arguments: {'id': id}),
          ),
          SingleButtonData(
            title: t.view_address,
            enableShrinkAnim: true,
            onPressed:
                () =>
                    Navigator.pushNamed(context, AppRoutes.addressList, arguments: {'id': id, 'isSpecificVault': true}),
          ),
          SingleButtonData(
            title: t.vault_menu_screen.view_xpub,
            enableShrinkAnim: true,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.viewXpub, arguments: {'id': id}),
          ),
          SingleButtonData(
            title: t.view_mnemonic,
            enableShrinkAnim: true,
            onPressed: () {
              if (!context.mounted) return;
              final walletProvider = context.read<WalletProvider>();
              if (walletProvider.isSigningOnlyMode) {
                Navigator.pushNamed(context, AppRoutes.mnemonicView, arguments: {'id': id});
                return;
              }

              _authenticateWithBiometricOrPin(
                context,
                PinCheckContextEnum.sensitiveAction,
                () => Navigator.pushNamed(context, AppRoutes.mnemonicView, arguments: {'id': id}),
              );
            },
          ),
          if (shouldShowPassphraseVerifyMenu) ...{
            SingleButtonData(
              title: t.verify_passphrase,
              enableShrinkAnim: true,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.passphraseVerification, arguments: {'id': id}),
            ),
          },
          SingleButtonData(
            title: t.vault_menu_screen.export_wallet,
            enableShrinkAnim: true,
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.vaultExportOptions,
                  arguments: {'id': id, 'walletType': WalletType.singleSignature},
                ),
          ),
        ],
      ),
    );
  }
}
