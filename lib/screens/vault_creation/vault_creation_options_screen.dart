import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';

class Option {
  final String name;
  final String path;
  final VoidCallback? onNextPressed;

  Option({required this.name, required this.path, this.onNextPressed});
}

class VaultCreationOptions extends StatelessWidget {
  const VaultCreationOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Option> options = [
      Option(
          name: "동전을 던져 직접 만들게요",
          path: "/security-self-check",
          onNextPressed: () {
            Navigator.pushNamed(context, '/mnemonic-flip-coin');
          }),
      Option(
          name: "앱에서 만들어 주세요",
          path: "/security-self-check",
          onNextPressed: () {
            Navigator.pushNamed(context, '/mnemonic-generate');
          }),
      Option(name: "사용 중인 니모닉 문구가 있어요", path: "/mnemonic-import"),
    ];

    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
        title: '일반 지갑',
        context: context,
        hasRightIcon: false,
        showTestnetLabel: false,
      ),
      body: CustomScrollView(
        semanticChildCount: options.length,
        slivers: <Widget>[
          SliverSafeArea(
              top: false,
              minimum: const EdgeInsets.only(top: 8),
              sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, index) {
                      return Column(children: [
                        ShrinkAnimationButton(
                            defaultColor: MyColors.lightgrey,
                            pressedColor: MyColors.grey.withOpacity(0.1),
                            onPressed: () {
                              final option = options[index];
                              if (option.onNextPressed != null) {
                                Navigator.pushNamed(
                                  context,
                                  option.path,
                                  arguments: option.onNextPressed,
                                );
                              } else {
                                Navigator.pushNamed(context, option.path);
                              }
                            },
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 36.0),
                                child: Row(
                                  children: [
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          options[index].name,
                                          style: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                              color: MyColors.black,
                                              letterSpacing: 0.2),
                                        )),
                                    const Spacer(),
                                    SvgPicture.asset(
                                        'assets/svg/curved-arrow-right.svg',
                                        width: 24)
                                  ],
                                ))),
                        const SizedBox(height: 8.0)
                      ]);
                    }, childCount: options.length),
                  )))
        ],
      ),
    );
  }
}
