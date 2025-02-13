import 'dart:io';

import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
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
                Text(
                  t.guide_screen.keep_network_off,
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
                            Text(t.guide_screen.network_status,
                                style: Styles.body2Bold),
                            const SizedBox(width: 40),
                            appModel.isNetworkOn != null &&
                                    appModel.isNetworkOn == true
                                ? HighLightedText(t.guide_screen.on,
                                    color: MyColors.warningText)
                                : Text(t.guide_screen.off,
                                    style: Styles.subLabel)
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t.guide_screen.bluetooth_status,
                                style: Styles.body2Bold),
                            const SizedBox(width: 40),
                            appModel.isBluetoothOn != null &&
                                    appModel.isBluetoothOn == true
                                ? HighLightedText(t.guide_screen.on,
                                    color: MyColors.warningText)
                                : Text(t.guide_screen.off,
                                    style: Styles.subLabel)
                          ],
                        ),
                        if (Platform.isAndroid) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.guide_screen.developer_option,
                                  style: Styles.body2Bold),
                              const SizedBox(width: 40),
                              appModel.isDeveloperModeOn != null &&
                                      appModel.isDeveloperModeOn == true
                                  ? HighLightedText(t.guide_screen.on,
                                      color: MyColors.warningText)
                                  : Text(t.guide_screen.off,
                                      style: Styles.subLabel)
                            ],
                          ),
                        ]
                      ],
                    )),
                const SizedBox(height: 32),
                if (appModel.isNetworkOn == true ||
                    appModel.isBluetoothOn == true)
                  Column(
                    children: [
                      Text(t.guide_screen.turn_off_network_and_bluetooth,
                          style: Styles.body2Bold.merge(
                              const TextStyle(color: MyColors.warningText))),
                    ],
                  ),
                if (appModel.isDeveloperModeOn == true && Platform.isAndroid)
                  Text(t.guide_screen.disable_developer_option,
                      style: Styles.body2Bold
                          .merge(const TextStyle(color: MyColors.warningText))),
                const SizedBox(
                  height: 40,
                ),
                GestureDetector(
                    onTap: appModel.isNetworkOn == false &&
                            appModel.isBluetoothOn == false &&
                            (!Platform.isAndroid ||
                                appModel.isDeveloperModeOn == false)
                        ? () async {
                            await appModel.setHasSeenGuide();
                            widget.onComplete!();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (Route<dynamic> route) => false,
                            );
                          }
                        : null,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: appModel.isNetworkOn == false &&
                                    appModel.isBluetoothOn == false &&
                                    (!Platform.isAndroid ||
                                        appModel.isDeveloperModeOn == false)
                                ? MyColors.black
                                : MyColors.transparentBlack_06),
                        child: Text(
                          t.start,
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
