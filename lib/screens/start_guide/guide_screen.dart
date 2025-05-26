import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:provider/provider.dart';

class GuideScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const GuideScreen({super.key, required this.onComplete});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(builder: (context, provider, child) {
      return Scaffold(
        backgroundColor: CoconutColors.white,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t.guide_screen.network_status, style: Styles.body2Bold),
                            const SizedBox(width: 40),
                            provider.isNetworkOn != null && provider.isNetworkOn == true
                                ? HighLightedText(
                                    t.guide_screen.on,
                                    color: CoconutColors.warningText,
                                  )
                                : Text(t.guide_screen.off, style: Styles.subLabel)
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t.guide_screen.bluetooth_status, style: Styles.body2Bold),
                            const SizedBox(width: 40),
                            provider.isBluetoothOn != null && provider.isBluetoothOn == true
                                ? HighLightedText(
                                    t.guide_screen.on,
                                    color: CoconutColors.warningText,
                                  )
                                : Text(t.guide_screen.off, style: Styles.subLabel)
                          ],
                        ),
                        if (Platform.isAndroid) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.guide_screen.developer_option, style: Styles.body2Bold),
                              const SizedBox(width: 40),
                              provider.isDeveloperModeOn != null &&
                                      provider.isDeveloperModeOn == true
                                  ? HighLightedText(
                                      t.guide_screen.on,
                                      color: CoconutColors.warningText,
                                    )
                                  : Text(t.guide_screen.off, style: Styles.subLabel)
                            ],
                          ),
                        ]
                      ],
                    )),
                const SizedBox(height: 32),
                if (provider.isNetworkOn == true || provider.isBluetoothOn == true)
                  Column(
                    children: [
                      Text(
                        t.guide_screen.turn_off_network_and_bluetooth,
                        style: Styles.body2Bold.merge(
                          const TextStyle(
                            color: CoconutColors.warningText,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (provider.isDeveloperModeOn == true && Platform.isAndroid)
                  Text(
                    t.guide_screen.disable_developer_option,
                    style: Styles.body2Bold.merge(
                      const TextStyle(
                        color: CoconutColors.warningText,
                      ),
                    ),
                  ),
                const SizedBox(
                  height: 40,
                ),
                GestureDetector(
                    onTap: provider.isNetworkOn == false &&
                            provider.isBluetoothOn == false &&
                            (!Platform.isAndroid || provider.isDeveloperModeOn == false)
                        ? () async {
                            await Provider.of<VisibilityProvider>(context, listen: false)
                                .setHasSeenGuide();
                            widget.onComplete();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (Route<dynamic> route) => false,
                            );
                          }
                        : null,
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: provider.isNetworkOn == false &&
                                    provider.isBluetoothOn == false &&
                                    (!Platform.isAndroid || provider.isDeveloperModeOn == false)
                                ? CoconutColors.black
                                : CoconutColors.black.withOpacity(0.06)),
                        child: Text(
                          t.start,
                          style: Styles.label.merge(const TextStyle(color: CoconutColors.white)),
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
