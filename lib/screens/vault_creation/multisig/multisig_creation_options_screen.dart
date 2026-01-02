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

class MultisigCreationOptionsScreen extends StatelessWidget {
  const MultisigCreationOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Option> options = [
      Option(
        name: t.multisig_creation_options_screen.new_multisig,
        path: AppRoutes.multisigQuorumSelection,
        onNextPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.multisigQuorumSelection);
        },
      ),
      Option(
        name: t.multisig_creation_options_screen.import_bsms,
        path: AppRoutes.coordinatorBsmsConfigScanner,
        onNextPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.coordinatorBsmsConfigScanner);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(title: t.multisig_wallet, context: context),
      body: CustomScrollView(
        semanticChildCount: options.length,
        slivers: <Widget>[
          SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.only(top: 10),
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, index) {
                  return Column(
                    children: [
                      ShrinkAnimationButton(
                        defaultColor: CoconutColors.gray150,
                        pressedColor: CoconutColors.gray500.withValues(alpha: 0.1),
                        onPressed: () {
                          final option = options[index];
                          if (option.onNextPressed != null) {
                            Navigator.pushNamed(context, option.path, arguments: option.onNextPressed);
                          } else {
                            Navigator.pushNamed(context, option.path);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                          child: Row(
                            children: [
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    options[index].name,
                                    style: CoconutTypography.body1_16_Bold
                                        .setColor(CoconutColors.black)
                                        .copyWith(letterSpacing: 0.2),
                                  ),
                                ),
                              ),
                              CoconutLayout.spacing_100w,
                              SvgPicture.asset('assets/svg/chevron-right.svg'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  );
                }, childCount: options.length),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
