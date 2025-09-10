import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/main_route_guard.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
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
import 'package:coconut_vault/screens/app_update/restoration_info_screen.dart';
import 'package:coconut_vault/screens/app_update/vault_list_restoration_screen.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:coconut_vault/screens/app_update/app_update_preparation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/settings/app_info_screen.dart';
import 'package:coconut_vault/screens/settings/mnemonic_word_list_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/screens/common/multisig_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/vault_menu/address_list_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_bsms_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_setup_info_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/passphrase_verification_screen.dart';
import 'package:coconut_vault/screens/vault_menu/multisig_signer_bsms_export_screen.dart';
import 'package:coconut_vault/screens/vault_menu/sync_to_wallet/sync_to_wallet_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/single_sig_setup_info_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/start_screen.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:provider/provider.dart';

enum AppEntryFlow {
  splash,
  tutorial,
  pinCheck,
  vaultHome,
  pinCheckForRestoration, // 복원파일o, 업데이트o 일때 바로 이동하는 핀체크 화면
  foundBackupFile, // 복원파일o, 업데이트x 일때 이동하는 복원파일 발견 화면
  restoration, // 복원 진행 화면
}

class CoconutVaultApp extends StatefulWidget {
  const CoconutVaultApp({super.key});

  @override
  State<CoconutVaultApp> createState() => _CoconutVaultAppState();
}

class _CoconutVaultAppState extends State<CoconutVaultApp> {
  AppEntryFlow _appEntryFlow = AppEntryFlow.splash;
  bool _isInactive = false;

  void _updateEntryFlow(AppEntryFlow appEntryFlow) {
    setState(() {
      _appEntryFlow = appEntryFlow;
    });
  }

  Widget _buildPinCheckScreen({
    required AppEntryFlow nextFlow,
    VoidCallback? onReset,
  }) {
    return PinCheckScreen(
      pinCheckContext: PinCheckContextEnum.appLaunch,
      onSuccess: () => _updateEntryFlow(nextFlow),
      onReset: onReset ?? () async => _updateEntryFlow(AppEntryFlow.vaultHome),
    );
  }

