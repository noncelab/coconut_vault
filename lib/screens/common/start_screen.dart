import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/view_model/start_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/material.dart';
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
    _viewModel = StartViewModel(Provider.of<ConnectivityProvider>(context, listen: false),
        Provider.of<VisibilityProvider>(context, listen: false).hasSeenGuide);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      /// Splash 딜레이
      await Future.delayed(const Duration(seconds: 2));

      /// 한번도 튜토리얼을 보지 않은 경우
      if (!_viewModel.hasSeenGuide) {
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
    return Scaffold(
      backgroundColor: CoconutColors.white,
      body: Column(
        children: [
          Flexible(
            child: Center(
              child: Image.asset(
                'assets/png/splash_logo.png',
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
