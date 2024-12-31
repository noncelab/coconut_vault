import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';
import 'package:provider/provider.dart';

class GuideScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const GuideScreen({super.key, required this.onComplete});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, appModel, child) {
      return Scaffold(
        backgroundColor: MyColors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/svg/stethoscope.svg',
                  width: 48,
                ),
                const SizedBox(height: 20),
                const Text(
                  "안전한 비트코인 보관을 위해,\n항상 연결 상태를 OFF로 유지해주세요",
                  style: Styles.body2Bold,
                  textAlign: TextAlign.center,
                ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('네트워크 상태', style: Styles.body2Bold),
                            const SizedBox(width: 40),
                            appModel.isNetworkOn != null &&
                                    appModel.isNetworkOn == true
                                ? const HighLightedText('ON',
                                    color: MyColors.warningText)
                                : const Text('OFF', style: Styles.subLabel)
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('블루투스 상태', style: Styles.body2Bold),
                            const SizedBox(width: 40),
                            appModel.isBluetoothOn != null &&
                                    appModel.isBluetoothOn == true
                                ? const HighLightedText('ON',
                                    color: MyColors.warningText)
                                : const Text('OFF', style: Styles.subLabel)
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('개발자 옵션', style: Styles.body2Bold),
                            const SizedBox(width: 40),
                            appModel.isDeveloperModeOn != null &&
                                    appModel.isDeveloperModeOn == true
                                ? const HighLightedText('ON',
                                    color: MyColors.warningText)
                                : const Text('OFF', style: Styles.subLabel)
                          ],
                        ),
                      ],
                    )),
                const SizedBox(height: 32),
                if (appModel.isNetworkOn == true ||
                    appModel.isBluetoothOn == true)
                  Column(
                    children: [
                      Text("네트워크와 블루투스를 모두 꺼주세요",
                          style: Styles.body2Bold.merge(
                              const TextStyle(color: MyColors.warningText))),
                    ],
                  ),
                const SizedBox(
                  height: 40,
                ),
                GestureDetector(
                    onTap: () async {
                      await appModel.setHasSeenGuide();
                      widget.onComplete!();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: MyColors.black),
                        child: Text(
                          '시작하기',
                          style: Styles.label
                              .merge(const TextStyle(color: MyColors.white)),
                        ))),
                const SizedBox(
                  height: 60,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
