import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/main_route_guard.dart';
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
import 'package:coconut_vault/screens/precheck/device_password_detection_screen.dart';
import 'package:coconut_vault/screens/precheck/jail_break_detection_screen.dart';
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/start_screen.dart';
import 'package:flutter/services.dart';
import 'package:coconut_vault/widgets/overlays/signing_mode_edge_panel.dart';
import 'package:provider/provider.dart';
import 'dart:async';

enum AppEntryFlow {
  securityCheck,
  jailbreakDetected, // 탈옥/루팅 감지 화면
  devicePasswordRequired, // 기기 비밀번호 설정 필요 화면
  devicePasswordChanged, // 기기 비밀번호 변경 감지 화면
  splash,
  tutorial,
  pinCheckAppLaunched,
  pinCheckAppResumed,
  vaultHome,
  vaultResetCompleted, // 볼트 초기화 완료 화면
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

class _CoconutVaultAppState extends State<CoconutVaultApp> {
  AppEntryFlow _appEntryFlow = AppEntryFlow.securityCheck;
  bool _isInactive = false;
  late final authProvider = AuthProvider();
  late final preferenceProvider = PreferenceProvider();
  late final visibilityProvider = VisibilityProvider(isSigningOnlyMode: preferenceProvider.isSigningOnlyMode);
  late final lifecycleProvider = AppLifecycleStateProvider();
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
    _routeNotifierHasShow.dispose();
    super.dispose();
  }

  void _updateEntryFlow(AppEntryFlow appEntryFlow) {
    setState(() {
      _appEntryFlow = appEntryFlow;
      if (appEntryFlow == AppEntryFlow.vaultHome) {
        _isInactive = false;
      }
    });
  }

  Widget _buildPinCheckScreen({
    required PinCheckContextEnum pinCheckContext,
    required AppEntryFlow nextFlow,
    VoidCallback? onReset,
  }) {
    return MainRouteGuard(
      onAppGoBackground: () {},
      onAppGoInactive: () {},
      onAppGoActive: () async {
        final securityResult = await SecurityPrechecker().performSecurityCheck();

        // 보안 검사 결과에 따른 처리
        switch (securityResult.status) {
          case SecurityCheckStatus.jailbreakDetected:
            // 탈옥/루팅 감지 시 플로우 변경
            _updateEntryFlow(AppEntryFlow.jailbreakDetected);
            return;
          case SecurityCheckStatus.devicePasswordRequired:
            // 기기 비밀번호 미설정 시 플로우 변경
            _updateEntryFlow(AppEntryFlow.devicePasswordRequired);
            return;
          case SecurityCheckStatus.devicePasswordChanged:
            if (Platform.isIOS) {
              _updateEntryFlow(AppEntryFlow.devicePasswordChanged);
            }
            break;
          case SecurityCheckStatus.secure:
            // 보안 검사 통과 시 계속 진행
            break;
          case SecurityCheckStatus.error:
            // 에러 발생 시 계속 진행 (에러 무시)
            break;
        }
      },
      child: PinCheckScreen(
        pinCheckContext: pinCheckContext,
        onSuccess: () => _updateEntryFlow(nextFlow),
        onReset: onReset ?? () async => _updateEntryFlow(AppEntryFlow.vaultHome),
      ),
    );
  }

  int resuemedCount = 0;

