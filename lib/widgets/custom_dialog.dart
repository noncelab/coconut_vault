import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:coconut_vault/styles.dart';

class CustomDialogs {
  static void showCustomAlertDialog(BuildContext context,
      {required String title,
      required VoidCallback onConfirm,
      VoidCallback? onCancel,
      String confirmButtonText = '확인',
      String cancelButtonText = '취소',
      String message = '',
      Text? textWidget,
      Color confirmButtonColor = MyColors.white}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(title, style: Styles.body1Bold),
            ),
            content: textWidget ??
                Text(
                  message,
                  style: Styles.body2,
                  textAlign: TextAlign.center,
                ),
            actions: [
              CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: onCancel,
                  child: Text(cancelButtonText, style: Styles.label)),
              CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: onConfirm,
                  child: Text(confirmButtonText,
                      style: Styles.label
                          .merge(TextStyle(color: confirmButtonColor)))),
            ]);
      },
    );
  }

  static void showFullScreenDialog(
      BuildContext context, String title, Widget body) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) {
        return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
                title: Text(title),
                centerTitle: true,
                backgroundColor: MyColors.black,
                titleTextStyle: Styles.h3.merge(
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
                toolbarTextStyle: Styles.h3,
                actions: [
                  IconButton(
                    color: MyColors.white,
                    focusColor: MyColors.transparentGrey,
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ]),
            body: SafeArea(
                child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                padding: Paddings.container,
                color: MyColors.black,
                child: Column(
                  children: [body],
                ),
              ),
            )));
      },
    ));
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
