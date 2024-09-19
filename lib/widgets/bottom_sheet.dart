import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';

class MyBottomSheet {
  static void showBottomSheet_90(
      {required BuildContext context,
      required Widget child,
      bool isDismissible = true,
      bool enableDrag = true}) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return child;
        },
        backgroundColor: MyColors.white,
        isDismissible: isDismissible,
        isScrollControlled: true,
        enableDrag: enableDrag,
        useSafeArea: true,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9));
  }

  static void showBottomSheet_95(
      {required BuildContext context,
      required Widget child,
      bool isDismissible = true,
      bool enableDrag = true}) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return child;
        },
        backgroundColor: MyColors.white,
        isDismissible: isDismissible,
        isScrollControlled: true,
        enableDrag: enableDrag,
        useSafeArea: true,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.95));
  }

  static void showBottomSheet(
      {required String title,
      required BuildContext context,
      required Widget child,
      bool isDismissible = true,
      bool enableDrag = true,
      EdgeInsetsGeometry titlePadding =
          const EdgeInsets.symmetric(vertical: 20, horizontal: 20)}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      builder: (context) {
        return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Wrap(
              children: <Widget>[
                Padding(
                    padding: titlePadding,
                    child: Center(
                        child: Text(
                      title,
                      style: Styles.body2Bold,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ))),
                child
              ],
            ));
      },
      backgroundColor: MyColors.white,
      isDismissible: isDismissible,
      isScrollControlled: true,
      enableDrag: enableDrag,
      useSafeArea: true,
    );
  }
}