  Widget _getHomeScreenRoute(AppEntryFlow appEntry, BuildContext context) {
    switch (appEntry) {
      case AppEntryFlow.securityCheck:
        return _SecurityCheckWidget(onComplete: _updateEntryFlow);
      case AppEntryFlow.jailbreakDetected:
        return JailBreakDetectionScreen(
          hasSeenGuide: visibilityProvider.hasSeenGuide,
          onSkip: () async {
            SharedPrefsRepository sharedPrefs = SharedPrefsRepository();
            await sharedPrefs.setBool(SharedPrefsKeys.jailbreakDetectionIgnored, true);
            await sharedPrefs.setInt(
              SharedPrefsKeys.jailbreakDetectionIgnoredTime,
              DateTime.now().millisecondsSinceEpoch,
            );
            _updateEntryFlow(AppEntryFlow.splash);
          },
          onReset: () => _onChangeEntryFlow(),
        );
      case AppEntryFlow.devicePasswordRequired:
        return DevicePasswordDetectionScreen(
          state: DevicePasswordDetectionScreenState.devicePasswordRequired,
          onComplete: () {
            // 앱 최초실행 여부 확인
            final isInitialLaunch = _isInitialLaunch();
            if (isInitialLaunch) {
              // 앱 최초실행인 경우 splash로 이동
              _updateEntryFlow(AppEntryFlow.splash);
            } else {
              // 앱 최초실행이 아닌 경우 devicePasswordChanged 화면으로 이동
              _updateEntryFlow(AppEntryFlow.devicePasswordChanged);
            }
          },
        );
      case AppEntryFlow.devicePasswordChanged:
        return DevicePasswordDetectionScreen(
          state: DevicePasswordDetectionScreenState.devicePasswordChanged,
          onComplete: () async {
            // 볼트 초기화 수행
            await _handleDevicePasswordChangedOnResume();
            // 볼트 초기화 후 vaultHome으로 이동
            _updateEntryFlow(AppEntryFlow.vaultHome);
          },
        );
      case AppEntryFlow.splash:
        return StartScreen(onComplete: _updateEntryFlow);

      case AppEntryFlow.tutorial:
        if (NetworkType.currentNetworkType.isTestnet) {
          return const TutorialScreen(screenStatus: TutorialScreenStatus.entrance);
        } else {
          onComplete() {
            _updateEntryFlow(AppEntryFlow.vaultHome);
          }

          return WelcomeScreen(onComplete: onComplete);
        }

      case AppEntryFlow.pinCheckAppLaunched:
        return _buildPinCheckScreen(pinCheckContext: PinCheckContextEnum.appLaunch, nextFlow: AppEntryFlow.vaultHome);
      case AppEntryFlow.pinCheckAppResumed:
        resuemedCount++;
        return _buildPinCheckScreen(pinCheckContext: PinCheckContextEnum.appResumed, nextFlow: AppEntryFlow.vaultHome);
      case AppEntryFlow.vaultHome:
        {
          return VaultHomeScreen(
            onChangeEntryFlow: () {
              _onChangeEntryFlow();
            },
            onTeeUnaccessible: () {
              _updateEntryFlow(AppEntryFlow.devicePasswordChanged);
            },
          );
        }

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

  @override
  Widget build(BuildContext context) {
    CoconutTheme.setTheme(Brightness.light);

    final Widget mainContent;
    if (_appEntryFlow == AppEntryFlow.vaultHome) {
      mainContent = MainRouteGuard(
        onAppGoBackground: () {
          if (!preferenceProvider.isSigningOnlyMode &&
              (authProvider.isPinSet || (SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0) > 0)) {
            _updateEntryFlow(AppEntryFlow.pinCheckAppResumed);
          }
        },
        onAppGoInactive: () {
          if (Platform.isAndroid) return; // 안드로이드는 Native에서 처리
          setState(() {
            _isInactive = true;
          });
        },
        onAppGoActive: () {
          // 생체인증이 진행 중인 경우 무시
          if (authProvider.isBiometricInProgress) {
            return;
          }
          _handleAppGoActive(preferenceProvider, authProvider);
        },
        child: Stack(
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
                    if (context.read<WalletProvider>().vaultList.isNotEmpty)
                      SigningModeEdgePanel(
                        navigatorKey: _navigatorKey,
                        routeVisibilityListenable: _routeNotifierHasShow,
                        isVaultHome: true,
                        onResetCompleted: _onChangeEntryFlow,
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
                    (context) => buildScreenWithArguments(context, (args) => MnemonicViewScreen(walletId: args['id'])),
                AppRoutes.vaultNameSetup: (context) => const VaultNameAndIconSetupScreen(),
                AppRoutes.singleSigSetupInfo: (context) {
                  return buildScreenWithArguments(
                    context,
                    (args) => SingleSigSetupInfoScreen(
                      id: args['id'],
                      entryPoint: args['entryPoint'],
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
                    (context) => buildScreenWithArguments(context, (args) => MultisigBsmsScreen(id: args['id'])),
                AppRoutes.mnemonicWordList: (context) => const MnemonicWordListScreen(),
                AppRoutes.addressList:
                    (context) => buildScreenWithArguments(
                      context,
                      (args) => AddressListScreen(id: args['id'], isSpecificVault: args['isSpecificVault'] ?? false),
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
                    (context) =>
                        buildScreenWithArguments(context, (args) => MultisigSignerBsmsExportScreen(id: args['id'])),
                AppRoutes.multisigSign: (context) => const MultisigSignScreen(),
                AppRoutes.singleSigSign: (context) => const SingleSigSignScreen(),
                AppRoutes.securitySelfCheck: (context) {
                  final VoidCallback? onNextPressed = ModalRoute.of(context)?.settings.arguments as VoidCallback?;
                  return SecuritySelfCheckScreen(onNextPressed: onNextPressed);
                },
                AppRoutes.mnemonicAutoGen: (context) => const MnemonicAutoGenScreen(entropyType: EntropyType.auto),
                AppRoutes.mnemonicCoinflip: (context) => const MnemonicCoinflipScreen(entropyType: EntropyType.manual),
                AppRoutes.mnemonicDiceRoll: (context) => const MnemonicDiceRollScreen(entropyType: EntropyType.manual),
                AppRoutes.appInfo: (context) => const AppInfoScreen(),
                AppRoutes.welcome: (context) {
                  void onComplete() {
                    _updateEntryFlow(AppEntryFlow.vaultHome);
                  }

                  return WelcomeScreen(onComplete: onComplete);
                },
                AppRoutes.passphraseVerification:
                    (context) =>
                        buildScreenWithArguments(context, (args) => PassphraseVerificationScreen(id: args['id'])),
                AppRoutes.vaultModeSelection: (context) => const VaultModeSelectionScreen(),
              },
            ),
            if (_isInactive)
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
        ),
      );
    } else {
      mainContent = CupertinoApp(
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
          // AppRoutes.devicePasswordDetection:
          //     (context) => DevicePasswordDetectionScreen(
          //       state: DevicePasswordDetectionScreenState.devicePasswordRequired,
          //       onComplete: () => _updateEntryFlow,
          //     ),
          // AppRoutes.jailBreakDetection:
          //     (context) => JailBreakDetectionScreen(onSkip: () => _updateEntryFlow(AppEntryFlow.vaultHome)),
          AppRoutes.welcome: (context) => WelcomeScreen(onComplete: () => _updateEntryFlow(AppEntryFlow.vaultHome)),
          AppRoutes.vaultModeSelection:
              (context) => buildScreenWithArguments(
                context,
                (args) => VaultModeSelectionScreen(onComplete: () => _updateEntryFlow(AppEntryFlow.vaultHome)),
              ),
        },
      );
    }

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
          ChangeNotifierProvider(
            create: (_) => WalletProvider(visibilityProvider, preferenceProvider, lifecycleProvider),
          ),
        ] else if (_appEntryFlow == AppEntryFlow.jailbreakDetected) ...[
          ChangeNotifierProvider(
            create: (_) => WalletProvider(visibilityProvider, preferenceProvider, lifecycleProvider),
          ),
        ],
      ],
      child: Directionality(textDirection: TextDirection.ltr, child: mainContent),
    );
  }

  void _onChangeEntryFlow() async {
    _updateEntryFlow(AppEntryFlow.vaultResetCompleted);
  }

  T buildScreenWithArguments<T>(
    BuildContext context,
    T Function(Map<String, dynamic>) builder, {
    Map<String, dynamic>? defaultArgs,
  }) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? defaultArgs ?? {};
    return builder(args);
  }

