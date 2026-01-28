import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomDialogs {
  static void showLoadingDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                child: Column(
                  children: [
                    CoconutLayout.spacing_800h,
                    SizedBox(width: 70, child: Lottie.asset('assets/lottie/loading-gray.json', fit: BoxFit.contain)),
                    CoconutLayout.spacing_500h,
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: MediaQuery(
                        data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
                        child: Text(textAlign: TextAlign.center, text, style: CoconutTypography.body2_14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showConfirmDialog(
  BuildContext context,
  String languageCode,
  String title,
  String description, {
  String? leftButtonText,
  String? rightButtonText,
  Function? onTapLeft,
  Function? onTapRight,
  bool barrierDismissible = true,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return CoconutPopup(
        languageCode: languageCode,
        title: title,
        backgroundColor: CoconutColors.white.withOpacity(0.7),
        description: description,
        descriptionPadding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
        insetPadding: const EdgeInsets.symmetric(horizontal: 50),
        leftButtonText: leftButtonText ?? t.cancel,
        leftButtonColor: CoconutColors.black,
        rightButtonText: rightButtonText ?? t.OK,
        rightButtonColor: CoconutColors.black,
        onTapLeft:
            onTapLeft ??
            () {
              Navigator.pop(context);
            },
        onTapRight:
            onTapRight ??
            () {
              Navigator.pop(context);
            },
      );
    },
  );
}
