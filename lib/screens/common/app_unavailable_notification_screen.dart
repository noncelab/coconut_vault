import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
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
    return Scaffold(
      backgroundColor: MyColors.white,
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
              Text(t.app_unavailable_notification_screen.network_on, style: Styles.body2Bold),
              const SizedBox(height: 20),
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: MyColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 4,
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('1', style: Styles.subLabel),
                      Text(t.app_unavailable_notification_screen.text1_1, style: Styles.subLabel),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.app_unavailable_notification_screen.text1_2,
                              style: Styles.subLabel),
                          HighLightedText(t.app_unavailable_notification_screen.text1_3,
                              color: MyColors.darkgrey),
                          Text(t.app_unavailable_notification_screen.text1_4,
                              style: Styles.subLabel),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('2', style: Styles.subLabel),
                      HighLightedText(t.app_unavailable_notification_screen.text2,
                          color: MyColors.darkgrey),
                      Text(t.app_unavailable_notification_screen.check_status,
                          style: Styles.subLabel),
                      const SizedBox(height: 24),
                      if (isAndroid) ...[
                        // Android only: iOS는 개발자 모드 on/off 확인 불가
                        const Text('3', style: Styles.subLabel),
                        HighLightedText(t.app_unavailable_notification_screen.text3,
                            color: MyColors.darkgrey),
                        Text(t.app_unavailable_notification_screen.check_status,
                            style: Styles.subLabel),
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
