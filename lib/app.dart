import 'package:coconut_vault/screens/airgap/psbt_confirmation_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_scanner_screen.dart';
import 'package:coconut_vault/screens/airgap/signed_transaction_qr_screen.dart';
import 'package:coconut_vault/screens/security_self_check_screen.dart';
import 'package:coconut_vault/screens/setting/app_info_screen.dart';
import 'package:coconut_vault/screens/setting/mnemonic_word_list_screen.dart';
import 'package:coconut_vault/screens/start_guide/guide_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:coconut_vault/screens/tutorial_screen.dart';
import 'package:coconut_vault/screens/vault_creation/mnemonic_coin_flip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/mnemonic_generate_screen.dart';
import 'package:coconut_vault/screens/vault_creation/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_icon_setup_screen.dart';
import 'package:coconut_vault/screens/vault_detail/address_list_screen.dart';
import 'package:coconut_vault/screens/vault_detail/sync_to_wallet_screen.dart';
import 'package:coconut_vault/screens/vault_detail/vault_detail_screen.dart';
import 'package:coconut_vault/screens/vault_detail/vault_settings.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/router_util.dart';
import 'package:coconut_vault/vault_list_tab.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/vault_model.dart';
import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/screens/start_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:provider/provider.dart';

enum HomeScreen {
  splash,
  tutorial,
  pincheck,
  vaultlist,
}

/// HomeScreen 상태 관리 싱글톤 객체
class HomeScreenStatus {
  static final HomeScreenStatus _instance = HomeScreenStatus._internal();

  factory HomeScreenStatus() {
    return _instance;
  }

  HomeScreenStatus._internal();

  HomeScreen screenStatus = HomeScreen.splash;

  void updateScreenStatus(HomeScreen status) {
    screenStatus = status;
  }
}

class PowVaultApp extends StatefulWidget {
  const PowVaultApp({super.key});

  @override
  State<PowVaultApp> createState() => _PowVaultAppState();
}

class _PowVaultAppState extends State<PowVaultApp> {
  Widget getHomeScreenRoute(HomeScreen status) {
    if (status == HomeScreen.splash) {
      return StartScreen(onComplete: (status) {
        setState(() {
          HomeScreenStatus().updateScreenStatus(status);
        });
      });
    } else if (status == HomeScreen.tutorial) {
      return const TutorialScreen(
        screenStatus: TutorialScreenStatus.entrance,
      );
    } else if (status == HomeScreen.pincheck) {
      return CustomLoadingOverlay(
        child: PinCheckScreen(
          screenStatus: PinCheckScreenStatus.entrance,
          onComplete: () {
            setState(() {
              HomeScreenStatus().updateScreenStatus(HomeScreen.vaultlist);
            });
          },
          onReset: () async {
            /// 초기화 이후 메인 라우터 이동
            setState(() {
              HomeScreenStatus().updateScreenStatus(HomeScreen.vaultlist);
            });
          },
        ),
      );
    }
    return const VaultListTab();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// splash, guide, main, pinCheck 에서 공통으로 사용하는 모델
        ChangeNotifierProvider(
          create: (_) => AppModel(
            onConnectivityStateChanged: (ConnectivityState state) {
              // Bluetooth, Network, Developer mode 리스너
              if (state == ConnectivityState.on) {
                goAppUnavailableNotificationScreen(context);
              } else if (state == ConnectivityState.bluetoothUnauthorized) {
                goBluetoothAuthNotificationScreen(context);
              }
            },
          ),
        ),
        ChangeNotifierProxyProvider<AppModel, VaultModel>(
          create: (_) => VaultModel(Provider.of<AppModel>(_, listen: false)),
          update: (_, appModel, vaultModel) =>
              vaultModel!..updateAppModel(appModel),
        ),
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
          home: getHomeScreenRoute(HomeScreenStatus().screenStatus),
          routes: {
            '/vault-lock': (context) => buildScreenWithArguments(
                  context,
                  (args) => CustomLoadingOverlay(
                    child: PinCheckScreen(
                      screenStatus: PinCheckScreenStatus.lock,
                      onReset: () async {
                        HomeScreenStatus()
                            .updateScreenStatus(HomeScreen.vaultlist);
                      },
                    ),
                  ),
                ),
            '/vault-creation-options': (context) =>
                const VaultCreationOptions(),
            '/mnemonic-import': (context) => const MnemonicImport(),
            '/vault-name-setup': (context) => const VaultNameIconSetup(),
            '/vault-details': (context) => buildScreenWithArguments(
                  context,
                  (args) => VaultDetails(id: args['id']),
                ),
            '/vault-settings': (context) => buildScreenWithArguments(
                  context,
                  (args) => VaultSettings(id: args['id']),
                ),
            '/mnemonic-word-list': (context) => const MnemonicWordListScreen(),
            '/address-list': (context) => buildScreenWithArguments(
                  context,
                  (args) => AddressListScreen(id: int.parse(args['id'])),
                ),
            '/psbt-scanner': (context) => buildScreenWithArguments(
                  context,
                  (args) => PsbtScannerScreen(id: int.parse(args['id'])),
                ),
            '/psbt-confirmation': (context) => buildScreenWithArguments(
                  context,
                  (args) => PsbtConfirmationScreen(id: args['id']),
                ),
            '/signed-transaction': (context) => buildScreenWithArguments(
                  context,
                  (args) => SignedTransactionQrScreen(id: args['id']),
                ),
            '/sync-to-wallet': (context) => buildScreenWithArguments(
                  context,
                  (args) => SyncToWalletScreen(id: args['id']),
                ),
            '/security-self-check': (context) {
              final VoidCallback? onNextPressed =
                  ModalRoute.of(context)?.settings.arguments as VoidCallback?;
              return SecuritySelfCheckScreen(onNextPressed: onNextPressed);
            },
            '/mnemonic-generate': (context) => const MnemonicGenerateScreen(),
            '/mnemonic-flip-coin': (context) => const MnemonicFlipCoinScreen(),
            '/app-info': (context) => const AppInfoScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/connectivity-guide': (context) {
              onComplete() {
                Logger.log('aaaahsudhushjdhsjdhjshdjhsjdhjhsjhdjshdj');
                setState(() {
                  HomeScreenStatus().updateScreenStatus(HomeScreen.vaultlist);
                });
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
