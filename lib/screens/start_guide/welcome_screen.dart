import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
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

class ScreenItem {
  final String title;
  final String descriptionText;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? imagePath;

  ScreenItem({
    required this.title,
    required this.descriptionText,
    required this.buttonText,
    required this.onButtonPressed,
    this.imagePath,
  });
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late ConnectivityProvider _connectivityProvider;
  late VisibilityProvider _visibilityProvider;
  int _currentScreenIndex = 0;

  final List<ScreenItem> _screenItems = [];

  @override
  void initState() {
    super.initState();
    _connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
    _visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);

    _initScreenItems();
    _initConnectionState();
  }

  void _initScreenItems() {
    _screenItems.addAll([
      ScreenItem(
        title: t.welcome_screen.screen_1_title,
        descriptionText: t.welcome_screen.screen_1_description,
        buttonText: t.welcome_screen.screen_1_button,
        onButtonPressed: () {
          setState(() {
            _currentScreenIndex = 1;
          });
        },
      ),
      ScreenItem(
        title: t.welcome_screen.screen_2_title,
        descriptionText: t.welcome_screen.screen_2_description,
        buttonText: t.welcome_screen.screen_2_button,
        onButtonPressed: () {
          setState(() {
            _currentScreenIndex = 2;
          });
        },
      ),
      ScreenItem(
        title: t.welcome_screen.screen_3_title,
        descriptionText: t.welcome_screen.screen_3_description,
        imagePath: 'assets/png/welcome2.png',
        buttonText: t.welcome_screen.screen_3_button,
        onButtonPressed: () {
          _connectivityProvider.setHasSeenGuideTrue();
          _visibilityProvider.setHasSeenGuide().then((_) {
            widget.onComplete();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
            }
          });
        },
      ),
    ]);
  }

  Future<void> _initConnectionState() async {
    await _connectivityProvider.setConnectActivity(bluetooth: true, network: false, developerMode: false);

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
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _screenItems[_currentScreenIndex].title,
                                style: CoconutTypography.heading3_21_Bold,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          CoconutLayout.spacing_300h,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _screenItems[_currentScreenIndex].descriptionText,
                                style: CoconutTypography.body1_16,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CoconutLayout.spacing_800h,
                    Flexible(flex: 2, child: _getImage()),
                  ],
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getImage() {
    switch (_currentScreenIndex) {
      case 0:
        return Image.asset(
          'assets/png/welcome1.png',
          height: MediaQuery.of(context).size.height * 0.3,
          fit: BoxFit.fitHeight,
        );
      case 2:
        return Image.asset(
          'assets/png/welcome2.png',
          height: MediaQuery.of(context).size.height * 0.3,
          fit: BoxFit.fitHeight,
        );
      case 1:
      default:
        return Consumer<ConnectivityProvider>(
          builder: (context, provider, child) {
            final isNetworkOn = provider.isNetworkOn ?? false;
            final isBluetoothOn = provider.isBluetoothOn ?? false;
            final isDeveloperModeOn = provider.isDeveloperModeOn ?? false;

            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(color: CoconutColors.gray150, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _getConnectionState(
                        t.welcome_screen.network,
                        isNetworkOn,
                        isNetworkOn ? t.connectivity_state.connected : t.connectivity_state.disconnected,
                      ),
                      CoconutLayout.spacing_300h,
                      _getConnectionState(
                        t.welcome_screen.bluetooth,
                        isBluetoothOn,
                        isBluetoothOn ? t.connectivity_state.enabled : t.connectivity_state.disabled,
                      ),
                      if (Platform.isAndroid) ...[
                        CoconutLayout.spacing_300h,
                        _getConnectionState(
                          t.welcome_screen.developer_option,
                          isDeveloperModeOn,
                          isDeveloperModeOn ? t.connectivity_state.active : t.connectivity_state.inactive,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
    }
  }

  Widget _getConnectionState(String label, bool isOn, String stateText) {
    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
      child: Row(
        children: [
          CoconutLayout.spacing_600w,
          Text(
            label,
            style:
                isOn
                    ? CoconutTypography.body1_16_Bold.setColor(CoconutColors.hotPink)
                    : CoconutTypography.body1_16_Bold.setColor(CoconutColors.black),
            maxLines: 2,
          ),
          if (isOn) ...[
            CoconutLayout.spacing_100w,
            SvgPicture.asset(
              'assets/svg/triangle-warning.svg',
              width: 16.0,
              height: 16.0,
              colorFilter: const ColorFilter.mode(CoconutColors.hotPink, BlendMode.srcIn),
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
                  color: isOn ? const Color.fromARGB(255, 236, 39, 35) : const Color.fromARGB(255, 95, 211, 109),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  textAlign: TextAlign.center,
                  stateText,
                  style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.white),
                ),
              ),
            ),
          ),
          CoconutLayout.spacing_600w,
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    if (_currentScreenIndex == 1) {
      return Consumer<ConnectivityProvider>(
        builder: (context, provider, child) {
          final isActive =
              provider.isNetworkOn == false &&
              provider.isBluetoothOn == false &&
              (!Platform.isAndroid || provider.isDeveloperModeOn == false);

          return FixedBottomButton(
            isActive: isActive,
            onButtonClicked: _screenItems[_currentScreenIndex].onButtonPressed,
            text: _screenItems[_currentScreenIndex].buttonText,
            subWidget: _buildSubButton(),
          );
        },
      );
    }
    return FixedBottomButton(
      isActive: true,
      onButtonClicked: _screenItems[_currentScreenIndex].onButtonPressed,
      text: _screenItems[_currentScreenIndex].buttonText,
    );
  }

  Widget _buildSubButton() {
    return CoconutButton(
      onPressed: _showSettingGuide,
      text: t.welcome_screen.setting_guide,
      backgroundColor: Colors.transparent,
      foregroundColor: CoconutColors.black,
      textStyle: CoconutTypography.body2_14,
      pressedBackgroundColor: CoconutColors.gray150,
      pressedTextColor: CoconutColors.gray400,
    );
  }

  void _showSettingGuide() {
    MyBottomSheet.showDraggableBottomSheet(
      title: t.welcome_screen.setting_guide,
      context: context,
      childBuilder:
          (controller) => Scaffold(
            backgroundColor: CoconutColors.white,
            body: SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSettingTitle(
                      t.welcome_screen.airplane_mode_on.title,
                      'assets/svg/settings-guide-icons/airplane-mode.svg',
                    ),
                    _buildSettingDescription(
                      Platform.isAndroid
                          ? t.welcome_screen.airplane_mode_on.description_android
                          : t.welcome_screen.airplane_mode_on.description_ios,
                    ),
                    _buildSettingTitle(t.welcome_screen.wifi_off.title, 'assets/svg/settings-guide-icons/wifi.svg'),
                    _buildSettingDescription(
                      Platform.isAndroid
                          ? t.welcome_screen.wifi_off.description_android
                          : t.welcome_screen.wifi_off.description_ios,
                    ),
                    _buildSettingTitle(
                      t.welcome_screen.mobile_data_off.title,
                      'assets/svg/settings-guide-icons/mobile-data.svg',
                    ),
                    _buildSettingDescription(
                      Platform.isAndroid
                          ? t.welcome_screen.mobile_data_off.description_android
                          : t.welcome_screen.mobile_data_off.description_ios,
                    ),
                    _buildSettingTitle(
                      t.welcome_screen.bluetooth_off.title,
                      'assets/svg/settings-guide-icons/bluetooth.svg',
                    ),
                    _buildSettingDescription(
                      Platform.isAndroid
                          ? t.welcome_screen.bluetooth_off.description_android
                          : t.welcome_screen.bluetooth_off.description_ios,
                    ),
                    if (Platform.isAndroid) ...[
                      _buildSettingTitle(
                        t.welcome_screen.developer_mode_off,
                        'assets/svg/settings-guide-icons/developer-mode.svg',
                      ),
                      _buildSettingDescription(t.welcome_screen.developer_mode_description),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSettingTitle(String title, String iconPath) {
    return Row(
      children: [
        SvgPicture.asset(iconPath, height: 16, fit: BoxFit.fitHeight),
        CoconutLayout.spacing_100w,
        Expanded(child: Text(title, style: CoconutTypography.heading4_18_Bold)),
      ],
    );
  }

  Widget _buildSettingDescription(String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 12, bottom: 24),
      child: Text(description, style: CoconutTypography.body1_16),
    );
  }
}
