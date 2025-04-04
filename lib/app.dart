import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/main_route_guard.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/airgap/multisig_sign_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_confirmation_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_scanner_screen.dart';
import 'package:coconut_vault/screens/airgap/signed_transaction_qr_screen.dart';
import 'package:coconut_vault/screens/airgap/single_sig_sign_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/settings/app_info_screen.dart';
import 'package:coconut_vault/screens/settings/mnemonic_word_list_screen.dart';
import 'package:coconut_vault/screens/start_guide/guide_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/screens/common/multisig_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/vault_menu/address_list_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_bsms_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_setup_info_screen.dart';
import 'package:coconut_vault/screens/vault_menu/multisig_signer_bsms_export_screen.dart';
import 'package:coconut_vault/screens/vault_menu/sync_to_wallet/sync_to_wallet_screen.dart';
import 'package:coconut_vault/screens/home/vault_menu_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/single_sig_setup_info_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/start_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:provider/provider.dart';

enum AppEntryFlow {
  splash,
  tutorial,
  pincheck,
  vaultlist,
}

class CoconutVaultApp extends StatefulWidget {
  const CoconutVaultApp({super.key});

  @override
  State<CoconutVaultApp> createState() => _CoconutVaultAppState();
}

class _CoconutVaultAppState extends State<CoconutVaultApp> {
  AppEntryFlow _appEntryFlow = AppEntryFlow.splash;

  void _updateEntryFlow(AppEntryFlow appEntryFlow) {
    setState(() {
      _appEntryFlow = appEntryFlow;
    });
  }

  Widget _getHomeScreenRoute(AppEntryFlow status, BuildContext context) {
    if (status == AppEntryFlow.splash) {
      return StartScreen(onComplete: (status) {
        _updateEntryFlow(status);
      });
    } else if (status == AppEntryFlow.tutorial) {
      return const TutorialScreen(
        screenStatus: TutorialScreenStatus.entrance,
      );
    } else if (status == AppEntryFlow.pincheck) {
      return CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.appLaunch,
          onComplete: () {
            _updateEntryFlow(AppEntryFlow.vaultlist);
          },
          onReset: () async {
            /// 초기화 이후 메인 라우터 이동
            _updateEntryFlow(AppEntryFlow.vaultlist);
          },
        ),
      );
    }

    return MainRouteGuard(
      onAppGoBackground: () {
        _updateEntryFlow(AppEntryFlow.pincheck);
      },
      child: const VaultListScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var visibilityProvider = VisibilityProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => visibilityProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<VisibilityProvider, ConnectivityProvider>(
          create: (_) => ConnectivityProvider(
              hasSeenGuide: visibilityProvider.hasSeenGuide),
          update: (_, visibilityProvider, connectivityProvider) {
            if (visibilityProvider.hasSeenGuide) {
              connectivityProvider!.setHasSeenGuideTrue();
            }

            return connectivityProvider!;
          },
        ),
        if (_appEntryFlow == AppEntryFlow.vaultlist) ...{
          Provider<WalletCreationProvider>(
              create: (_) => WalletCreationProvider()),
          Provider<SignProvider>(create: (_) => SignProvider()),
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(
                Provider.of<VisibilityProvider>(_, listen: false)),
          )
        }
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CupertinoApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          theme: const CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.blue, // 기본 색상
            scaffoldBackgroundColor: MyColors.white, // 배경색
            textTheme: CupertinoTextThemeData(
              navTitleTextStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MyColors.darkgrey, // 제목 텍스트 색상
              ),
              textStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.black, // 기본 텍스트 색상
              ),
            ),
          ),
          color: MyColors.black,
          home: _getHomeScreenRoute(_appEntryFlow, context),
          routes: {
            AppRoutes.vaultTypeSelection: (context) =>
                const VaultTypeSelectionScreen(),
            AppRoutes.multisigQuorumSelection: (context) =>
                const MultisigQuorumSelectionScreen(),
            AppRoutes.signerAssignment: (context) =>
                const SignerAssignmentScreen(),
            AppRoutes.vaultCreationOptions: (context) =>
                const VaultCreationOptions(),
            AppRoutes.mnemonicImport: (context) => const MnemonicImport(),
            AppRoutes.vaultNameSetup: (context) =>
                const VaultNameAndIconSetupScreen(),
            AppRoutes.vaultDetails: (context) => buildScreenWithArguments(
                  context,
                  (args) => VaultMenuBottomSheet(id: args['id']),
                ),
            AppRoutes.singleSigSetupInfo: (context) => buildScreenWithArguments(
                context, (args) => SingleSigSetupInfoScreen(id: args['id'])),
            AppRoutes.multisigSetupInfo: (context) => buildScreenWithArguments(
                  context,
                  (args) => MultisigSetupInfoScreen(id: args['id']),
                ),
            AppRoutes.multisigBsmsView: (context) => buildScreenWithArguments(
                  context,
                  (args) => MultisigBsmsScreen(
                    id: args['id'],
                  ),
                ),
            AppRoutes.mnemonicWordList: (context) =>
                const MnemonicWordListScreen(),
            AppRoutes.addressList: (context) => buildScreenWithArguments(
                  context,
                  (args) => AddressListScreen(id: args['id']),
                ),
            AppRoutes.signerBsmsScanner: (context) => buildScreenWithArguments(
                  context,
                  (args) => MultisigBsmsScannerScreen(
                      id: args['id'], screenType: args['screenType']),
                ),
            AppRoutes.psbtScanner: (context) => buildScreenWithArguments(
                  context,
                  (args) => PsbtScannerScreen(id: args['id']),
                ),
            AppRoutes.psbtConfirmation: (context) =>
                const PsbtConfirmationScreen(),
            AppRoutes.signedTransaction: (context) =>
                const SignedTransactionQrScreen(),
            AppRoutes.syncToWallet: (context) => buildScreenWithArguments(
                  context,
                  (args) => SyncToWalletScreen(id: args['id']),
                ),
            AppRoutes.multisigSignerBsmsExport: (context) =>
                buildScreenWithArguments(
                  context,
                  (args) => MultisigSignerBsmsExportScreen(
                    id: args['id'],
                  ),
                ),
            AppRoutes.multisigSign: (context) => const MultisigSignScreen(),
            AppRoutes.singleSigSign: (context) => const SingleSigSignScreen(),
            AppRoutes.securitySelfCheck: (context) {
              final VoidCallback? onNextPressed =
                  ModalRoute.of(context)?.settings.arguments as VoidCallback?;
              return SecuritySelfCheckScreen(onNextPressed: onNextPressed);
            },
            AppRoutes.mnemonicGeneration: (context) =>
                const MnemonicGenerationScreen(),
            AppRoutes.mnemonicCoinflip: (context) =>
                const MnemonicCoinflipScreen(),
            AppRoutes.appInfo: (context) => const AppInfoScreen(),
            AppRoutes.welcome: (context) => const WelcomeScreen(),
            AppRoutes.connectivityGuide: (context) {
              onComplete() {
                _updateEntryFlow(AppEntryFlow.vaultlist);
              }

              return GuideScreen(onComplete: onComplete);
            }
          },
        ),
      ),
    );
  }

  T buildScreenWithArguments<T>(
      BuildContext context, T Function(Map<String, dynamic>) builder,
      {Map<String, dynamic>? defaultArgs}) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            defaultArgs ??
            {};
    return builder(args);
  }
}
