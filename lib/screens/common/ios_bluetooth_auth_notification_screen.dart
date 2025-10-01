import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';

class IosBluetoothAuthNotificationScreen extends StatefulWidget {
  const IosBluetoothAuthNotificationScreen({super.key});

  @override
  State<IosBluetoothAuthNotificationScreen> createState() => _IosBluetoothAuthNotificationScreenState();
}

class _IosBluetoothAuthNotificationScreenState extends State<IosBluetoothAuthNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          color: CoconutColors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.ios_bluetooth_auth_notification_screen.allow_permission,
                style: CoconutTypography.heading3_21_Bold,
                textAlign: TextAlign.center,
              ),
              CoconutLayout.spacing_800h,
              Image.asset('assets/png/state/bluetooth_on.png', width: 140, fit: BoxFit.fitWidth),
              CoconutLayout.spacing_800h,
              Column(
                children: [
                  _buildStep('1', t.ios_bluetooth_auth_notification_screen.guide1),
                  CoconutLayout.spacing_400h,
                  _buildStep('2', t.ios_bluetooth_auth_notification_screen.guide2),
                  CoconutLayout.spacing_400h,
                  _buildStep('3', t.ios_bluetooth_auth_notification_screen.guide3),
                ],
              ),
              const SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String text, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: Container()),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: CoconutColors.black, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(text, style: CoconutTypography.body3_12_Number.setColor(CoconutColors.white))),
        ),
        CoconutLayout.spacing_300w,
        Expanded(flex: 3, child: Text(description, style: CoconutTypography.heading4_18.setColor(CoconutColors.black))),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }
}
