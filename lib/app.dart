import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
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
import 'package:coconut_vault/screens/common/vault_mode_selection_screen.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:coconut_vault/screens/app_update/app_update_preparation_screen.dart';
import 'package:coconut_vault/screens/precheck/device_password_check_screen.dart';
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
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/start_screen.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'dart:async';

enum AppEntryFlow {
  splash,
  tutorial,
  pinCheckAppLaunched,
  pinCheckAppResumed,
  vaultHome,
  pinCheckForRestoration, // 복원파일o, 업데이트o 일때 바로 이동하는 핀체크 화면
  foundBackupFile, // 복원파일o, 업데이트x 일때 이동하는 복원파일 발견 화면
  restoration, // 복원 진행 화면
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
  bool _isInactive = false;
  late final authProvider = AuthProvider();
  late final preferenceProvider = PreferenceProvider();
  late final visibilityProvider = VisibilityProvider(isSigningOnlyMode: preferenceProvider.isSigningOnlyMode);
  late final walletProvider = WalletProvider(visibilityProvider, preferenceProvider);

  // 엣지 패널 관련 변수
  double _signingModeEdgePanelWidth = 20.0;
  double? _signingModeEdgePanelVerticalPos;
  double? _signingModeEdgePanelHorizontalPos;
  bool _isDraggingManually = false;
  bool _isPanningEdgePanel = false; // 패널 확장/축소 중인지 여부
  bool _isExitDialogOpen = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _longPressTimer;
  final GlobalKey _indicatorKey = GlobalKey();
  ConnectivityProvider? _connectivityProvider;
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
        if (routeName == null || routeName == '/') {
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
    Logger.log("--> app.dart dispose");
    _longPressTimer?.cancel();
    _edgePanelAnimationController.dispose();
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
    return PinCheckScreen(
      pinCheckContext: pinCheckContext,
      onSuccess: () => _updateEntryFlow(nextFlow),
      onReset: onReset ?? () async => _updateEntryFlow(AppEntryFlow.vaultHome),
    );
  }

