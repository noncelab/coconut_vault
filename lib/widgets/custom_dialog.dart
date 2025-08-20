import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomDialogs {
  static void showCustomAlertDialog(BuildContext context,
      {required String title,
      required VoidCallback onConfirm,
      VoidCallback? onCancel,
      String confirmButtonText = '확인',
      String cancelButtonText = '취소',
      String message = '',
      bool isSingleButton = false,
      bool barrierDismissible = true,
      Text? textWidget,
      Color confirmButtonColor = CoconutColors.white}) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(title, style: CoconutTypography.body1_16_Bold),
          ),
          content: textWidget ??
              Text(
                message,
                style: CoconutTypography.body2_14,
                textAlign: TextAlign.center,
              ),
          actions: [
            if (!isSingleButton)
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: onCancel,
                child: Text(cancelButtonText,
                    style: CoconutTypography.body2_14.merge(
                      TextStyle(
                        color: CoconutColors.black.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    )),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: onConfirm,
              child: Text(
                confirmButtonText,
                style: CoconutTypography.body2_14.merge(
                  TextStyle(
                    color: confirmButtonColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showLoadingDialog(
    BuildContext context,
    String text,
  ) {
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    CoconutLayout.spacing_800h,
                    SizedBox(
                      width: 70,
                      child: Lottie.asset(
                        'assets/lottie/loading-gray.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    CoconutLayout.spacing_500h,
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                            textAlign: TextAlign.center, text, style: CoconutTypography.body2_14)),
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
