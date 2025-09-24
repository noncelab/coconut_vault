import 'dart:async';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/view_model/start_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatefulWidget {
  final void Function(AppEntryFlow status) onComplete;

  const StartScreen({super.key, required this.onComplete});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late StartViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StartViewModel(
        Provider.of<ConnectivityProvider>(context, listen: false),
        Provider.of<AuthProvider>(context, listen: false),
        Provider.of<VisibilityProvider>(context, listen: false).hasSeenGuide,
        Provider.of<PreferenceProvider>(context, listen: false).getVaultMode() != null);

    if (_viewModel.isVaultModeSelected &&
        context.read<PreferenceProvider>().getVaultMode() == VaultMode.signingOnly) {
      // 서명 전용 모드인 경우 한번 더 초기화 작업을 진행합니다.
      Logger.log('[서명 전용 모드]인 경우 한번 더 초기화 작업을 진행합니다.');
      // TODO: 서명 전용 모드 초기화 작업 추가
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      /// Splash 딜레이
      await Future.delayed(const Duration(seconds: 2));

      /// 한번도 튜토리얼을 보지 않은 경우 / 볼트 모드를 선택하지 않은 경우
      if (!_viewModel.hasSeenGuide || !_viewModel.isVaultModeSelected) {
        _showTutorialScreen();
      }
    });
  }

  Future _showTutorialScreen() async {
    widget.onComplete(AppEntryFlow.tutorial); // 가이드
  }

  Future _determineNextEntryFlow() async {
    await Future.delayed(const Duration(seconds: 2));

    var nextEntryFlow = await _viewModel.getNextEntryFlow();
    widget.onComplete(nextEntryFlow);
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
                  if (!viewModel.hasSeenGuide) {
                    return Container();
                  }

                  // 아직 연결 상태 체크가 완료되지 않음
                  if (viewModel.connectivityState == null) return Container();
                  if (!viewModel.connectivityState!) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _determineNextEntryFlow();
                    });
                  }

                  // 첫 실행이 아닌데 무엇인가 켜져 있는 경우, connectivityProvider에 의해서 알림 화면으로 자동 이동됨.
                  return Container();
                },
              ))
        ],
      ),
    );
  }
}
