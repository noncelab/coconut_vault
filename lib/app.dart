import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
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
import 'package:coconut_vault/screens/common/app_unavailable_notification_screen.dart';
import 'package:coconut_vault/screens/common/vault_mode_selection_screen.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:coconut_vault/screens/precheck/device_password_checker_screen.dart';
import 'package:coconut_vault/screens/precheck/jail_break_detection_screen.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_availability_checker.dart';
import 'package:coconut_vault/services/security_prechecker.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_dice_roll_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/settings/app_info_screen.dart';
import 'package:coconut_vault/screens/settings/mnemonic_word_list_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
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
import 'package:coconut_vault/widgets/overlays/signing_mode_edge_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'utils/logger.dart';

enum AppEntryFlow {
  splash,
  firstLaunch,
  securityPrecheck, // 보안 검사 실행
  pinCheck,
  vaultHome,
  vaultResetCompleted, // 지갑 초기화 완료 상태
  cannotAccessToSecureZone, // 보안 영역 접근 불가 상태
}

const cupertinoThemeData = CupertinoThemeData(
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
);

class CoconutVaultApp extends StatefulWidget {
  const CoconutVaultApp({super.key});

  @override
  State<CoconutVaultApp> createState() => _CoconutVaultAppState();
}

class _CoconutVaultAppState extends State<CoconutVaultApp> with SingleTickerProviderStateMixin {
  AppEntryFlow _appEntryFlow = AppEntryFlow.splash;
  bool _shouldShowPrivacyScreen = false;
  late final authProvider = AuthProvider();
  late final preferenceProvider = PreferenceProvider();
  late final visibilityProvider = VisibilityProvider(isSigningOnlyMode: preferenceProvider.isSigningOnlyMode);
  late final lifecycleProvider = AppLifecycleStateProvider();
  WalletProvider? _walletProvider; // 서명전용 모드일 때를 위해서 변수 할당, ChangeNotifier.value 사용하므로 dispose를 직접 관리

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // 현재 라우트 추적
  late _CustomNavigatorObserver _navigatorObserver;
  final ValueNotifier<bool> _routeNotifierHasShow = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _navigatorObserver = _CustomNavigatorObserver(
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
    if (preferenceProvider.isSigningOnlyMode) return;

    if (lifecycleProvider.shouldIgnoreLifecycleEvent) {
      return;
    }

    // 안전 저장 모드일 때
    _walletProvider?.dispose();
    final walletCount = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    if (walletCount > 0) {
      Logger.log('--> _handleAppGoBackgroundOfMainRoute: walletCount > 0 / pinCheck화면으로 이동');
      _updateEntryFlow(AppEntryFlow.pinCheck);
    }
  }

  void _handleAppGoInactiveOfMainRoute() {
    if (Platform.isAndroid) return; // 안드로이드는 화면보호기 Native에서 처리
    setState(() {
      _shouldShowPrivacyScreen = true;
    });
  }

  Future<void> _handleAppGoActiveOfMainRoute() async {
    // 플랫폼별로 다른 로직 적용
    // iOS: 무한 반복 방지를 위해 _shouldShowPrivacyScreen 체크 추가
    // Android: 기기 비밀번호 해제 감지를 위해 항상 실행
    if (Platform.isIOS && _shouldShowPrivacyScreen == false && _appEntryFlow == AppEntryFlow.vaultHome) {
      // iOS에서 이미 _appEntryFlow가 vaultHome로 이동한 경우 무한 반복 방지
      return;
    }

    if (lifecycleProvider.shouldIgnoreLifecycleEvent) {
      return;
    }

    _updateEntryFlow(AppEntryFlow.securityPrecheck);

    // 생체인증 상태 업데이트: 생체인증 ON 상태에서 백그라운드 나가서 권한을 해제한 경우에 상태값을 변경하기 위해
    if (!preferenceProvider.isSigningOnlyMode) {
      await authProvider.updateDeviceBiometricAvailability();
    }

    if (Platform.isIOS) {
      setState(() {
        _shouldShowPrivacyScreen = false;
      });
    }
  }

