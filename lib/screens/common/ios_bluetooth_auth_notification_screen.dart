import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';

class IosBluetoothAuthNotificationScreen extends StatefulWidget {
  const IosBluetoothAuthNotificationScreen({super.key});

  @override
  State<IosBluetoothAuthNotificationScreen> createState() =>
      _IosBluetoothAuthNotificationScreenState();
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
            SvgPicture.asset(
              'assets/svg/bluetooth.svg',
              width: 48,
            ),
            const SizedBox(height: 20),
            Text(t.ios_bluetooth_auth_notification_screen.allow_permission,
                style: CoconutTypography.body2_14_Bold),
            const SizedBox(height: 20),
            Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: CoconutColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: CoconutColors.gray500.withOpacity(0.3),
                      spreadRadius: 4,
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      t.ios_bluetooth_auth_notification_screen.text1_1,
                      style: CoconutTypography.body2_14.setColor(
                        CoconutColors.black.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      t.ios_bluetooth_auth_notification_screen.text1_2,
                      style: CoconutTypography.body2_14.setColor(
                        CoconutColors.black.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      t.ios_bluetooth_auth_notification_screen.text1_3,
                      style: CoconutTypography.body2_14.setColor(
                        CoconutColors.black.withOpacity(0.7),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.ios_bluetooth_auth_notification_screen.text1_4,
                          style: CoconutTypography.body2_14.setColor(
                            CoconutColors.black.withOpacity(0.7),
                          ),
                        ),
                        HighLightedText(t.ios_bluetooth_auth_notification_screen.text1_5,
                            color: CoconutColors.gray800),
                        Text(
                          t.ios_bluetooth_auth_notification_screen.text1_6,
                          style: CoconutTypography.body2_14.setColor(
                            CoconutColors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      t.ios_bluetooth_auth_notification_screen.text1_7,
                      style: CoconutTypography.body2_14.setColor(
                        CoconutColors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                )),
            const SizedBox(
              height: 100,
            ),
          ],
        ),
      )),
    );
  }
}