  Widget _getHomeScreenRoute(AppEntryFlow appEntry, BuildContext context) {
    switch (appEntry) {
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
        return CustomLoadingOverlay(
          child: _buildPinCheckScreen(pinCheckContext: PinCheckContextEnum.appLaunch, nextFlow: AppEntryFlow.vaultHome),
        );
      case AppEntryFlow.pinCheckAppResumed:
        return CustomLoadingOverlay(
          child: _buildPinCheckScreen(
            pinCheckContext: PinCheckContextEnum.appResumed,
            nextFlow: AppEntryFlow.vaultHome,
          ),
        );
      case AppEntryFlow.pinCheckForRestoration:

        /// 복원 파일 o, 업데이트 o 일때 바로 이동하는 핀체크 화면
        return CustomLoadingOverlay(
          child: _buildPinCheckScreen(
            pinCheckContext: PinCheckContextEnum.restoration, // TODO: 동작 확인 필요
            nextFlow: AppEntryFlow.restoration,
          ),
        );

      case AppEntryFlow.foundBackupFile:

        /// 복원파일 o, 업데이트 x 일때 이동하는 복원파일 발견 화면
        return CustomLoadingOverlay(
          child: RestorationInfoScreen(
            onComplete: () => _updateEntryFlow(AppEntryFlow.restoration),
            onReset: () => _updateEntryFlow(AppEntryFlow.vaultHome),
          ),
        );

      case AppEntryFlow.restoration:

        /// 복원 진행 화면
        return CustomLoadingOverlay(
          child: VaultListRestorationScreen(onComplete: () => _updateEntryFlow(AppEntryFlow.vaultHome)),
        );

      case AppEntryFlow.vaultHome:
        return const VaultHomeScreen();
    }
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
                _isExitDialogOpen = false;
              });
            }
          }
        }
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => authProvider),
          ChangeNotifierProvider(create: (_) => preferenceProvider),
          ChangeNotifierProxyProvider<PreferenceProvider, VisibilityProvider>(
            create: (context) => visibilityProvider,
            update: (context, preferenceProvider, visibilityProvider) {
              visibilityProvider!.updateIsSigningOnlyMode(preferenceProvider.isSigningOnlyMode);
              return visibilityProvider;
            },
          ),
          ChangeNotifierProxyProvider<PreferenceProvider, WalletProvider>(
            create: (context) => walletProvider,
            update: (context, preferenceProvider, walletProvider) {
              walletProvider!.updateIsSigningOnlyMode(preferenceProvider.isSigningOnlyMode);
              return walletProvider;
            },
          ),
          // TODO: ConnectivityProvider 계속 재생산 되는 것 방지
          ChangeNotifierProxyProvider2<VisibilityProvider, PreferenceProvider, ConnectivityProvider>(
            create:
                (_) => ConnectivityProvider(
                  hasSeenGuide: visibilityProvider.hasSeenGuide,
                  isSigningOnlyMode: preferenceProvider.isSigningOnlyMode,
                ),
            update: (_, visibilityProvider, preferenceProvider, connectivityProvider) {
              if (visibilityProvider.hasSeenGuide) {
                connectivityProvider!.setHasSeenGuideTrue();
              }

              // VaultMode 변경 감지
              final newIsSigningOnlyMode = preferenceProvider.isSigningOnlyMode;
              connectivityProvider!.updateSigningOnlyMode(newIsSigningOnlyMode);

              // 인스턴스 저장
              _connectivityProvider = connectivityProvider;

              return connectivityProvider;
            },
          ),
          if (_appEntryFlow == AppEntryFlow.vaultHome) ...[
            Provider<WalletCreationProvider>(create: (_) => WalletCreationProvider()),
            Provider<SignProvider>(create: (_) => SignProvider()),
          ],
        ],

        child: Directionality(
          textDirection: TextDirection.ltr,
          child:
              _appEntryFlow == AppEntryFlow.vaultHome
                  ? MainRouteGuard(
                    onAppGoBackground: () {
                      if (!preferenceProvider.isSigningOnlyMode) {
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
                      /// 지갑이 0개인 경우에는 pin_check_screen을 거치지 않아서 여기서 생체인증 상태를 업데이트
                      if (_appEntryFlow == AppEntryFlow.vaultHome) {
                        authProvider.updateDeviceBiometricAvailability();
                        // TODO: 안전 저장 모드에서도 TEE영역 사용 시 아래 조건문 제거
                        if (preferenceProvider.isSigningOnlyMode) {
                          // 기기 비밀번호 설정 여부 확인
                          // ConnectivityProvider는 MultiProvider에서 제공되므로
                          // 여기서는 직접 메서드 호출할 수 없음
                          // 대신 별도 메서드 생성
                          _checkDeviceSecurityOnResume();
                        }
                      }
                      if (Platform.isAndroid) return;

                      setState(() {
                        _isInactive = false;
                      });
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
                                        final isEdgePannelVisible =
                                            prefProvider.getVaultMode() == VaultMode.signingOnly &&
                                            _appEntryFlow == AppEntryFlow.vaultHome &&
                                            hasShow;

                                        return _floatingExitButton(context, isEdgePannelVisible);
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
                                (context) => buildScreenWithArguments(
                                  context,
                                  (args) => MnemonicViewScreen(walletId: args['id']),
                                ),
                            AppRoutes.vaultNameSetup: (context) => const VaultNameAndIconSetupScreen(),
                            AppRoutes.singleSigSetupInfo: (context) {
                              return buildScreenWithArguments(
                                context,
                                (args) => SingleSigSetupInfoScreen(
                                  id: args['id'],
                                  entryPoint: args['entryPoint'],
                                  // 서명 전용 모드일 때는 항상 false
                                  hasPassphrase: preferenceProvider.isSigningOnlyMode ? false : args['hasPassphrase'],
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
                            AppRoutes.prepareUpdate:
                                (context) => const CustomLoadingOverlay(child: AppUpdatePreparationScreen()),
                            AppRoutes.passphraseVerification:
                                (context) => buildScreenWithArguments(
                                  context,
                                  (args) => PassphraseVerificationScreen(id: args['id']),
                                ),
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
                      AppRoutes.devicePasswordCheck: (context) => const DevicePasswordCheckScreen(),
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

  Widget _floatingExitButton(BuildContext context, bool isEdgePannelVisible) {
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
                isEdgePannelVisible
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
                          'assets/svg/exit.svg',
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
                            if (_isExitDialogOpen) return;
                            _isExitDialogOpen = true;
                            showDialog(
                              context: navContext,
                              builder: (BuildContext dialogContext) {
                                return CoconutPopup(
                                  insetPadding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(navContext).size.width * 0.15,
                                  ),
                                  title: t.exit_vault,
                                  description: t.exit_vault_description,
                                  backgroundColor: CoconutColors.white,
                                  leftButtonText: t.cancel,
                                  rightButtonText: t.confirm,
                                  rightButtonColor: CoconutColors.black,
                                  onTapLeft: () {
                                    Navigator.pop(dialogContext);
                                    _isExitDialogOpen = false;
                                  },
                                  onTapRight: () {
                                    _isExitDialogOpen = false;
                                    if (Platform.isAndroid) {
                                      SystemNavigator.pop();
                                    } else {
                                      exit(0);
                                    }
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
                              'assets/svg/exit.svg',
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
                              top: 52,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _signingModeEdgePanelWidth == 100.0 ? 1.0 : 0.0,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      t.exit_vault,
                                      style: CoconutTypography.body2_14_Bold.copyWith(color: CoconutColors.white),
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

  void _checkDeviceSecurityOnResume() {
    _connectivityProvider?.checkDeviceSecurityOnResume();
  }
}

/// 라우트 변경을 감지하는 NavigatorObserver
class _CustomNavigatorObserver extends NavigatorObserver {
  final Function(String?) onRouteChanged;

  _CustomNavigatorObserver({required this.onRouteChanged});

  void _notifyRouteChange(Route<dynamic>? route) {
    if (route != null) {
      final routeName = route.settings.name;
      onRouteChanged(routeName);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notifyRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notifyRouteChange(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notifyRouteChange(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notifyRouteChange(previousRoute);
  }
}
