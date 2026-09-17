import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/screens/airgap/multisig_sign_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_confirmation_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_scanner_screen.dart';
import 'package:coconut_vault/screens/airgap/signed_transaction_qr_screen.dart';
import 'package:coconut_vault/screens/airgap/single_sig_sign_screen.dart';
import 'package:coconut_vault/screens/settings/app_info_screen.dart';
import 'package:coconut_vault/screens/settings/developer_screen.dart';
import 'package:coconut_vault/screens/settings/mnemonic_word_list_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/coordinator_bsms_config_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/coordinator_bsms_paste_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_dice_roll_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/screens/wallet_info/address_list_screen.dart';
import 'package:coconut_vault/screens/wallet_info/export_options_screen.dart';
import 'package:coconut_vault/screens/wallet_info/multisig_menu/backup_wallet_data_screen.dart';
import 'package:coconut_vault/screens/wallet_info/multisig_menu/coordinator_bsms_qr_screen.dart';
import 'package:coconut_vault/screens/wallet_info/multisig_wallet_info_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/extended_pub_key_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/signer_bsms_qr_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_wallet_info_screen.dart';
import 'package:coconut_vault/screens/wallet_info/sync_to_wallet_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:coconut_vault/utils/route_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// full 버전과 lite 버전이 공유하는 라우트 테이블.
///
/// flavor별로 추가/제외해야 하는 화면은 이 함수가 아닌 호출 측에서 처리합니다.
Map<String, WidgetBuilder> buildCommonRoutes({required VoidCallback onWelcomeComplete}) {
  return {
    AppRoutes.vaultList: (context) => const VaultListScreen(),
    AppRoutes.vaultTypeSelection: (context) => const VaultTypeSelectionScreen(),
    AppRoutes.signerAssignment: (context) => const SignerAssignmentScreen(),
    AppRoutes.vaultCreationOptions: (context) => const VaultCreationOptions(),
    AppRoutes.mnemonicVerify:
        (context) =>
            buildScreenWithArguments(context, (args) => MnemonicVerifyScreen(isTaproot: args['isTaproot'] ?? false)),
    AppRoutes.mnemonicImport:
        (context) => buildScreenWithArguments(
          context,
          (args) => MnemonicImportScreen(
            externalSigner: args['externalSigner'],
            multisigVaultIdOfExternalSigner: args['multisigVaultIdOfExternalSigner'],
            isTaprootCreationChild: args['isTaproot'] ?? false,
          ),
        ),
    AppRoutes.seedQrImport:
        (context) => buildScreenWithArguments(
          context,
          (args) => SeedQrImportScreen(
            externalSigner: args['externalSigner'],
            multisigVaultIdOfExternalSigner: args['multisigVaultIdOfExternalSigner'],
            isTaproot: args['isTaproot'] ?? false,
            requirePassphraseConfirmation: args['requirePassphraseConfirmation'] ?? true,
          ),
        ),
    AppRoutes.mnemonicConfirmation:
        (context) => buildScreenWithArguments(
          context,
          (args) => MnemonicConfirmationScreen(calledFrom: args['calledFrom'], isTaproot: args['isTaproot'] ?? false),
        ),
    AppRoutes.mnemonicView:
        (context) => buildScreenWithArguments(context, (args) => MnemonicViewScreen(walletId: args['id'])),
    AppRoutes.singleSigSetupInfo: (context) {
      return buildScreenWithArguments(
        context,
        (args) => SingleSigWalletInfoScreen(
          id: args['id'],
          entryPoint: args['entryPoint'],
          // 서명 전용 모드일 때는 항상 false
          shouldShowPassphraseVerifyMenu:
              context.read<PreferenceProvider>().isSigningOnlyMode ? false : args['shouldShowPassphraseVerifyMenu'],
        ),
      );
    },
    AppRoutes.multisigSetupInfo:
        (context) => buildScreenWithArguments(
          context,
          (args) => MultisigWalletInfoScreen(id: args['id'], entryPoint: args['entryPoint']),
        ),
    AppRoutes.multisigBsmsView:
        (context) => buildScreenWithArguments(context, (args) => CoordinatorBsmsQrScreen(id: args['id'])),
    AppRoutes.viewXpub: (context) => buildScreenWithArguments(context, (args) => ExtendedPubKeyScreen(id: args['id'])),
    AppRoutes.mnemonicWordList: (context) => const MnemonicWordListScreen(),
    AppRoutes.addressList:
        (context) => buildScreenWithArguments(
          context,
          (args) => AddressListScreen(id: args['id'], isSpecificVault: args['isSpecificVault'] ?? false),
        ),
    AppRoutes.multisigCreationOptions: (context) => const MultisigCreationOptionsScreen(),
    AppRoutes.multisigQuorumSelection: (context) => const MultisigQuorumSelectionScreen(),
    AppRoutes.coordinatorBsmsConfigScanner: (context) => const CoordinatorBsmsConfigScannerScreen(),
    AppRoutes.bsmsPaste: (context) => const CoordinatorBsmsPasteScreen(),
    AppRoutes.signerBsmsScanner:
        (context) => buildScreenWithArguments(context, (args) => SignerBsmsScannerScreen(id: args['id'])),
    AppRoutes.psbtScanner:
        (context) => buildScreenWithArguments(
          context,
          (args) => PsbtScannerScreen(id: args['id'], hardwareWalletType: args['hardwareWalletType']),
        ),
    AppRoutes.psbtConfirmation: (context) => const PsbtConfirmationScreen(),
    AppRoutes.signedTransaction:
        (context) =>
            buildScreenWithArguments(context, (args) => SignedTransactionQrScreen(tooltipText: args['tooltipText'])),
    AppRoutes.syncToWallet:
        (context) => buildScreenWithArguments(
          context,
          (args) => SyncToWalletScreen(id: args['id'], syncOption: args['syncOption']),
        ),
    AppRoutes.multisigSignerBsmsExport:
        (context) => buildScreenWithArguments(context, (args) => SignerBsmsQrScreen(id: args['id'])),
    AppRoutes.vaultExportOptions:
        (context) => buildScreenWithArguments(
          context,
          (args) => VaultExportOptionsScreen(id: args['id'], walletType: args['walletType']),
        ),
    AppRoutes.backupWalletData:
        (context) => buildScreenWithArguments(context, (args) => BackupWalletDataScreen(id: args['id'])),
    AppRoutes.multisigSign: (context) => const MultisigSignScreen(),
    AppRoutes.singleSigSign: (context) => const SingleSigSignScreen(),
    AppRoutes.securitySelfCheck: (context) {
      final VoidCallback? onNextPressed = ModalRoute.of(context)?.settings.arguments as VoidCallback?;
      return SecuritySelfCheckScreen(onNextPressed: onNextPressed);
    },
    AppRoutes.mnemonicAutoGen:
        (context) => buildScreenWithArguments(
          context,
          (args) => MnemonicAutoGenScreen(entropyType: EntropyType.auto, isTaproot: args['isTaproot'] ?? false),
        ),
    AppRoutes.mnemonicCoinflip:
        (context) => buildScreenWithArguments(
          context,
          (args) => MnemonicCoinflipScreen(entropyType: EntropyType.manual, isTaproot: args['isTaproot'] ?? false),
        ),
    AppRoutes.mnemonicDiceRoll:
        (context) => buildScreenWithArguments(
          context,
          (args) => MnemonicDiceRollScreen(entropyType: EntropyType.manual, isTaproot: args['isTaproot'] ?? false),
        ),
    AppRoutes.appInfo: (context) => const AppInfoScreen(),
    AppRoutes.welcome: (context) => WelcomeScreen(onComplete: onWelcomeComplete),
    AppRoutes.developer: (context) => const DeveloperScreen(),
  };
}
