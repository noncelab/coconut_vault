import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          name: t.vault_creation_options_screen.coin_flip,
          path: AppRoutes.securitySelfCheck,
          onNextPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.mnemonicCoinflip);
          }),
      Option(
          name: t.vault_creation_options_screen.auto_generate,
          path: AppRoutes.securitySelfCheck,
          onNextPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.mnemonicGeneration);
          }),
      Option(name: t.vault_creation_options_screen.import_mnemonic, path: AppRoutes.mnemonicImport),
    ];

    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.single_sig_wallet,
        context: context,
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
                            defaultColor: CoconutColors.gray150,
                            pressedColor: CoconutColors.gray500.withOpacity(0.1),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
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
                                              color: CoconutColors.black,
                                              letterSpacing: 0.2),
                                        )),
                                    const Spacer(),
                                    SvgPicture.asset('assets/svg/curved-arrow-right.svg', width: 24)
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
