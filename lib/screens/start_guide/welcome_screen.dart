import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late ConnectivityProvider _connectivityProvider;
  late VisibilityProvider _visibilityProvider;
  @override
  void initState() {
    super.initState();
    _connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
    _visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);

    _initConnectionState();
  }

  Future<void> _initConnectionState() async {
    await _connectivityProvider.setConnectActivity(
        bluetooth: true, network: false, developerMode: false);

    // 상태 값이 설정될 때까지 잠시 대기
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CoconutColors.white,
        body: SafeArea(
            child: Stack(
          children: [
            Consumer<ConnectivityProvider>(builder: (context, provider, child) {
              final isNetworkOn = provider.isNetworkOn ?? false;
              final isBluetoothOn = provider.isBluetoothOn ?? false;
              final isDeveloperModeOn = provider.isDeveloperModeOn ?? false;
              final canStart = provider.isNetworkOn == false &&
                  provider.isBluetoothOn == false &&
                  (!Platform.isAndroid || provider.isDeveloperModeOn == false);

              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                        canStart
                            ? t.welcome_screen.title_can_start
                            : t.welcome_screen.title_cannot_start,
                        style: CoconutTypography.heading3_21_Bold,
                        textAlign: TextAlign.center),
                    CoconutLayout.spacing_500h,
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: CoconutColors.gray150,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _getState(
                                  t.welcome_screen.network,
                                  isNetworkOn,
                                  isNetworkOn
                                      ? t.connectivity_state.connected
                                      : t.connectivity_state.disconnected),
                              CoconutLayout.spacing_300h,
                              _getState(
                                  t.welcome_screen.bluetooth,
                                  isBluetoothOn,
                                  isBluetoothOn
                                      ? t.connectivity_state.enabled
                                      : t.connectivity_state.disabled),
                              if (Platform.isAndroid) ...[
                                CoconutLayout.spacing_300h,
                                _getState(
                                    t.welcome_screen.developer_option,
                                    isDeveloperModeOn,
                                    isDeveloperModeOn
                                        ? t.connectivity_state.active
                                        : t.connectivity_state.inactive),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                    CoconutLayout.spacing_2000h,
                  ]);
            }),
            Consumer<ConnectivityProvider>(builder: (context, provider, child) {
              final isActive = provider.isNetworkOn == false &&
                  provider.isBluetoothOn == false &&
                  (!Platform.isAndroid || provider.isDeveloperModeOn == false);

              return FixedBottomButton(
                isActive: isActive,
                onButtonClicked: () {
                  _connectivityProvider.setHasSeenGuideTrue();
                  _visibilityProvider.setHasSeenGuide().then((_) {
                    widget.onComplete();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (Route<dynamic> route) => false,
                      );
                    }
                  });
                },
                text: t.start,
              );
            }),
          ],
        )));
  }

  Widget _getState(String label, bool isOn, String stateText) {
    return Row(
      children: [
        CoconutLayout.spacing_600w,
        Text(label,
            style: isOn
                ? CoconutTypography.body1_16_Bold.setColor(CoconutColors.hotPink)
                : CoconutTypography.body1_16_Bold.setColor(CoconutColors.black),
            maxLines: 2),
        if (isOn) ...[
          CoconutLayout.spacing_100w,
          SvgPicture.asset(
            'assets/svg/triangle-warning.svg',
            width: 16.0,
            height: 16.0,
            colorFilter: const ColorFilter.mode(
              CoconutColors.hotPink,
              BlendMode.srcIn,
            ),
          ),
        ],
        CoconutLayout.spacing_100w,
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOn
                    ? const Color.fromARGB(255, 236, 39, 35)
                    : const Color.fromARGB(255, 95, 211, 109),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                  textAlign: TextAlign.center,
                  stateText,
                  style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.white)),
            ),
          ),
        ),
        CoconutLayout.spacing_600w,
      ],
    );
  }
}