  Widget _getHomeScreenRoute(AppEntryFlow status, BuildContext context) {
    switch (status) {
      case AppEntryFlow.splash:
        return StartScreen(onComplete: _updateEntryFlow);

      case AppEntryFlow.tutorial:
        if (NetworkType.currentNetworkType.isTestnet) {
          return const TutorialScreen(
            screenStatus: TutorialScreenStatus.entrance,
          );
        } else {
          onComplete() {
            _updateEntryFlow(AppEntryFlow.vaultHome);
          }

          return WelcomeScreen(onComplete: onComplete);
        }

      case AppEntryFlow.pinCheck:
        return CustomLoadingOverlay(
          child: _buildPinCheckScreen(nextFlow: AppEntryFlow.vaultHome),
        );

      case AppEntryFlow.pinCheckForRestoration:

        /// 복원 파일 o, 업데이트 o 일때 바로 이동하는 핀체크 화면
        return CustomLoadingOverlay(
          child: _buildPinCheckScreen(nextFlow: AppEntryFlow.restoration),
        );

      case AppEntryFlow.foundBackupFile:

        /// 복원파일 o, 업데이트 x 일때 이동하는 복원파일 발견 화면
        return CustomLoadingOverlay(
          child: RestorationInfoScreen(
            onComplete: () => _updateEntryFlow(AppEntryFlow.restoration),
            onReset: () async => _updateEntryFlow(AppEntryFlow.vaultHome),
          ),
        );

      case AppEntryFlow.restoration:

        /// 복원 진행 화면
        return CustomLoadingOverlay(
          child: VaultListRestorationScreen(
            onComplete: () => _updateEntryFlow(AppEntryFlow.vaultHome),
          ),
        );

      case AppEntryFlow.vaultHome:
        return const VaultHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    var visibilityProvider = VisibilityProvider();
    CoconutTheme.setTheme(Brightness.light);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => visibilityProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PreferenceProvider()),
        ChangeNotifierProxyProvider<VisibilityProvider, ConnectivityProvider>(
          create: (_) => ConnectivityProvider(hasSeenGuide: visibilityProvider.hasSeenGuide),
          update: (_, visibilityProvider, connectivityProvider) {
            if (visibilityProvider.hasSeenGuide) {
              connectivityProvider!.setHasSeenGuideTrue();
            }

            return connectivityProvider!;
          },
        ),
        if (_appEntryFlow == AppEntryFlow.vaultHome) ...{
          Provider<WalletCreationProvider>(create: (_) => WalletCreationProvider()),
          Provider<SignProvider>(create: (_) => SignProvider()),
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(
              Provider.of<VisibilityProvider>(_, listen: false),
              Provider.of<PreferenceProvider>(_, listen: false),
            ),
          )
        } else if (_appEntryFlow == AppEntryFlow.restoration) ...{
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(
              Provider.of<VisibilityProvider>(_, listen: false),
              Provider.of<PreferenceProvider>(_, listen: false),
            ),
          )
        }
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: _appEntryFlow == AppEntryFlow.vaultHome
            ? MainRouteGuard(
                onAppGoBackground: () => _updateEntryFlow(AppEntryFlow.pinCheck),
                onAppGoInactive: () {
                  setState(() {
                    _isInactive = true;
                  });
                },
                onAppGoActive: () {
                  setState(() {
                    _isInactive = false;
                  });
                },
                child: Stack(
                  children: [
                    CupertinoApp(
                      debugShowCheckedModeBanner: false,
                      localizationsDelegates: const [
                        DefaultMaterialLocalizations.delegate,
                        DefaultWidgetsLocalizations.delegate,
                        DefaultCupertinoLocalizations.delegate,
                      ],
                      theme: const CupertinoThemeData(
                        brightness: Brightness.light,
                        primaryColor: CoconutColors.black, // 기본 색상
                        scaffoldBackgroundColor: CoconutColors.white, // 배경색
                        textTheme: CupertinoTextThemeData(
                          navTitleTextStyle: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CoconutColors.gray800, // 제목 텍스트 색상
                          ),
                          textStyle: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: CoconutColors.black, // 기본 텍스트 색상
                          ),
                        ),
                        barBackgroundColor: CoconutColors.white,
                      ),
                      color: CoconutColors.white,
                      home: _getHomeScreenRoute(_appEntryFlow, context),
                      routes: {
                        AppRoutes.vaultList: (context) => const VaultListScreen(),
                        AppRoutes.vaultTypeSelection: (context) => const VaultTypeSelectionScreen(),
                        AppRoutes.multisigQuorumSelection: (context) =>
                            const MultisigQuorumSelectionScreen(),
                        AppRoutes.signerAssignment: (context) => const SignerAssignmentScreen(),
                        AppRoutes.vaultCreationOptions: (context) => const VaultCreationOptions(),
                        AppRoutes.mnemonicVerify: (context) => const MnemonicVerifyScreen(),
                        AppRoutes.mnemonicImport: (context) => const MnemonicImportScreen(),
                        AppRoutes.seedQrImport: (context) => const SeedQrImportScreen(),
                        AppRoutes.mnemonicConfirmation: (context) =>
                            const MnemonicConfirmationScreen(),
                        AppRoutes.mnemonicCoinflipConfirmation: (context) =>
                            const MnemonicCoinflipConfirmationScreen(),
                        AppRoutes.mnemonicView: (context) => buildScreenWithArguments(
                              context,
                              (args) => MnemonicViewScreen(
                                walletId: args['id'],
                              ),
                            ),
                        AppRoutes.vaultNameSetup: (context) => const VaultNameAndIconSetupScreen(),
                        AppRoutes.singleSigSetupInfo: (context) => buildScreenWithArguments(
                              context,
                              (args) => SingleSigSetupInfoScreen(
                                id: args['id'],
                                entryPoint: args['entryPoint'],
                              ),
                            ),
                        AppRoutes.multisigSetupInfo: (context) => buildScreenWithArguments(
                              context,
                              (args) => MultisigSetupInfoScreen(
                                id: args['id'],
                                entryPoint: args['entryPoint'],
                              ),
                            ),
                        AppRoutes.multisigBsmsView: (context) => buildScreenWithArguments(
                              context,
                              (args) => MultisigBsmsScreen(
                                id: args['id'],
                              ),
                            ),
                        AppRoutes.mnemonicWordList: (context) => const MnemonicWordListScreen(),
                        AppRoutes.addressList: (context) => buildScreenWithArguments(
                              context,
                              (args) => AddressListScreen(
                                id: args['id'],
                                isSpecificVault: args['isSpecificVault'] ?? false,
                              ),
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
                        AppRoutes.psbtConfirmation: (context) => const PsbtConfirmationScreen(),
                        AppRoutes.signedTransaction: (context) => const SignedTransactionQrScreen(),
                        AppRoutes.syncToWallet: (context) => buildScreenWithArguments(
                              context,
                              (args) => SyncToWalletScreen(
                                  id: args['id'], syncOption: args['syncOption']),
                            ),
                        AppRoutes.multisigSignerBsmsExport: (context) => buildScreenWithArguments(
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
                        AppRoutes.mnemonicGeneration: (context) => const MnemonicGenerationScreen(),
                        AppRoutes.mnemonicCoinflip: (context) => const MnemonicCoinflipScreen(),
                        AppRoutes.appInfo: (context) => const AppInfoScreen(),
                        AppRoutes.welcome: (context) {
                          onComplete() {
                            _updateEntryFlow(AppEntryFlow.vaultHome);
                          }

                          return WelcomeScreen(onComplete: onComplete);
                        },
                        AppRoutes.prepareUpdate: (context) => const CustomLoadingOverlay(
                              child: AppUpdatePreparationScreen(),
                            ),
                        AppRoutes.passphraseVerification: (context) => buildScreenWithArguments(
                              context,
                              (args) => PassphraseVerificationScreen(
                                id: args['id'],
                              ),
                            ),
                      },
                    ),
                    if (_isInactive)
                      Container(
                        color: CoconutColors.white,
                        child: Center(
                          child: Image.asset(
                              'assets/png/splash_logo_${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.png',
                              width: 60,
                              fit: BoxFit.fitWidth),
                        ),
                      ),
                  ],
                ),
              )
            : CupertinoApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  DefaultMaterialLocalizations.delegate,
                  DefaultWidgetsLocalizations.delegate,
                  DefaultCupertinoLocalizations.delegate,
                ],
                theme: const CupertinoThemeData(
                  brightness: Brightness.light,
                  primaryColor: CoconutColors.black, // 기본 색상
                  scaffoldBackgroundColor: CoconutColors.white, // 배경색
                  textTheme: CupertinoTextThemeData(
                    navTitleTextStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CoconutColors.gray800, // 제목 텍스트 색상
                    ),
                    textStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: CoconutColors.black, // 기본 텍스트 색상
                    ),
                  ),
                  barBackgroundColor: CoconutColors.white,
                ),
                color: CoconutColors.white,
                home: _getHomeScreenRoute(_appEntryFlow, context),
                routes: {
                  AppRoutes.vaultList: (context) => const VaultListScreen(),
                  AppRoutes.vaultTypeSelection: (context) => const VaultTypeSelectionScreen(),
                  AppRoutes.multisigQuorumSelection: (context) =>
                      const MultisigQuorumSelectionScreen(),
                  AppRoutes.signerAssignment: (context) => const SignerAssignmentScreen(),
                  AppRoutes.vaultCreationOptions: (context) => const VaultCreationOptions(),
                  AppRoutes.mnemonicVerify: (context) => const MnemonicVerifyScreen(),
                  AppRoutes.mnemonicImport: (context) => const MnemonicImportScreen(),
                  AppRoutes.seedQrImport: (context) => const SeedQrImportScreen(),
                  AppRoutes.mnemonicConfirmation: (context) => const MnemonicConfirmationScreen(),
                  AppRoutes.mnemonicCoinflipConfirmation: (context) =>
                      const MnemonicCoinflipConfirmationScreen(),
                  AppRoutes.mnemonicView: (context) => buildScreenWithArguments(
                        context,
                        (args) => MnemonicViewScreen(
                          walletId: args['id'],
                        ),
                      ),
                  AppRoutes.vaultNameSetup: (context) => const VaultNameAndIconSetupScreen(),
                  AppRoutes.singleSigSetupInfo: (context) => buildScreenWithArguments(
                        context,
                        (args) => SingleSigSetupInfoScreen(
                          id: args['id'],
                          entryPoint: args['entryPoint'],
                        ),
                      ),
                  AppRoutes.multisigSetupInfo: (context) => buildScreenWithArguments(
                        context,
                        (args) => MultisigSetupInfoScreen(
                          id: args['id'],
                          entryPoint: args['entryPoint'],
                        ),
                      ),
                  AppRoutes.multisigBsmsView: (context) => buildScreenWithArguments(
                        context,
                        (args) => MultisigBsmsScreen(
                          id: args['id'],
                        ),
                      ),
                  AppRoutes.mnemonicWordList: (context) => const MnemonicWordListScreen(),
                  AppRoutes.addressList: (context) => buildScreenWithArguments(
                        context,
                        (args) => AddressListScreen(
                          id: args['id'],
                          isSpecificVault: args['isSpecificVault'] ?? false,
                        ),
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
                  AppRoutes.psbtConfirmation: (context) => const PsbtConfirmationScreen(),
                  AppRoutes.signedTransaction: (context) => const SignedTransactionQrScreen(),
                  AppRoutes.syncToWallet: (context) => buildScreenWithArguments(
                        context,
                        (args) =>
                            SyncToWalletScreen(id: args['id'], syncOption: args['syncOption']),
                      ),
                  AppRoutes.multisigSignerBsmsExport: (context) => buildScreenWithArguments(
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
                  AppRoutes.mnemonicGeneration: (context) => const MnemonicGenerationScreen(),
                  AppRoutes.mnemonicCoinflip: (context) => const MnemonicCoinflipScreen(),
                  AppRoutes.appInfo: (context) => const AppInfoScreen(),
                  AppRoutes.welcome: (context) {
                    onComplete() {
                      _updateEntryFlow(AppEntryFlow.vaultHome);
                    }

                    return WelcomeScreen(onComplete: onComplete);
                  },
                  AppRoutes.prepareUpdate: (context) => const CustomLoadingOverlay(
                        child: AppUpdatePreparationScreen(),
                      ),
                  AppRoutes.passphraseVerification: (context) => buildScreenWithArguments(
                        context,
                        (args) => PassphraseVerificationScreen(
                          id: args['id'],
                        ),
                      ),
                },
              ),
      ),
    );
  }

  T buildScreenWithArguments<T>(BuildContext context, T Function(Map<String, dynamic>) builder,
      {Map<String, dynamic>? defaultArgs}) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? defaultArgs ?? {};
    return builder(args);
  }
}