  /// onAppGoActive에서 실행되는 로직
  Future<void> _handleAppGoActive(PreferenceProvider preferenceProvider, AuthProvider authProvider) async {
    bool isPinSet = authProvider.isPinSet;
    int vaultListLength = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;

    // 플랫폼별로 다른 로직 적용
    // iOS: 무한 반복 방지를 위해 inactive 체크 추가
    // Android: 기기 비밀번호 해제 감지를 위해 항상 실행
    if (Platform.isIOS && _isInactive == false && _appEntryFlow == AppEntryFlow.vaultHome) {
      // iOS에서 이미 _appEntryFlow가 vaultHome로 이동한 경우 무한 반복 방지
      return;
    }

    try {
      // 첫 번째/두 번째 플로우: 보안 검사 수행
      final securityResult = await SecurityPrechecker().performSecurityCheck();

      // 보안 검사 결과에 따른 처리
      switch (securityResult.status) {
        case SecurityCheckStatus.jailbreakDetected:
          // 탈옥/루팅 감지 시 flow 변경
          _updateEntryFlow(AppEntryFlow.jailbreakDetected);
          return;
        case SecurityCheckStatus.devicePasswordRequired:
          // 기기 비밀번호 미설정 시 flow 변경
          _updateEntryFlow(AppEntryFlow.devicePasswordRequired);
          return;
        case SecurityCheckStatus.devicePasswordChanged:
          // 앱 최초실행 여부 확인
          final isInitialLaunch = _isInitialLaunch();
          if (isInitialLaunch) {
            // 앱 최초실행인 경우 splash로 이동
            _updateEntryFlow(AppEntryFlow.splash);
          } else {
            // 앱 최초실행이 아닌 경우 devicePasswordChanged 화면으로 이동
            _updateEntryFlow(AppEntryFlow.devicePasswordChanged);
          }
          return;
        case SecurityCheckStatus.secure:
          // 보안 검사 통과 시 계속 진행
          break;
        case SecurityCheckStatus.error:
          // 에러 발생 시 계속 진행 (에러 무시)
          break;
      }

      // 생체인증 상태 업데이트
      await authProvider.updateDeviceBiometricAvailability();

      if (preferenceProvider.isSigningOnlyMode || (!isPinSet || vaultListLength == 0)) {
        // 서명 전용 모드이거나 지갑이 없으면 vaultHome으로 이동
        _updateEntryFlow(AppEntryFlow.vaultHome);
      } else {
        _updateEntryFlow(AppEntryFlow.pinCheckAppResumed);
      }
    } catch (e) {
      // 예외 발생 시
      if (isPinSet || vaultListLength > 0) {
        _updateEntryFlow(AppEntryFlow.pinCheckAppResumed);
      } else {
        _updateEntryFlow(AppEntryFlow.vaultHome);
      }
    }

    // Android가 아닌 경우 inactive 상태 해제
    if (Platform.isAndroid) return;
    setState(() {
      _isInactive = false;
    });
  }

