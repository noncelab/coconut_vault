import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class RestorationInfoScreen extends StatefulWidget {
  final Function onComplete;
  final Function onReset;
  const RestorationInfoScreen({super.key, required this.onComplete, required this.onReset});

  @override
  State<RestorationInfoScreen> createState() => _RestorationInfoScreenState();
}

class _RestorationInfoScreenState extends State<RestorationInfoScreen> {
  DateTime? _lastPressedAt;
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (Platform.isAndroid) {
            final now = DateTime.now();
            if (_lastPressedAt == null ||
                now.difference(_lastPressedAt!) > const Duration(seconds: 3)) {
              _lastPressedAt = now;
              Fluttertoast.showToast(
                backgroundColor: CoconutColors.gray800,
                msg: t.toast.back_exit,
                toastLength: Toast.LENGTH_SHORT,
              );
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
            backgroundColor: CoconutColors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoconutLayout.defaultPadding,
                ),
                child: Column(children: [
                  CoconutLayout.spacing_2500h,
                  Text(
                    t.restoration_info.found_title,
                    style: CoconutTypography.heading3_21_Bold,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      t.restoration_info.found_description,
                      style: CoconutTypography.body1_16,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  CoconutButton(
                    disabledBackgroundColor: CoconutColors.gray400,
                    width: double.infinity,
                    height: 52,
                    text: t.restore,
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      if (await authProvider.isBiometricsAuthValid()) {
                        widget.onComplete();
                        return;
                      }

                      if (context.mounted) {
                        MyBottomSheet.showBottomSheet_90(
                          context: context,
                          child: CustomLoadingOverlay(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(CoconutStyles.radius_200),
                                topRight: Radius.circular(CoconutStyles.radius_200),
                              ),
                              child: PinCheckScreen(
                                pinCheckContext: PinCheckContextEnum.restoration,
                                onSuccess: () async {
                                  widget.onComplete();
                                },
                                onReset: () async {
                                  widget.onReset();
                                },
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  CoconutLayout.spacing_500h
                ]),
              ),
            )));
  }
}
