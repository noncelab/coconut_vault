import 'dart:async';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/view_model/splash_view_model.dart';
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
  late SplashViewModel _viewModel;
  bool _hasSplashDelayFinished = false;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _viewModel = SplashViewModel(
      Provider.of<ConnectivityProvider>(context, listen: false),
      Provider.of<VisibilityProvider>(context, listen: false).hasSeenGuide,
      //Provider.of<PreferenceProvider>(context, listen: false).getVaultMode() != null,
    );
    if (_viewModel.hasSeenGuide) {
      _viewModel.addListener(_onConnectivityStateChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      /// Splash 딜레이
      await Future.delayed(const Duration(seconds: 2));
      if (!_viewModel.hasSeenGuide) {
        /// iOS 블루투스 권한을 Tutorial 단계에서 확인하므로 그 전까지 connectivityState가 null
        widget.onComplete(AppEntryFlow.securityPrecheck);
        return;
      }

      _hasSplashDelayFinished = true;

      if (_viewModel.connectivityState != null && !_hasCompleted) {
        _hasCompleted = true;
        widget.onComplete(AppEntryFlow.securityPrecheck);
        return;
      }
      // 아직 _viewModel.connectivityState가 null이면 이벤트 등록

      // 한번도 튜토리얼을 보지 않은 경우 / 볼트 모드를 선택하지 않은 경우
      // firstLaunch 플로우로 이동
      // TODO: 아래 로직을 securityPrecheck 끝나고로 이동해야함!!!!!
      // if (!_viewModel.hasSeenGuide || !_viewModel.isVaultModeSelected) {
      //   widget.onComplete(AppEntryFlow.firstLaunch);
      //   return;
      // }
    });
  }

  void _onConnectivityStateChanged() {
    if (_viewModel.connectivityState != null && _hasSplashDelayFinished && !_hasCompleted) {
      _hasCompleted = true;
      widget.onComplete(AppEntryFlow.securityPrecheck);
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
          ChangeNotifierProxyProvider<ConnectivityProvider, SplashViewModel>(
            create: (_) => _viewModel,
            update: (_, connectivityProvider, splashViewModel) {
              splashViewModel!.updateConnectivityState();
              return splashViewModel;
            },
            child: Consumer<SplashViewModel>(
              builder: (context, viewModel, child) {
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onConnectivityStateChanged);
    super.dispose();
  }
}
