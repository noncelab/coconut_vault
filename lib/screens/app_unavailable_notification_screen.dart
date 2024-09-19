import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';

class AppUnavailableNotificationScreen extends StatefulWidget {
  const AppUnavailableNotificationScreen({super.key});

  @override
  State<AppUnavailableNotificationScreen> createState() =>
      _AppUnavailableNotificationScreenState();
}

class _AppUnavailableNotificationScreenState
    extends State<AppUnavailableNotificationScreen> {
  bool isAndroid = Platform.isAndroid ? true : false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centers the content vertically
            children: [
              SvgPicture.asset(
                'assets/svg/coconut-security.svg',
                width: 80,
              ),
              const SizedBox(height: 20),
              const Text("휴대폰이 외부와 연결된 상태예요", style: Styles.body2Bold),
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
                      const Text('안전한 사용을 위해', style: Styles.subLabel),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('지금 바로 ', style: Styles.subLabel),
                          HighLightedText('앱을 종료', color: MyColors.darkgrey),
                          Text('해 주세요', style: Styles.subLabel),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('2', style: Styles.subLabel),
                      const HighLightedText('네트워크 및 블루투스',
                          color: MyColors.darkgrey),
                      const Text('상태를 확인해 주세요', style: Styles.subLabel),
                      const SizedBox(height: 24),
                      if (isAndroid) ...[
                        // Android only: iOS는 개발자 모드 on/off 확인 불가
                        const Text('3', style: Styles.subLabel),
                        const HighLightedText('개발자 옵션 OFF',
                            color: MyColors.darkgrey),
                        const Text('상태를 확인해 주세요', style: Styles.subLabel),
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