  WalletProvider _ensureWalletProvider(
    VisibilityProvider visibilityProvider,
    PreferenceProvider preferenceProvider,
    AppLifecycleStateProvider lifecycleProvider,
  ) {
    if (preferenceProvider.isSigningOnlyMode) {
      // 서명 전용 모드: 재사용
      _walletProvider ??= WalletProvider(visibilityProvider, preferenceProvider, lifecycleProvider);
    } else {
      // 안전 저장 모드: 매번 새로 생성
      _walletProvider = WalletProvider(visibilityProvider, preferenceProvider, lifecycleProvider);
    }

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
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    Logger.log('--> case SecurityCheckStatus.secure:');
                    // 한번도 튜토리얼을 보지 않은 경우
                    if (!visibilityProvider.hasSeenGuide) {
                      _updateEntryFlow(AppEntryFlow.firstLaunch);
                      return;
                    }

                    // 서명 전용 모드인 경우
                    if (preferenceProvider.isSigningOnlyMode) {
                      _updateEntryFlow(AppEntryFlow.vaultHome);
                      return;
                    }

                    // 영구 잠금 상태 - 이미 데이터는 초기화되었지만 PinCheck화면에서 t.errors.restart_vault 버튼을 누르지 않고 앱을 종료한 경우
                    if (authProvider.isPermanentlyLocked) {
                      _updateEntryFlow(AppEntryFlow.pinCheck);
                      return;
                    }

                    // 저장 모드 && PinSet
                    if (Platform.isIOS && authProvider.isPinSet) {
                      // 기기 패스코드 삭제 여부 확인
                      final isKeychainValid = await SecureZoneManager().verifyIosKeychainValidity();
                      if (!isKeychainValid) {
                        _updateEntryFlow(AppEntryFlow.cannotAccessToSecureZone);
                        return;
                      }
                    }

                    final walletCount = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
                    if (walletCount > 0) {
                      _updateEntryFlow(AppEntryFlow.pinCheck);
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
          return WelcomeScreen(
            onComplete: () {
              _updateEntryFlow(AppEntryFlow.vaultHome);
            },
          );
        }
      case AppEntryFlow.pinCheck:
        if (!authProvider.isPermanentlyLocked) {
          authProvider.updateDeviceBiometricAvailability();
          lifecycleProvider.registerCallbacks(onAppGoActive: () => _updateEntryFlow(AppEntryFlow.securityPrecheck));
        }
        return PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.appLaunch,
          onSuccess: () => _updateEntryFlow(AppEntryFlow.vaultHome),
          onReset: () => _updateEntryFlow(AppEntryFlow.securityPrecheck),
          onPermanentlyLocked: () {
            lifecycleProvider.unregisterAllCallbacks();
          },
        );
      case AppEntryFlow.vaultHome:
        return VaultHomeScreen(
          onAllWalletDeleted: () {
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
            await _handleDevicePasswordChangedOnResume();
            _updateEntryFlow(AppEntryFlow.vaultHome);
          },
        );
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
                      routes: {
                        AppRoutes.vaultList: (context) => const VaultListScreen(),
                        AppRoutes.vaultTypeSelection: (context) => const VaultTypeSelectionScreen(),
                        AppRoutes.multisigQuorumSelection: (context) => const MultisigQuorumSelectionScreen(),
                        AppRoutes.signerAssignment: (context) => const SignerAssignmentScreen(),
                        AppRoutes.vaultCreationOptions: (context) => const VaultCreationOptions(),
                        AppRoutes.mnemonicVerify: (context) => const MnemonicVerifyScreen(),
                        AppRoutes.mnemonicImport: (context) => const MnemonicImportScreen(),
                        AppRoutes.seedQrImport: (context) => const SeedQrImportScreen(),
                        AppRoutes.mnemonicConfirmation:
                            (context) => buildScreenWithArguments(
                              context,
                              (args) => MnemonicConfirmationScreen(calledFrom: args['calledFrom']),
                            ),
                        AppRoutes.mnemonicView:
                            (context) =>
                                buildScreenWithArguments(context, (args) => MnemonicViewScreen(walletId: args['id'])),
                        AppRoutes.vaultNameSetup: (context) => const VaultNameAndIconSetupScreen(),
                        AppRoutes.singleSigSetupInfo: (context) {
                          return buildScreenWithArguments(
                            context,
                            (args) => SingleSigSetupInfoScreen(
                              id: args['id'],
                              entryPoint: args['entryPoint'],
                              // 서명 전용 모드일 때는 항상 false
                              shouldShowPassphraseVerifyMenu:
                                  preferenceProvider.isSigningOnlyMode ? false : args['shouldShowPassphraseVerifyMenu'],
                            ),
                          );
                        },
                        AppRoutes.multisigSetupInfo:
                            (context) => buildScreenWithArguments(
                              context,
                              (args) => MultisigSetupInfoScreen(id: args['id'], entryPoint: args['entryPoint']),
                            ),
                        AppRoutes.multisigBsmsView:
                            (context) =>
                                buildScreenWithArguments(context, (args) => MultisigBsmsScreen(id: args['id'])),
                        AppRoutes.mnemonicWordList: (context) => const MnemonicWordListScreen(),
                        AppRoutes.addressList:
                            (context) => buildScreenWithArguments(
                              context,
                              (args) =>
                                  AddressListScreen(id: args['id'], isSpecificVault: args['isSpecificVault'] ?? false),
                            ),
                        AppRoutes.signerBsmsScanner:
                            (context) => buildScreenWithArguments(
                              context,
                              (args) => MultisigBsmsScannerScreen(id: args['id'], screenType: args['screenType']),
                            ),
                        AppRoutes.psbtScanner:
                            (context) => buildScreenWithArguments(context, (args) => PsbtScannerScreen(id: args['id'])),
                        AppRoutes.psbtConfirmation: (context) => const PsbtConfirmationScreen(),
                        AppRoutes.signedTransaction: (context) => const SignedTransactionQrScreen(),
                        AppRoutes.syncToWallet:
                            (context) => buildScreenWithArguments(
                              context,
                              (args) => SyncToWalletScreen(id: args['id'], syncOption: args['syncOption']),
                            ),
                        AppRoutes.multisigSignerBsmsExport:
                            (context) => buildScreenWithArguments(
                              context,
                              (args) => MultisigSignerBsmsExportScreen(id: args['id']),
                            ),
                        AppRoutes.multisigSign: (context) => const MultisigSignScreen(),
                        AppRoutes.singleSigSign: (context) => const SingleSigSignScreen(),
                        AppRoutes.securitySelfCheck: (context) {
                          final VoidCallback? onNextPressed =
                              ModalRoute.of(context)?.settings.arguments as VoidCallback?;
                          return SecuritySelfCheckScreen(onNextPressed: onNextPressed);
                        },
                        AppRoutes.mnemonicAutoGen:
                            (context) => const MnemonicAutoGenScreen(entropyType: EntropyType.auto),
                        AppRoutes.mnemonicCoinflip:
                            (context) => const MnemonicCoinflipScreen(entropyType: EntropyType.manual),
                        AppRoutes.mnemonicDiceRoll:
                            (context) => const MnemonicDiceRollScreen(entropyType: EntropyType.manual),
                        AppRoutes.appInfo: (context) => const AppInfoScreen(),
                        AppRoutes.welcome: (context) {
                          onComplete() {
                            _updateEntryFlow(AppEntryFlow.vaultHome);
                          }

                          return WelcomeScreen(onComplete: onComplete);
                        },
                        AppRoutes.passphraseVerification:
                            (context) => buildScreenWithArguments(
                              context,
                              (args) => PassphraseVerificationScreen(id: args['id']),
                            ),
                        AppRoutes.vaultModeSelection: (context) => const VaultModeSelectionScreen(),
                      },
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
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: const [
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                    DefaultCupertinoLocalizations.delegate,
                  ],
                  theme: cupertinoThemeData,
                  color: CoconutColors.white,
                  home: _getHomeScreenRoute(_appEntryFlow, context),
                  routes: {
                    AppRoutes.welcome:
                        (context) => WelcomeScreen(onComplete: () => _updateEntryFlow(AppEntryFlow.vaultHome)),
                    AppRoutes.vaultModeSelection:
                        (context) => buildScreenWithArguments(
                          context,
                          (args) =>
                              VaultModeSelectionScreen(onComplete: () => _updateEntryFlow(AppEntryFlow.vaultHome)),
                        ),
                  },
                ),
      ),
    );
  }

  T buildScreenWithArguments<T>(
    BuildContext context,
    T Function(Map<String, dynamic>) builder, {
    Map<String, dynamic>? defaultArgs,
  }) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? defaultArgs ?? {};
    return builder(args);
  }

  /// onAppGoActive에서 기기 비밀번호 변경 시 볼트 초기화 처리
  Future<void> _handleDevicePasswordChangedOnResume() async {
    try {
      // 볼트 초기화 (앱 최초실행 여부, 볼트 모드는 유지)
      await SecureZoneManager().deleteStoredData(authProvider);
    } catch (e) {
      debugPrint('볼트 초기화 실패: $e');
      // 볼트 초기화 실패 시에도 계속 진행
    }
  }
}

/// 라우트 변경을 감지하는 NavigatorObserver
class _CustomNavigatorObserver extends NavigatorObserver {
  final Function(String?) onRouteChanged;

  _CustomNavigatorObserver({required this.onRouteChanged});

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
