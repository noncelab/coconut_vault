import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppUnavailableNotificationScreen extends StatefulWidget {
  final bool? isNetworkOn;
  final bool? isBluetoothOn;
  final bool? isDeveloperModeOn;

  const AppUnavailableNotificationScreen({
    super.key,
    this.isNetworkOn,
    this.isBluetoothOn,
    this.isDeveloperModeOn,
  });

  @override
  State<AppUnavailableNotificationScreen> createState() => _AppUnavailableNotificationScreenState();
}

class _AppUnavailableNotificationScreenState extends State<AppUnavailableNotificationScreen> {
  bool isAndroid = Platform.isAndroid ? true : false;

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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers the content vertically
            children: [
              Text(t.app_unavailable_notification_screen.restart_app,
                  style: CoconutTypography.heading3_21_Bold, textAlign: TextAlign.center),
              CoconutLayout.spacing_800h,
              _buildImage(),
              CoconutLayout.spacing_800h,
              _buildStep('1', t.app_unavailable_notification_screen.step1),
              CoconutLayout.spacing_400h,
              _buildStep('2', t.app_unavailable_notification_screen.step2),
              CoconutLayout.spacing_400h,
              _buildStep('3', t.app_unavailable_notification_screen.step3),
              const SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.isNetworkOn == true) {
      return Image.asset('assets/png/state/wifi_on.png', width: 140, fit: BoxFit.fitWidth);
    } else if (widget.isBluetoothOn == true) {
      return Image.asset('assets/png/state/bluetooth_on.png', width: 140, fit: BoxFit.fitWidth);
    } else if (Platform.isAndroid && widget.isDeveloperModeOn == true) {
      return Image.asset('assets/png/state/developer_on.png', width: 140, fit: BoxFit.fitWidth);
    }
    return Container();
  }

  Widget _buildStep(String text, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: Container()),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: CoconutColors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: CoconutTypography.body3_12_Number.setColor(CoconutColors.white),
            ),
          ),
        ),
        CoconutLayout.spacing_300w,
        Expanded(
          flex: 2,
          child: Text(
            description,
            style: CoconutTypography.heading4_18.setColor(CoconutColors.black),
          ),
        ),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }
}
