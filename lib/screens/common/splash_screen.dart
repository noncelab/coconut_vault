import 'dart:async';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/view_model/start_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// 앱 플로우의 진입점으로 스플래시를 띄움
// 네트워크 연결 상태가 null이 아닐때까지 대기 후
// 체크 후 보안 검사 플로우로 이동
class SplashScreen extends StatefulWidget {
  final void Function(AppEntryFlow status) onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late StartViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StartViewModel(
      Provider.of<ConnectivityProvider>(context, listen: false),
      Provider.of<VisibilityProvider>(context, listen: false).hasSeenGuide,
      Provider.of<PreferenceProvider>(context, listen: false).getVaultMode() != null,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      /// Splash 딜레이
      await Future.delayed(const Duration(seconds: 2));

      // 한번도 튜토리얼을 보지 않은 경우 / 볼트 모드를 선택하지 않은 경우
      // firstLaunch 플로우로 이동
      if (!_viewModel.hasSeenGuide || !_viewModel.isVaultModeSelected) {
        widget.onComplete(AppEntryFlow.firstLaunch);
        return;
      }

      // 네트워크 연결 상태 null이 아닐때까지 대기
      if (_viewModel.connectivityState == null) {
        return;
      }

      widget.onComplete(AppEntryFlow.securityPrecheck);
    });
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

    return Scaffold(
      backgroundColor: CoconutColors.white,
      body: Column(
        children: [
          Flexible(
            child: Container(
              padding: Platform.isIOS ? null : const EdgeInsets.only(top: Sizes.size48),
              child: Center(
                child: Image.asset(
                  'assets/png/splash_logo_${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.png',
                  width: Sizes.size60,
                ),
              ),
            ),
          ),
          ChangeNotifierProxyProvider<ConnectivityProvider, StartViewModel>(
            create: (_) => _viewModel,
            update: (_, connectivityProvider, startViewModel) {
              startViewModel!.updateConnectivityState();
              return startViewModel;
            },
            child: Consumer<StartViewModel>(
              builder: (context, viewModel, child) {
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}
