import 'package:coconut_vault/app_shell.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/routes/common_routes.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/vault_mode_selection_screen.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/child_creation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/parent_creation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/passphrase_verification_screen.dart';
import 'package:coconut_vault/screens/wallet_info/taproot_sync_qr_screen.dart';
import 'package:coconut_vault/screens/wallet_info/taproot_wallet_info_screen.dart';
import 'package:coconut_vault/screens/airgap/taproot_sign_screen.dart';
import 'package:coconut_vault/utils/route_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 기존 진입점과의 호환성을 유지하는 래퍼.
class CoconutVaultApp extends StatelessWidget {
  const CoconutVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultApp(
      isLiteBuild: false,
      routesBuilder: _buildFullRoutes,
      fallbackRoutesBuilder: _buildFullFallbackRoutes,
      firstLaunchExtraBuilder: (context) => const TutorialScreen(screenStatus: TutorialScreenStatus.entrance),
      pinCheckScreenBuilder: (context, onSuccess, onReset, onPermanentlyLocked, onPermanentLockReset) {
        return PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.appLaunch,
          onSuccess: onSuccess,
          onReset: onReset,
          onPermanentlyLocked: onPermanentlyLocked,
          onPermanentLockReset: onPermanentLockReset,
        );
      },
    );
  }
}

Map<String, WidgetBuilder> _buildFullRoutes(VoidCallback onWelcomeComplete) => {
  ...buildCommonRoutes(onWelcomeComplete: onWelcomeComplete),
  AppRoutes.vaultNameSetup:
      (context) => buildScreenWithArguments(
        context,
        (args) => VaultNameAndIconSetupScreen(
          name: args['name'],
          iconIndex: args['iconIndex'],
          colorIndex: args['colorIndex'],
          isImported: args['isImported'],
        ),
      ),
  AppRoutes.taprootSetupInfo:
      (context) => buildScreenWithArguments(
        context,
        (args) => TaprootWalletInfoScreen(id: args['id'], entryPoint: args['entryPoint']),
      ),
  AppRoutes.taprootSyncView:
      (context) => buildScreenWithArguments(context, (args) => TaprootSyncQrScreen(id: args['id'])),
  AppRoutes.taprootSign: (context) => const TaprootSignScreen(),
  AppRoutes.taprootCreationOptions: (context) => const TaprootCreationOptionScreen(),
  AppRoutes.taprootParentCreation: (context) => const ParentCreationScreen(),
  AppRoutes.taprootChildCreation: (context) => const ChildCreationScreen(),
  AppRoutes.taprootPreparedCreation: (context) => const TaprootImportScreen(),
  AppRoutes.passphraseVerification:
      (context) => buildScreenWithArguments(context, (args) => PassphraseVerificationScreen(id: args['id'])),
  AppRoutes.vaultModeSelection: (context) => const VaultModeSelectionScreen(),
};

Map<String, WidgetBuilder> _buildFullFallbackRoutes(
  VoidCallback onWelcomeComplete,
  VoidCallback onModeSelectionComplete,
) => {
  AppRoutes.welcome: (context) => WelcomeScreen(onComplete: onWelcomeComplete),
  AppRoutes.vaultModeSelection:
      (context) =>
          buildScreenWithArguments(context, (args) => VaultModeSelectionScreen(onComplete: onModeSelectionComplete)),
};
