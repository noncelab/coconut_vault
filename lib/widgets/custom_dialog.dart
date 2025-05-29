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
            ]);
      },
    );
  }

  static void showLoadingDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부를 터치해도 닫히지 않게 설정
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(100),
            child: Stack(
              children: [
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Lottie.asset(
                    'assets/lottie/loading-coconut.json',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
