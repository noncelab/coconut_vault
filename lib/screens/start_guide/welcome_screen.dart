import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late ConnectivityProvider _connectivityProvider;
  late CarouselSliderController _controller;
  late VisibilityProvider _visibilityProvider;
  int _current = 0;
  final Set<int> _viewedPages = {
    0,
  };

  @override
  void initState() {
    super.initState();
    _connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
    _visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);

    _initConnectionState();

    _controller = CarouselSliderController();
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
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CarouselSlider(
                  carouselController: _controller,
                  options: CarouselOptions(
                    autoPlay: false,
                    aspectRatio: 1.0,
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _current = index;
                        _viewedPages.add(index);
                      });
                    },
                  ),
                  items: [
                    _buildGuide(1),
                    _buildGuide(2),
                    _buildGuide(3),
                  ].map((item) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
                      child: item,
                    );
                  }).toList(),
                ),
                const SizedBox(
                  height: 200,
                ),
              ],
            )),
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(3, (index) {
                  return GestureDetector(
                      onTap: () => _controller.animateToPage(index),
                      child: Container(
                        width: _current == index ? 9.0 : 7,
                        height: _current == index ? 9.0 : 7,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CoconutColors.black.withOpacity(_current == index ? 0.7 : 0.3),
                        ),
                      ));
                }),
              ),
            ),
            Consumer<ConnectivityProvider>(builder: (context, provider, child) {
              final isActive = provider.isNetworkOn == false &&
                  provider.isBluetoothOn == false &&
                  (!Platform.isAndroid || provider.isDeveloperModeOn == false);

              return Visibility(
                visible: _viewedPages.length == 3,
                child: FixedBottomButton(
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
                ),
              );
            }),
          ],
        )));
  }

  Widget _buildGuide(
    int step,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_getMessage(step),
            style: CoconutTypography.heading3_21_Bold, textAlign: TextAlign.center),
        CoconutLayout.spacing_1000h,
        _getImage(step),
      ],
    );
  }

  String _getMessage(int step) {
    switch (step) {
      case 1:
        return t.welcome_screen.guide1;
      case 2:
        return t.welcome_screen.guide2;
      case 3:
        return t.welcome_screen.guide3;
    }
    return '';
  }

  Widget _getImage(int step) {
    switch (step) {
      case 1:
        return Image.asset('assets/png/onboarding_1.png', height: 160, fit: BoxFit.fitHeight);
      case 2:
        return Image.asset('assets/png/onboarding_2.png', height: 160, fit: BoxFit.fitHeight);
      case 3:
        return Container(
          height: 160,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: BoxDecoration(
            color: CoconutColors.gray150,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Consumer<ConnectivityProvider>(builder: (context, provider, child) {
            final isNetworkOn = provider.isNetworkOn ?? false;
            final isBluetoothOn = provider.isBluetoothOn ?? false;
            final isDeveloperModeOn = provider.isDeveloperModeOn ?? false;

            return Column(
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
                _getState(t.welcome_screen.bluetooth, isBluetoothOn,
                    isBluetoothOn ? t.connectivity_state.enabled : t.connectivity_state.disabled),
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
            );
          }),
        );
    }
    return Container();
  }

  Widget _getState(String label, bool isOn, String stateText) {
    return Row(
      children: [
        Expanded(flex: 1, child: Container()),
        Expanded(
            flex: 4,
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: CoconutTypography.heading4_18_Bold))),
        Expanded(flex: 1, child: Container()),
        Expanded(
            flex: 1,
            child: isOn
                ? SvgPicture.asset('assets/svg/circle-stop-outlined.svg')
                : SvgPicture.asset('assets/svg/circle-check-outlined.svg')),
        CoconutLayout.spacing_200w,
        Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                stateText,
                style: isOn
                    ? CoconutTypography.heading4_18_Bold.setColor(CoconutColors.red)
                    : CoconutTypography.heading4_18.setColor(CoconutColors.black),
              ),
            )),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }
}
