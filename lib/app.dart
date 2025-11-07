import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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

  // 엣지 패널 관련 변수
  double _signingModeEdgePanelWidth = 20.0;
  double? _signingModeEdgePanelVerticalPos;
  double? _signingModeEdgePanelHorizontalPos;
  bool _isDraggingManually = false;
  bool _isPanningEdgePanel = false; // 패널 확장/축소 중인지 여부
  bool _isResetDialogOpen = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _longPressTimer;
  final GlobalKey _indicatorKey = GlobalKey();
  late AnimationController _edgePanelAnimationController;
  late Animation<double> _edgePanelAnimation;

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
    _edgePanelAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _edgePanelAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _edgePanelAnimationController, curve: Curves.easeOut))..addListener(() {
      setState(() {
        _signingModeEdgePanelHorizontalPos = _edgePanelAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _walletProvider?.dispose();
    _longPressTimer?.cancel();
    _edgePanelAnimationController.dispose();
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

    // 안전 저장 모드일 때
    _walletProvider?.dispose();
    final walletCount = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    if (walletCount > 0) {
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
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (_signingModeEdgePanelWidth == 100.0) {
          // AnimatedContainer 영역인지 확인
          final RenderBox? box = _indicatorKey.currentContext?.findRenderObject() as RenderBox?;
          if (box != null) {
            final position = box.localToGlobal(Offset.zero);
            final size = box.size;
            final indicatorArea = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

            // 터치 위치가 indicator 영역 밖이면 축소
            if (!indicatorArea.contains(event.position) && mounted) {
              setState(() {
                _signingModeEdgePanelWidth = 20.0;
                _isResetDialogOpen = false;
              });
            }
          }
        }
      },
      child: MultiProvider(
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
                              Consumer<PreferenceProvider>(
                                builder: (context, prefProvider, child) {
                                  // 드래그 중이나 패널 확장/축소 중이 아닐 때만 위치 업데이트
                                  if (!_isDraggingManually && !_isPanningEdgePanel) {
                                    final savedPosX = prefProvider.signingModeEdgePanelPos.$1;
                                    final savedPosY = prefProvider.signingModeEdgePanelPos.$2;

                                    // provider 값이 null이면 항상 초기값으로 리셋
                                    if (savedPosX != null) {
                                      _signingModeEdgePanelHorizontalPos = savedPosX;
                                    } else {
                                      _signingModeEdgePanelHorizontalPos =
                                          _signingModeEdgePanelWidth == 20
                                              ? MediaQuery.sizeOf(context).width - _signingModeEdgePanelWidth - 20
                                              : MediaQuery.sizeOf(context).width - _signingModeEdgePanelWidth + 60;
                                    }

                                    if (savedPosY != null) {
                                      _signingModeEdgePanelVerticalPos = savedPosY;
                                    } else {
                                      _signingModeEdgePanelVerticalPos = kToolbarHeight + 50;
                                    }
                                  }
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: _routeNotifierHasShow,
                                    builder: (context, hasShow, child) {
                                      final isEdgePanelVisible =
                                          prefProvider.getVaultMode() == VaultMode.signingOnly &&
                                          _appEntryFlow == AppEntryFlow.vaultHome &&
                                          hasShow;

                                      return _floatingResetButton(context, isEdgePanelVisible);
                                    },
                                  );
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
                                    preferenceProvider.isSigningOnlyMode
                                        ? false
                                        : args['shouldShowPassphraseVerifyMenu'],
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
                                (args) => AddressListScreen(
                                  id: args['id'],
                                  isSpecificVault: args['isSpecificVault'] ?? false,
                                ),
                              ),
                          AppRoutes.signerBsmsScanner:
                              (context) => buildScreenWithArguments(
                                context,
                                (args) => MultisigBsmsScannerScreen(id: args['id'], screenType: args['screenType']),
                              ),
                          AppRoutes.psbtScanner:
                              (context) =>
                                  buildScreenWithArguments(context, (args) => PsbtScannerScreen(id: args['id'])),
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
      ),
    );
  }

  Widget _floatingResetButton(BuildContext context, bool isEdgePanelVisible) {
    final halfScreenWidth = MediaQuery.sizeOf(context).width / 2;

    return Positioned(
      top: _signingModeEdgePanelVerticalPos,
      left: _signingModeEdgePanelHorizontalPos! <= halfScreenWidth ? _signingModeEdgePanelHorizontalPos : null,
      right:
          _signingModeEdgePanelHorizontalPos! > halfScreenWidth
              ? _signingModeEdgePanelWidth == 20
                  ? MediaQuery.sizeOf(context).width -
                      _signingModeEdgePanelHorizontalPos! -
                      (_signingModeEdgePanelWidth + 20)
                  : MediaQuery.sizeOf(context).width - _signingModeEdgePanelHorizontalPos! - 40
              : null,
      child: Listener(
        onPointerDown: (details) {
          _longPressTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isDraggingManually = true;
              });
              HapticFeedback.mediumImpact();
            }
          });
        },
        onPointerUp: (details) {
          _longPressTimer?.cancel();
          if (_isDraggingManually) {
            setState(() {
              _signingModeEdgePanelHorizontalPos = details.position.dx;
            });
            movePanelToEdge(details);
          }
        },
        onPointerCancel: (details) {
          _longPressTimer?.cancel();
          if (_isDraggingManually) {
            movePanelToEdge(details);
          }
        },
        onPointerMove: (details) {
          if (_isDraggingManually) {
            // 엣지 패널 위치 변경 중
            setState(() {
              final screenHeight = MediaQuery.of(context).size.height;
              final topPadding = MediaQuery.of(context).padding.top;
              _signingModeEdgePanelVerticalPos = details.position.dy - (topPadding + kToolbarHeight);
              _signingModeEdgePanelVerticalPos = _signingModeEdgePanelVerticalPos!.clamp(
                topPadding + kToolbarHeight,
                screenHeight - 100.0,
              );
              _signingModeEdgePanelHorizontalPos = details.position.dx;
            });
          }
        },
        child: GestureDetector(
          // 수평 드래그는 GestureDetector로 처리 (패널 확장/축소)
          onPanStart: (details) {
            if (!_isDraggingManually) {
              setState(() {
                _isPanningEdgePanel = true;
              });
            }
          },
          onPanUpdate: (details) {
            if (!_isDraggingManually) {
              setState(() {
                _signingModeEdgePanelWidth -= details.delta.dx;
                _signingModeEdgePanelWidth = _signingModeEdgePanelWidth.clamp(20.0, 100.0);
              });
            }
          },
          onPanEnd: (details) {
            if (!_isDraggingManually) {
              setState(() {
                if (_signingModeEdgePanelHorizontalPos! > MediaQuery.sizeOf(context).width / 2) {
                  if (details.velocity.pixelsPerSecond.dx.abs() > 500) {
                    if (details.velocity.pixelsPerSecond.dx < 0) {
                      _signingModeEdgePanelWidth = 100.0;
                    } else {
                      _signingModeEdgePanelWidth = 20.0;
                    }
                  } else {
                    _signingModeEdgePanelWidth = _signingModeEdgePanelWidth > 70 ? 100.0 : 20.0;
                  }
                } else {
                  if (details.velocity.pixelsPerSecond.dx.abs() > 500) {
                    if (details.velocity.pixelsPerSecond.dx > 0) {
                      _signingModeEdgePanelWidth = 100.0;
                    } else {
                      _signingModeEdgePanelWidth = 20.0;
                    }
                  } else {
                    _signingModeEdgePanelWidth = _signingModeEdgePanelWidth > 70 ? 100.0 : 20.0;
                  }
                }
                _isPanningEdgePanel = false;
              });
            }
          },
          child: AnimatedContainer(
            key: _indicatorKey,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width:
                isEdgePanelVisible
                    ? _isDraggingManually
                        ? 50
                        : _signingModeEdgePanelWidth + 20 + (_isDraggingManually ? 4 : 0)
                    : 0,
            height: _isDraggingManually ? 50 : 100,
            decoration: BoxDecoration(
              color:
                  _signingModeEdgePanelWidth != 100.0
                      ? CoconutColors.black.withValues(alpha: 0.8)
                      : CoconutColors.black,
              borderRadius: _getEdgePanelBorderRadius(),
              border: _isDraggingManually ? Border.all(color: CoconutColors.white, width: 2) : null,
            ),
            child:
                _isDraggingManually
                    ? SizedBox(
                      width: 40,
                      height: double.infinity,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SvgPicture.asset(
                          'assets/svg/eraser.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(CoconutColors.white, BlendMode.srcIn),
                        ),
                      ),
                    )
                    : GestureDetector(
                      onTap: () {
                        if (_signingModeEdgePanelWidth != 100.0) {
                          setState(() {
                            _signingModeEdgePanelWidth = 100.0;
                          });
                        } else {
                          // 패널이 확장된 상태에서 탭하면 exit dialog 표시
                          final navContext = _navigatorKey.currentContext;
                          if (navContext != null) {
                            if (_isResetDialogOpen) return;
                            _isResetDialogOpen = true;
                            showDialog(
                              context: navContext,
                              builder: (BuildContext dialogContext) {
                                return CoconutPopup(
                                  insetPadding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(navContext).size.width * 0.15,
                                  ),
                                  title: t.delete_vault,
                                  description: t.delete_vault_description,
                                  backgroundColor: CoconutColors.white,
                                  leftButtonText: t.cancel,
                                  rightButtonText: t.confirm,
                                  rightButtonColor: CoconutColors.black,
                                  onTapLeft: () {
                                    Navigator.pop(dialogContext);
                                    _isResetDialogOpen = false;
                                  },
                                  onTapRight: () async {
                                    _isResetDialogOpen = false;
                                    await context.read<WalletProvider>().deleteAllWallets();
                                    await preferenceProvider.resetVaultOrderAndFavorites();

                                    _updateEntryFlow(AppEntryFlow.vaultResetCompleted);
                                  },
                                );
                              },
                            );
                          }
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        children: [
                          // Exit 아이콘 - 위치와 크기 애니메이션
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            left:
                                _signingModeEdgePanelHorizontalPos! > MediaQuery.sizeOf(context).width / 2
                                    ? _signingModeEdgePanelWidth == 100.0
                                        ? (_signingModeEdgePanelWidth + 20) / 2 - 12
                                        : 10
                                    : null,
                            right:
                                _signingModeEdgePanelHorizontalPos! <= MediaQuery.sizeOf(context).width / 2
                                    ? _signingModeEdgePanelWidth == 100.0
                                        ? (_signingModeEdgePanelWidth + 20) / 2 - 12
                                        : 10
                                    : null,
                            top: _signingModeEdgePanelWidth == 100.0 ? 20 : 50 - 12,
                            child: SvgPicture.asset(
                              'assets/svg/eraser.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(CoconutColors.white, BlendMode.srcIn),
                            ),
                          ),
                          // Exit 텍스트 - fade in/out
                          if (_signingModeEdgePanelWidth == 100.0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 30,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _signingModeEdgePanelWidth == 100.0 ? 1.0 : 0.0,
                                child: MediaQuery(
                                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        t.delete_vault,
                                        style: CoconutTypography.body2_14_Bold.copyWith(color: CoconutColors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  void movePanelToEdge(PointerEvent details) {
    _signingModeEdgePanelWidth = 20.0;
    final targetPosition =
        details.position.dx <= MediaQuery.sizeOf(context).width / 2
            ? 0.0
            : MediaQuery.sizeOf(context).width - _signingModeEdgePanelWidth - 20;

    // 애니메이션으로 부드럽게 이동
    _edgePanelAnimation = Tween<double>(
      begin: _signingModeEdgePanelHorizontalPos,
      end: targetPosition,
    ).animate(CurvedAnimation(parent: _edgePanelAnimationController, curve: Curves.easeOut));

    _edgePanelAnimationController.reset();
    _edgePanelAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isDraggingManually = false;
        });
        preferenceProvider.setSigningModeEdgePanelPos(
          _signingModeEdgePanelHorizontalPos!,
          _signingModeEdgePanelVerticalPos!,
        );
      }
    });
  }

  BorderRadius _getEdgePanelBorderRadius() {
    final halfScreenWidth = MediaQuery.sizeOf(context).width / 2;
    return _isDraggingManually
        ? const BorderRadius.all(Radius.circular(10))
        : _signingModeEdgePanelHorizontalPos! <= halfScreenWidth
        ? const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
        : const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10));
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
