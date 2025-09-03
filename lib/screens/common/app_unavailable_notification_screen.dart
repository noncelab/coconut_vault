import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';

class AppUnavailableNotificationScreen extends StatefulWidget {
  const AppUnavailableNotificationScreen({super.key});

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
              SvgPicture.asset(
                'assets/svg/coconut-security-${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.svg',
                width: 80,
              ),
              const SizedBox(height: 20),
              Text(
                t.app_unavailable_notification_screen.network_on,
                style: CoconutTypography.body2_14_Bold,
              ),
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
                        '1',
                        style: CoconutTypography.body2_14.setColor(
                          CoconutColors.black.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        t.app_unavailable_notification_screen.text1_1,
                        style: CoconutTypography.body2_14.setColor(
                          CoconutColors.black.withOpacity(0.7),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.app_unavailable_notification_screen.text1_2,
                            style: CoconutTypography.body2_14.setColor(
                              CoconutColors.black.withOpacity(0.7),
                            ),
                          ),
                          HighLightedText(t.app_unavailable_notification_screen.text1_3,
                              color: CoconutColors.gray800),
                          Text(
                            t.app_unavailable_notification_screen.text1_4,
                            style: CoconutTypography.body2_14.setColor(
                              CoconutColors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '2',
                        style: CoconutTypography.body2_14.setColor(
                          CoconutColors.black.withOpacity(0.7),
                        ),
                      ),
                      HighLightedText(t.app_unavailable_notification_screen.text2,
                          color: CoconutColors.gray800),
                      Text(
                        t.app_unavailable_notification_screen.check_status,
                        style: CoconutTypography.body2_14.setColor(
                          CoconutColors.black.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isAndroid) ...[
                        // Android only: iOS는 개발자 모드 on/off 확인 불가
                        Text(
                          '3',
                          style: CoconutTypography.body2_14.setColor(
                            CoconutColors.black.withOpacity(0.7),
                          ),
                        ),
                        HighLightedText(t.app_unavailable_notification_screen.text3,
                            color: CoconutColors.gray800),
                        Text(
                          t.app_unavailable_notification_screen.check_status,
                          style: CoconutTypography.body2_14.setColor(
                            CoconutColors.black.withOpacity(0.7),
                          ),
                        ),
                      ]
                    ],
                  )),
              const SizedBox(
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
