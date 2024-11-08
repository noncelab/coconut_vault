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

  static void showBottomSheet({
    required String title,
    required BuildContext context,
    required Widget child,
    TextStyle titleTextStyle = Styles.body2Bold,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isCloseButton = false,
    EdgeInsetsGeometry titlePadding =
        const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
  }) {
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: isCloseButton
                            ? () {
                                Navigator.pop(context);
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.transparent,
                          child: isCloseButton
                              ? const Icon(Icons.close_rounded,
                                  color: MyColors.black)
                              : Container(width: 16),
                        ),
                      ),
                      Text(
                        title,
                        style: titleTextStyle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        child: Container(width: 16),
                      ),
                    ],
                  ),
                ),
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
