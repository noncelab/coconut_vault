import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/services/shared_preferences_keys.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/services/secure_storage_service.dart';
import 'package:coconut_vault/styles.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatefulWidget {
  final void Function(HomeScreen status) onComplete;

  const StartScreen({super.key, required this.onComplete});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late bool _hasSeenGuide;

  @override
  void initState() {
    super.initState();
    _hasSeenGuide =
        SharedPrefsService().getBool(SharedPrefsKeys.hasShownStartGuide) ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      /// Splash 딜레이
      await Future.delayed(const Duration(seconds: 2));

      /// 한번도 튜토리얼을 보지 않은 경우
      if (!_hasSeenGuide) {
        _goTutorialScreen();
      }
    });
  }

  Future _goNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    bool isNotEmpty =
        SharedPrefsService().getBool(SharedPrefsKeys.isNotEmptyVaultList) ?? false;
    bool isPinEnabled =
        SharedPrefsService().getBool(SharedPrefsKeys.isPinEnabled) ?? false;

    /// 비밀번호 등록 되어 있더라도, 추가한 볼트가 없는 경우는 볼트 리스트 화면으로 이동합니다.
    if (isNotEmpty) {
      assert(isPinEnabled == true);
      widget.onComplete(HomeScreen.pincheck);
    } else {
      widget.onComplete(HomeScreen.vaultlist);
    }
  }

  Future _goTutorialScreen() async {
    if (Platform.isIOS) {
      // iOS는 앱을 삭제해도 secure storage에 데이터가 남아있음
      await SecureStorageService().deleteAll();
    }
    widget.onComplete(HomeScreen.tutorial); // 가이드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      body: Column(
        children: [
          Flexible(
            child: Center(
              child: Image.asset(
                'assets/png/splash_logo.png',
              ),
            ),
          ),
          Selector<AppModel, Map<String, bool?>>(
            selector: (context, provider) => {
              'isNetworkOn': provider.isNetworkOn,
              'isBluetoothOn': provider.isBluetoothOn,
              'isDeveloperModeOn': provider.isDeveloperModeOn,
            },
            builder: (context, selectedValues, child) {
              if (!_hasSeenGuide) {
                return Container();
              }

              final isNetworkOn = selectedValues['isNetworkOn'];
              final isBluetoothOn = selectedValues['isBluetoothOn'];
              final isDeveloperModeOn = selectedValues['isDeveloperModeOn'];

              bool hasConnectivitySet = isNetworkOn != null &&
                  isBluetoothOn != null &&
                  isDeveloperModeOn != null;
              // 아직 연결 상태 체크가 완료되지 않음
              if (!hasConnectivitySet) return Container();

              // 연결 상태 체크 완료
              bool isConnectivityOn = true;
              if (Platform.isAndroid) {
                isConnectivityOn =
                    isNetworkOn || isBluetoothOn || isDeveloperModeOn;
              } else {
                isConnectivityOn = isNetworkOn || isBluetoothOn;
              }

              if (!isConnectivityOn) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _goNextScreen();
                });
              }

              return Container();
            },
          )
        ],
      ),
    );
  }
}
