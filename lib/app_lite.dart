import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/airgap/multisig_sign_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_confirmation_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_scanner_screen.dart';
import 'package:coconut_vault/screens/airgap/signed_transaction_qr_screen.dart';
import 'package:coconut_vault/screens/airgap/single_sig_sign_screen.dart';

import 'package:coconut_vault/screens/common/app_unavailable_notification_screen.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:coconut_vault/screens/precheck/device_password_checker_screen.dart';
import 'package:coconut_vault/screens/precheck/jail_break_detection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/coordinator_bsms_paste_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/coordinator_bsms_config_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_creation_options_screen.dart';

import 'package:coconut_vault/screens/wallet_info/multisig_menu/backup_wallet_data_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/extended_pub_key_screen.dart';
import 'package:coconut_vault/screens/wallet_info/export_options_screen.dart';
import 'package:coconut_vault/services/security_prechecker.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_dice_roll_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/settings/app_info_screen.dart';
import 'package:coconut_vault/screens/settings/developer_screen.dart';
import 'package:coconut_vault/screens/settings/mnemonic_word_list_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/wallet_info/address_list_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/wallet_info/multisig_menu/coordinator_bsms_qr_screen.dart';
import 'package:coconut_vault/screens/wallet_info/multisig_wallet_info_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/signer_bsms_qr_screen.dart';
import 'package:coconut_vault/screens/wallet_info/sync_to_wallet_screen.dart';

import 'package:coconut_vault/screens/wallet_info/single_sig_wallet_info_screen.dart';

import 'package:coconut_vault/widgets/overlays/signing_mode_edge_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/splash_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async';

/// 서명 전용 모드로 고정된 라이트 버전 앱.
///
/// 안전 저장 모드 전용 진입 플로우(PIN 확인, 모드 선택, 보안 영역 무결성 검사)와
/// 라우트를 제외한 버전입니다. [AppEntryFlow]는 app.dart의 것을 재사용하되
/// pinCheck/vaultModeSelection 관련 경로는 생성하지 않습니다.
class CoconutVaultLiteApp extends StatefulWidget {
  const CoconutVaultLiteApp({super.key});

  @override
  State<CoconutVaultLiteApp> createState() => _CoconutVaultLiteAppState();
}

