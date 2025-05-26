import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late ConnectivityProvider _connectivityProvider;

  @override
  void initState() {
    super.initState();
    _connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CoconutColors.white,
        body: SafeArea(
            child: Center(
                child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/coconut-security-${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.svg',
              width: 80,
            ),
            const SizedBox(height: 20),
            Text(
              t.welcome_screen.greeting,
              style: Styles.body2Bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 24,
            ),
            CarouselSlider(
              options: CarouselOptions(
                aspectRatio: 16 / 12,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 10),
                enlargeCenterPage: true,
              ),
              items: [
                // Guide1
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/number/one.svg',
                      width: 20,
                      colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 20),
                    Text(t.welcome_screen.guide1_1, style: Styles.subLabel),
                    HighLightedText(
                        t.welcome_screen
                            .guide1_2(suffix: Platform.isAndroid ? ', ${t.developer_option}' : ''),
                        color: CoconutColors.gray800),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HighLightedText(t.welcome_screen.guide1_3, color: CoconutColors.gray800),
                        Text(t.welcome_screen.guide1_4, style: Styles.subLabel),
                      ],
                    ),
                    Text(t.welcome_screen.guide1_5, style: Styles.subLabel),
                  ],
                ),
                // Guide2
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/number/two.svg',
                      width: 20,
                      colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 20),
                    Text(t.welcome_screen.guide2_1, style: Styles.subLabel),
                    Text(t.welcome_screen.guide2_2, style: Styles.subLabel),
                    HighLightedText(t.welcome_screen.guide2_3, color: CoconutColors.gray800),
                    Text(t.welcome_screen.guide2_4, style: Styles.subLabel),
                  ],
                ),
                // Guide3
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/number/three.svg',
                      width: 20,
                      colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HighLightedText(t.welcome_screen.guide3_1, color: CoconutColors.gray800),
                        Text(t.welcome_screen.guide3_2, style: Styles.subLabel),
                      ],
                    ),
                    Text(t.welcome_screen.guide3_3, style: Styles.subLabel),
                    Text(t.welcome_screen.guide3_4, style: Styles.subLabel),
                  ],
                ),
              ].map((item) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: CoconutColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: CoconutColors.gray500.withOpacity(0.18),
                        spreadRadius: 4,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: item),
                );
              }).toList(),
            ),
            const SizedBox(
              height: 20,
            ),
            CupertinoButton(
                onPressed: () {
                  _connectivityProvider.setConnectActivity(
                      bluetooth: true, network: false, developerMode: false);
                  Navigator.pushNamed(context, AppRoutes.connectivityGuide);
                },
                child: Text(
                  t.welcome_screen.understood,
                  style: Styles.label.merge(const TextStyle(
                      color: Color.fromRGBO(113, 111, 245, 1.0), fontWeight: FontWeight.bold)),
                )),
            const SizedBox(
              height: 60,
            ),
          ],
        ))));
  }
}
