import 'dart:ui';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/label_testnet.dart';

class FrostedAppBar extends StatefulWidget {
  final bool showPlusButton;
  final VoidCallback onTapPlus;
  final VoidCallback onTapSeeMore;
  final GlobalKey? dropdownKey;
  const FrostedAppBar(
      {super.key,
      required this.onTapPlus,
      required this.onTapSeeMore,
      this.dropdownKey,
      required this.showPlusButton});

  @override
  State<FrostedAppBar> createState() => _FrostedAppBarState();
}

class _FrostedAppBarState extends State<FrostedAppBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 상태바 배경
        statusBarBrightness: Brightness.light, // 상태바 아이콘 (iOS)
        statusBarIconBrightness: Brightness.dark, // 상태바 아이콘 (Android)
      ),
      backgroundColor: Colors.transparent,
      pinned: true,
      stretch: false,
      expandedHeight: 84,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: SvgPicture.asset(
                            'assets/svg/coconut-${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.svg',
                            colorFilter: const ColorFilter.mode(MyColors.darkgrey, BlendMode.srcIn),
                            width: 24)),
                    Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Row(
                            children: [
                              const Text('Vault',
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    color: MyColors.darkgrey,
                                    fontSize: 22,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w800,
                                  )),
                              const SizedBox(
                                width: 10,
                              ),
                              if (NetworkType.currentNetworkType.isTestnet)
                                const TestnetLabelWidget(),
                            ],
                          )),
                    ),
                    if (widget.showPlusButton)
                      Container(
                        margin: const EdgeInsets.only(top: 32),
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset(
                            'assets/svg/wallet-plus.svg',
                            colorFilter: const ColorFilter.mode(
                              CoconutColors.gray800,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: widget.onTapPlus,
                          color: MyColors.white,
                        ),
                      ),
                    Container(
                      key: widget.dropdownKey,
                      margin: const EdgeInsets.only(top: 32),
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/svg/kebab.svg',
                          colorFilter:
                              const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
                        ),
                        color: CoconutColors.gray800,
                        onPressed: () => widget.onTapSeeMore.call(),
                      ),
                    )
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