  /// onAppGoActive에서 기기 비밀번호 변경 시 볼트 초기화 처리
  Future<void> _handleDevicePasswordChangedOnResume() async {
    try {
      // 볼트 초기화 (앱 최초실행 여부, 볼트 모드는 유지)
      await SecurityPrechecker().deleteStoredData(authProvider);
    } catch (e) {
      debugPrint('볼트 초기화 실패: $e');
      // 볼트 초기화 실패 시에도 계속 진행
    }
  }

  /// 앱 최초실행 여부 확인
  bool _isInitialLaunch() {
    try {
      // 지갑이 존재하지 않거나 PIN이 설정되지 않은 경우 최초실행으로 간주
      final vaultListLength = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
      final hasSeenGuide = SharedPrefsRepository().getBool(SharedPrefsKeys.hasShownStartGuide) ?? false;
      final isPinEnabled = SharedPrefsRepository().getBool(SharedPrefsKeys.isPinEnabled) ?? false;
      // 지갑이 없거나 가이드를 본 적이 없으면 최초실행
      return (!isPinEnabled && vaultListLength == 0) || !hasSeenGuide;
    } catch (e) {
      debugPrint('앱 최초실행 여부 확인 실패: $e');
      // 에러 발생 시 최초실행으로 간주
      return true;
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

class _SecurityCheckWidget extends StatefulWidget {
  final Function(AppEntryFlow) onComplete;

  const _SecurityCheckWidget({required this.onComplete});

  @override
  State<_SecurityCheckWidget> createState() => _SecurityCheckWidgetState();
}

class _SecurityCheckWidgetState extends State<_SecurityCheckWidget> {
  @override
  void initState() {
    super.initState();
    performSecurityCheck();
  }

  Future<void> performSecurityCheck() async {
    try {
      final securityResult = await SecurityPrechecker().performSecurityCheck();
      debugPrint('securityResult: ${securityResult.status}');
      switch (securityResult.status) {
        case SecurityCheckStatus.jailbreakDetected:
          // 탈옥/루팅 감지 시 탈옥 감지 화면으로 이동
          widget.onComplete(AppEntryFlow.jailbreakDetected);
          break;
        case SecurityCheckStatus.devicePasswordRequired:
          // 기기 비밀번호 미설정 시 비밀번호 설정 화면으로 이동
          widget.onComplete(AppEntryFlow.devicePasswordRequired);
          break;
        case SecurityCheckStatus.devicePasswordChanged:
          // 앱 최초실행 여부 확인
          final isInitialLaunch = isInitialLaunch0();
          if (isInitialLaunch) {
            // 앱 최초실행인 경우 splash로 이동
            widget.onComplete(AppEntryFlow.splash);
          } else {
            // 앱 최초실행이 아닌 경우 devicePasswordChanged 화면으로 이동
            widget.onComplete(AppEntryFlow.devicePasswordChanged);
          }
          break;
        case SecurityCheckStatus.secure:
          // 보안 검사 통과 시 스플래시로 이동
          widget.onComplete(AppEntryFlow.splash);
          break;
        case SecurityCheckStatus.error:
          // 에러 발생 시 스플래시로 이동 (에러 무시)
          widget.onComplete(AppEntryFlow.splash);
          break;
      }
    } catch (e) {
      // 예외 발생 시 스플래시로 이동
      widget.onComplete(AppEntryFlow.splash);
    }
  }

  /// 앱 최초실행 여부 확인
  bool isInitialLaunch0() {
    try {
      // 지갑이 존재하지 않거나 PIN이 설정되지 않은 경우 최초실행으로 간주
      final vaultListLength = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
      final hasSeenGuide = SharedPrefsRepository().getBool(SharedPrefsKeys.hasShownStartGuide) ?? false;
      final isPinEnabled = SharedPrefsRepository().getBool(SharedPrefsKeys.isPinEnabled) ?? false;
      // 지갑이 없거나 가이드를 본 적이 없으면 최초실행
      return (!isPinEnabled && vaultListLength == 0) || !hasSeenGuide;
    } catch (e) {
      debugPrint('앱 최초실행 여부 확인 실패: $e');
      // 에러 발생 시 최초실행으로 간주
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      Platform.isIOS
          ? const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark, // iOS → 검정 텍스트
          )
          : const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark, // Android → 검정 텍스트
            statusBarColor: Colors.transparent,
          ),
    );

    // 스플래시와 동일한 화면
    return Scaffold(
      backgroundColor: CoconutColors.white,
      body: Container(
        padding: Platform.isIOS ? null : const EdgeInsets.only(top: Sizes.size48),
        child: Center(
          child: Image.asset(
            'assets/png/splash_logo_${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.png',
            width: Sizes.size60,
          ),
        ),
      ),
    );
  }
}
