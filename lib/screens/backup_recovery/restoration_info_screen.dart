import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';

class RestorationInfoScreen extends StatefulWidget {
  const RestorationInfoScreen({super.key});

  @override
  State<RestorationInfoScreen> createState() => _RestorationInfoScreenState();
}

class _RestorationInfoScreenState extends State<RestorationInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            backgroundColor: CoconutColors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoconutLayout.defaultPadding,
                ),
                child: Stack(children: [
                  Center(
                    child: Column(
                      children: [
                        CoconutLayout.spacing_2500h,
                        Text(
                          t.restoration_info.found_title,
                          style: CoconutTypography.heading4_18_Bold,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            t.restoration_info.found_description,
                            style: CoconutTypography.body2_14,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: CoconutButton(
                      disabledBackgroundColor: CoconutColors.gray400,
                      width: double.infinity,
                      text: t.restore,
                      onPressed: () {
                        Navigator.pushNamed(
                            context, AppRoutes.vaultListRestoration);
                      },
                    ),
                  ),
                ]),
              ),
            )));
  }
}
