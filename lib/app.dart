import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/main_route_guard.dart';
import 'package:coconut_vault/model/multisig/multisig_creation_model.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart'
    as connectivityProvider;
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/airgap/multi_signature_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_confirmation_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_scanner_screen.dart';
import 'package:coconut_vault/screens/airgap/signed_transaction_qr_screen.dart';
import 'package:coconut_vault/screens/airgap/single_signature_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:coconut_vault/screens/security_self_check_screen.dart';
import 'package:coconut_vault/screens/setting/app_info_screen.dart';
import 'package:coconut_vault/screens/setting/mnemonic_word_list_screen.dart';
import 'package:coconut_vault/screens/start_guide/guide_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/tutorial_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_scan_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/vault_detail/address_list_screen.dart';
import 'package:coconut_vault/screens/vault_detail/multi_sig_bsms_screen.dart';
import 'package:coconut_vault/screens/vault_detail/multisig_setup_screen.dart';
import 'package:coconut_vault/screens/vault_detail/select_export_type_screen.dart';
import 'package:coconut_vault/screens/vault_detail/signer_bsms_screen.dart';
import 'package:coconut_vault/screens/vault_detail/sync_to_wallet_screen.dart';
import 'package:coconut_vault/screens/vault_detail/vault_menu_screen.dart';
import 'package:coconut_vault/screens/vault_detail/vault_settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/start_screen.dart';
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
        ChangeNotifierProxyProvider<VisibilityProvider,
            connectivityProvider.ConnectivityProvider>(
          create: (_) => connectivityProvider.ConnectivityProvider(
              hasSeenGuide: visibilityProvider.hasSeenGuide),
          update: (_, visibilityProvider, connectivityProvider) {
            if (visibilityProvider.hasSeenGuide) {
              connectivityProvider!.setHasSeenGuideTrue();
            }

            return connectivityProvider!;
          },
        ),

        /// splash, guide, main, pinCheck 에서 공통으로 사용하는 모델
        ChangeNotifierProvider(
          create: (_) => AppModel(
            onConnectivityStateChanged: (ConnectivityState state) {
              // Bluetooth, Network, Developer mode 리스너
              // TODO: connectivityProvider로 아래 로직 이동시키기
              // if (state == ConnectivityState.on) {
              //   goAppUnavailableNotificationScreen();
              // } else if (state == ConnectivityState.bluetoothUnauthorized) {
              //   goBluetoothAuthNotificationScreen();
              // }
            },
          ),
        ),
        if (_appEntryFlow == AppEntryFlow.vaultlist) ...{
          Provider<MultisigCreationModel>(
              create: (_) => MultisigCreationModel()),
          ChangeNotifierProxyProvider<AppModel, WalletProvider>(
            create: (_) => WalletProvider(
                Provider.of<AppModel>(
                  _,
                  listen: false,
                ),
                Provider.of<MultisigCreationModel>(_, listen: false)),
            update: (_, appModel, vaultModel) =>
                vaultModel!..updateAppModel(appModel),
          ),
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
                  (args) => VaultMenuScreen(id: args['id']),
                ),
            '/vault-settings': (context) => buildScreenWithArguments(
                context, (args) => VaultSettingsScreen(id: args['id'])),
            '/multisig-setup': (context) => buildScreenWithArguments(
                  context,
                  (args) => MultisigSetupScreen(id: args['id']),
                ),
            AppRoutes.multisigBsms: (context) => buildScreenWithArguments(
                  context,
                  (args) => MultiSigBsmsScreen(
                    id: args['id'],
                  ),
                ),
            AppRoutes.mnemonicWordList: (context) =>
                const MnemonicWordListScreen(),
            AppRoutes.addressList: (context) => buildScreenWithArguments(
                  context,
                  (args) => AddressListScreen(id: args['id']),
                ),
            AppRoutes.signerScanner: (context) => buildScreenWithArguments(
                  context,
                  (args) => SignerScanScreen(
                      id: args['id'], screenType: args['screenType']),
                ),
            AppRoutes.psbtScanner: (context) => buildScreenWithArguments(
                  context,
                  (args) => PsbtScannerScreen(id: args['id']),
                ),
            AppRoutes.psbtConfirmation: (context) => buildScreenWithArguments(
                  context,
                  (args) => PsbtConfirmationScreen(id: args['id']),
                ),
            AppRoutes.signedTransaction: (context) => buildScreenWithArguments(
                  context,
                  (args) => SignedTransactionQrScreen(id: args['id']),
                ),
            AppRoutes.syncToWallet: (context) => buildScreenWithArguments(
                  context,
                  (args) => SyncToWalletScreen(id: args['id']),
                ),
            AppRoutes.signerBsms: (context) => buildScreenWithArguments(
                  context,
                  (args) => SignerBsmsScreen(
                    id: args['id'],
                  ),
                ),
            AppRoutes.syncTypeSelection: (context) => buildScreenWithArguments(
                  context,
                  (args) => SelectExportTypeScreen(id: args['id']),
                ),
            AppRoutes.multiSignature: (context) => buildScreenWithArguments(
                  context,
                  (args) => MultiSignatureScreen(
                    id: args['id'],
                    psbtBase64: args['psbtBase64'],
                    sendAddress: args['sendAddress'],
                    bitcoinString: args['bitcoinString'],
                  ),
                ),
            AppRoutes.singleSignature: (context) => buildScreenWithArguments(
                  context,
                  (args) => SingleSignatureScreen(
                    id: args['id'],
                    psbtBase64: args['psbtBase64'],
                    sendAddress: args['sendAddress'],
                    bitcoinString: args['bitcoinString'],
                  ),
                ),
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
