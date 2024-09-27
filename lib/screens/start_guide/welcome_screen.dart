import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: MyColors.white,
        body: SafeArea(
            child: Center(
                child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/coconut-security.svg',
              width: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              "원활한 코코넛 볼트 사용을 위해\n잠깐만 시간을 내주세요",
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
                      colorFilter: const ColorFilter.mode(
                          MyColors.darkgrey, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 20),
                    const Text('볼트는', style: Styles.subLabel),
                    HighLightedText(
                        '네트워크, 블루투스 연결${Platform.isAndroid ? ', 개발자 옵션이 ' : '이 '}',
                        color: MyColors.darkgrey),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HighLightedText('꺼져있는 상태', color: MyColors.darkgrey),
                        Text('에서만', style: Styles.subLabel),
                      ],
                    ),
                    const Text('사용하실 수 있어요', style: Styles.subLabel),
                  ],
                ),
                // Guide2
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/number/two.svg',
                      width: 20,
                      colorFilter: const ColorFilter.mode(
                          MyColors.darkgrey, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 20),
                    const Text('즉,', style: Styles.subLabel),
                    const Text('연결이 감지되면', style: Styles.subLabel),
                    const HighLightedText('앱을 사용하실 수 없게',
                        color: MyColors.darkgrey),
                    const Text('설계되어 있어요', style: Styles.subLabel),
                  ],
                ),
                // Guide3
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/number/three.svg',
                      width: 20,
                      colorFilter: const ColorFilter.mode(
                          MyColors.darkgrey, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HighLightedText('안전한 사용', color: MyColors.darkgrey),
                        Text('을 위한', style: Styles.subLabel),
                      ],
                    ),
                    const Text('조치이오니', style: Styles.subLabel),
                    const Text('사용 시 유의해 주세요', style: Styles.subLabel),
                  ],
                ),
              ].map((item) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 10),
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: MyColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.18),
                        spreadRadius: 4,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0), child: item),
                );
              }).toList(),
            ),
            const SizedBox(
              height: 20,
            ),
            CupertinoButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/connectivity-guide'),
                child: Text(
                  '모두 이해했어요 :)',
                  style: Styles.label.merge(const TextStyle(
                      color: MyColors.secondary, fontWeight: FontWeight.bold)),
                )),
            const SizedBox(
              height: 60,
            ),
          ],
        ))));
  }
}