class _CoconutVaultLiteAppState extends State<CoconutVaultLiteApp> with SingleTickerProviderStateMixin {
  AppEntryFlow _appEntryFlow = AppEntryFlow.splash;
  bool _shouldShowPrivacyScreen = false;
  late final authProvider = AuthProvider();
  late final preferenceProvider = PreferenceProvider();
  late final visibilityProvider = VisibilityProvider(isSigningOnlyMode: preferenceProvider.isSigningOnlyMode);
  late final lifecycleProvider = AppLifecycleStateProvider();
  WalletProvider? _walletProvider;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // 현재 라우트 추적
  late _LiteNavigatorObserver _navigatorObserver;
  final ValueNotifier<bool> _routeNotifierHasShow = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _navigatorObserver = _LiteNavigatorObserver(
      onRouteChanged: (routeName) {
        if (routeName == null || routeName == '/' || routeName == AppRoutes.vaultModeSelection) {
          _routeNotifierHasShow.value = false;
        } else {
          _routeNotifierHasShow.value = true;
        }
      },
    );
  }

  @override
  void dispose() {
    _walletProvider?.dispose();
    _routeNotifierHasShow.dispose();
    super.dispose();
  }

  void _updateEntryFlow(AppEntryFlow appEntryFlow) {
    _appEntryFlow = appEntryFlow;
    if (appEntryFlow == AppEntryFlow.vaultHome) {
      _shouldShowPrivacyScreen = false;

      lifecycleProvider.registerCallbacks(
        onAppGoBackground: _handleAppGoBackgroundOfMainRoute,
        onAppGoInactive: _handleAppGoInactiveOfMainRoute,
        onAppGoActive: _handleAppGoActiveOfMainRoute,
      );
    } else {
      lifecycleProvider.unregisterAllCallbacks();
    }

    setState(() {});
  }

  void _handleAppGoBackgroundOfMainRoute() {
    // 서명 전용 모드에서는 백그라운드 전환 시 지갑 데이터를 메모리에서 유지하므로 아무 작업도 하지 않음
  }

  void _handleAppGoInactiveOfMainRoute() {
    if (Platform.isAndroid) return; // 안드로이드는 화면보호기 Native에서 처리
    setState(() {
      _shouldShowPrivacyScreen = true;
    });
  }

  Future<void> _handleAppGoActiveOfMainRoute() async {
    // iOS: 무한 반복 방지를 위해 _shouldShowPrivacyScreen 체크 추가
    if (Platform.isIOS && _shouldShowPrivacyScreen == false && _appEntryFlow == AppEntryFlow.vaultHome) {
      return;
    }

    if (lifecycleProvider.shouldIgnoreLifecycleEvent) {
      return;
    }

    _updateEntryFlow(AppEntryFlow.securityPrecheck);
  }

  /// 라이트 버전 온보딩 완료: 모드 선택 없이 가이드 확인 처리 후 홈으로 이동
  Future<void> _completeLiteOnboarding() async {
    await visibilityProvider.setHasSeenGuide();
    if (!mounted) return;
    _updateEntryFlow(AppEntryFlow.vaultHome);
  }

  WalletProvider _ensureWalletProvider(
    VisibilityProvider visibilityProvider,
    PreferenceProvider preferenceProvider,
    AppLifecycleStateProvider lifecycleProvider,
  ) {
    _walletProvider ??= WalletProvider(visibilityProvider, preferenceProvider, lifecycleProvider);
    return _walletProvider!;
  }

  Widget _getHomeScreenRoute(AppEntryFlow appEntry, BuildContext context) {
    switch (appEntry) {
      case AppEntryFlow.splash:
        return SplashScreen(onComplete: _updateEntryFlow);

      case AppEntryFlow.securityPrecheck:
        return FutureBuilder<SecurityCheckResult>(
          future: Future.delayed(const Duration(milliseconds: 500), () => SecurityPrechecker().performSecurityCheck()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSecurityCheckInProgress();
            }

            if (snapshot.hasData) {
              final securityResult = snapshot.data!.status;

              switch (securityResult) {
                case SecurityCheckStatus.jailbreakDetected:
                  return JailBreakDetectionScreen(
                    hasSeenGuide: visibilityProvider.hasSeenGuide,
                    onSkip: () async {
                      // 첫 실행 화면으로 이동하여 다시 보안 검사 이어서 실행
                      _updateEntryFlow(AppEntryFlow.splash);
                    },
                    onReset: () {
                      _updateEntryFlow(AppEntryFlow.vaultResetCompleted);
                    },
                  );
                case SecurityCheckStatus.devicePasswordRequired:
                  return DevicePasswordCheckerScreen(
                    state: DevicePasswordCheckerScreenState.devicePasswordRequired,
                    onComplete: () {
                      // 스플래시 플로우로 이동 후 다시 보안 검사 이어서 실행
                      _updateEntryFlow(AppEntryFlow.splash);
                    },
                  );
                case SecurityCheckStatus.secure:
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // 한번도 튜토리얼을 보지 않은 경우
                    if (!visibilityProvider.hasSeenGuide) {
                      _updateEntryFlow(AppEntryFlow.firstLaunch);
                      return;
                    }

                    _updateEntryFlow(AppEntryFlow.vaultHome);
                  });
                case SecurityCheckStatus.error:
              }
            }
            return _buildSecurityCheckInProgress();
          },
        );
      case AppEntryFlow.firstLaunch:
        if (NetworkType.currentNetworkType.isTestnet) {
          return const TutorialScreen(screenStatus: TutorialScreenStatus.entrance);
        } else {
          return WelcomeScreen(onComplete: _completeLiteOnboarding);
        }
      case AppEntryFlow.vaultHome:
        return VaultHomeScreen(
          onSigningModeReset: () {
            _updateEntryFlow(AppEntryFlow.vaultResetCompleted);
          },
          onSecureZoneUnaccessible: () {
            _updateEntryFlow(AppEntryFlow.cannotAccessToSecureZone);
          },
        );
      case AppEntryFlow.cannotAccessToSecureZone:
        return DevicePasswordCheckerScreen(
          state: DevicePasswordCheckerScreenState.devicePasswordChanged,
          onComplete: () async {
            _updateEntryFlow(AppEntryFlow.vaultHome);
          },
        );
      case AppEntryFlow.pinCheck:
        // 라이트 빌드에서는 PIN 잠금이 없어 도달하지 않음
        return const SizedBox.shrink();
      case AppEntryFlow.vaultResetCompleted:
        lifecycleProvider.disposeWhenVaultReset();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          runApp(
            const CupertinoApp(
              debugShowCheckedModeBanner: false,
              home: AppUnavailableNotificationScreen(isVaultReset: true),
            ),
          );
        });
        return const SizedBox.shrink(); // 빈 위젯 반환
    }
  }

  Widget _buildSecurityCheckInProgress() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(t.verify_security, style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.gray800)),
          CoconutLayout.spacing_300h,
          const CircularProgressIndicator(color: CoconutColors.gray800),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CoconutTheme.setTheme(Brightness.light);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => preferenceProvider),
        ChangeNotifierProvider(create: (_) => visibilityProvider),
        ChangeNotifierProvider(create: (_) => lifecycleProvider),
        ChangeNotifierProxyProvider2<VisibilityProvider, PreferenceProvider, ConnectivityProvider>(
          create: (_) => ConnectivityProvider(hasSeenGuide: visibilityProvider.hasSeenGuide),
          update: (_, visibilityProvider, preferenceProvider, connectivityProvider) {
            if (visibilityProvider.hasSeenGuide) {
              connectivityProvider!.setHasSeenGuideTrue();
            }

            return connectivityProvider!;
          },
        ),
        if (_appEntryFlow == AppEntryFlow.vaultHome) ...[
          Provider<WalletCreationProvider>(create: (_) => WalletCreationProvider()),
          Provider<TaprootWalletCreationProvider>(create: (_) => TaprootWalletCreationProvider()),
          Provider<SignProvider>(create: (_) => SignProvider()),
          ChangeNotifierProvider.value(
            value: _ensureWalletProvider(visibilityProvider, preferenceProvider, lifecycleProvider),
          ),
        ],
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child:
            _appEntryFlow == AppEntryFlow.vaultHome
                ? Stack(
                  children: [
                    CupertinoApp(
                      navigatorKey: _navigatorKey,
                      navigatorObservers: [_navigatorObserver],
                      debugShowCheckedModeBanner: false,
                      localizationsDelegates: const [
                        DefaultMaterialLocalizations.delegate,
                        DefaultWidgetsLocalizations.delegate,
                        DefaultCupertinoLocalizations.delegate,
                      ],
                      theme: cupertinoThemeData,
                      color: CoconutColors.white,
                      home: _getHomeScreenRoute(_appEntryFlow, context),
                      builder: (context, child) {
                        return Stack(
                          children: [
                            child ?? const SizedBox.shrink(),
                            Selector<WalletProvider, bool>(
                              selector: (context, walletProvider) => walletProvider.vaultList.isNotEmpty,
                              builder: (context, vaultListIsNotEmpty, child) {
                                return vaultListIsNotEmpty
                                    ? SigningModeEdgePanel(
                                      navigatorKey: _navigatorKey,
                                      routeVisibilityListenable: _routeNotifierHasShow,
                                      onResetCompleted: () => _updateEntryFlow(AppEntryFlow.vaultResetCompleted),
                                    )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ],
                        );
                      },
                      // 라이트 버전 라우트 테이블: vaultModeSelection 등 안전 저장 모드 전용 경로 제외
                      routes: buildLiteRoutes(onWelcomeComplete: _completeLiteOnboarding),
                    ),
                    if (_shouldShowPrivacyScreen)
                      Container(
                        color: CoconutColors.white,
                        child: Center(
                          child: Image.asset(
                            'assets/png/splash_logo_${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.png',
                            width: 60,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                  ],
                )
                : CupertinoApp(
                  key: ValueKey<AppEntryFlow>(_appEntryFlow),
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: const [
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                    DefaultCupertinoLocalizations.delegate,
                  ],
                  theme: cupertinoThemeData,
                  color: CoconutColors.white,
                  home: _getHomeScreenRoute(_appEntryFlow, context),
                  routes: {AppRoutes.welcome: (context) => WelcomeScreen(onComplete: _completeLiteOnboarding)},
                ),
      ),
    );
  }
}

/// 라이트 버전 라우트 테이블. `test/app_lite_routes_test.dart`에서 허용 라우트 목록과 일치하는지 검증합니다.
Map<String, WidgetBuilder> buildLiteRoutes({required VoidCallback onWelcomeComplete}) {
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
    AppRoutes.singleSigSetupInfo:
        (context) => buildScreenWithArguments(
          context,
          (args) => SingleSigWalletInfoScreen(
            id: args['id'],
            entryPoint: args['entryPoint'],
            shouldShowPassphraseVerifyMenu: false,
          ),
        ),
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

T buildScreenWithArguments<T>(
  BuildContext context,
  T Function(Map<String, dynamic>) builder, {
  Map<String, dynamic>? defaultArgs,
}) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? defaultArgs ?? {};
  return builder(args);
}

/// 라우트 변경을 감지하는 NavigatorObserver
class _LiteNavigatorObserver extends NavigatorObserver {
  final Function(String?) onRouteChanged;

  _LiteNavigatorObserver({required this.onRouteChanged});

  void notifyRouteChange(Route<dynamic>? route) {
    if (route != null) {
      final routeName = route.settings.name;
      onRouteChanged(routeName);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    notifyRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    notifyRouteChange(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    notifyRouteChange(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    notifyRouteChange(previousRoute);
  }
}
