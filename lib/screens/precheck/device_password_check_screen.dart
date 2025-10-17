import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/main_route_guard.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/utils/device_secure_checker.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DevicePasswordCheckScreen extends StatefulWidget {
  const DevicePasswordCheckScreen({super.key});

  @override
  State<DevicePasswordCheckScreen> createState() => _DevicePasswordCheckScreenState();
}

class _DevicePasswordCheckScreenState extends State<DevicePasswordCheckScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainRouteGuard(
      onAppGoActive: () async {
        bool deviceSecured = await isDeviceSecured();
        if (deviceSecured) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.welcome);
        }
      },
      onAppGoBackground: () {},
      onAppGoInactive: () {},
      child: Scaffold(
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
                                  t.device_password_check_screen.set_device_password,
                                  style: CoconutTypography.heading3_21_Bold,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            CoconutLayout.spacing_300h,
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.23),

                              child: Text(
                                t.device_password_check_screen.set_device_password_description,
                                style: CoconutTypography.body1_16,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CoconutLayout.spacing_800h,
                      Flexible(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 80),
                          child: Image.asset('assets/png/password-required.png', fit: BoxFit.fitWidth),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return FixedBottomButton(
      isActive: true,
      onButtonClicked: () async {
        await openSystemSecuritySettings(
          context,
          hasDialogShownForIos: true,
          title: t.device_password_check_screen.ios_settings_dialog_title,
          description: t.device_password_check_screen.ios_settings_dialog_description,
          buttonText: t.confirm,
        );
      },
      text: t.device_password_check_screen.go_to_settings,
    );
  }
}
