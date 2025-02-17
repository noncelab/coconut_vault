import 'dart:ui';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/label_testnet.dart';
import 'package:provider/provider.dart';

class FrostedAppBar extends StatefulWidget {
  final Function onTapSeeMore;
  const FrostedAppBar({super.key, required this.onTapSeeMore});

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
                        child: SvgPicture.asset('assets/svg/coconut.svg',
                            colorFilter: const ColorFilter.mode(
                                MyColors.darkgrey, BlendMode.srcIn),
                            width: 24)),
                    const Expanded(
                      child: Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 4),
                          child: Row(
                            children: [
                              Text('Vault',
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    color: MyColors.darkgrey,
                                    fontSize: 22,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w800,
                                  )),
                              SizedBox(
                                width: 10,
                              ),
                              TestnetLabelWidget(),
                            ],
                          )),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 32),
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/svg/book.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                              MyColors.darkgrey, BlendMode.srcIn),
                        ),
                        onPressed: () {
                          MyBottomSheet.showBottomSheet_90(
                            context: context,
                            child: const TutorialScreen(
                              screenStatus: TutorialScreenStatus.modal,
                            ),
                          );
                        },
                        color: MyColors.darkgrey,
                      ),
                    ),
                    Selector<AppModel, bool>(
                      selector: (context, model) => model.isPinEnabled,
                      builder: (context, isPinEnabled, child) {
                        return Selector<AppModel, int>(
                          selector: (context, model) => model.vaultListLength,
                          builder: (context, vaultListLength, child) {
                            final isNotEmptyVaultList = vaultListLength > 0;
                            return Container(
                              margin: const EdgeInsets.only(top: 32),
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: MyColors.darkgrey,
                                ),
                                onPressed: () {
                                  if (!isNotEmptyVaultList && !isPinEnabled) {
                                    MyBottomSheet.showBottomSheet_90(
                                        context: context,
                                        child: const PinSettingScreen(
                                            greetingVisible: true));
                                  } else {
                                    Navigator.pushNamed(
                                        context, AppRoutes.vaultTypeSelection);
                                  }
                                },
                                color: MyColors.white,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 32),
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(CupertinoIcons.ellipsis, size: 18),
                        onPressed: () {
                          widget.onTapSeeMore.call();
                        },
                        color: MyColors.darkgrey,
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
