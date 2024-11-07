import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
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

  static Future<T?> showDraggableScrollableSheet<T>({
    required BuildContext context,
    required Widget child,
    ValueNotifier<bool>? isButtonActiveNotifier,
    bool enableDrag = true,
    Color backgroundColor = Colors.transparent,
    bool isDismissible = true,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool expand = true,
    bool snap = true,
    double initialChildSize = 1,
    double maxChildSize = 1,
    double minChildSize = 0.9,
    double maxHeight = 0.9,
    bool topWidget = false,
    VoidCallback? onTopWidgetButtonClicked,
  }) async {
    return showModalBottomSheet<T>(
        context: context,
        builder: (context) {
          return DraggableScrollableSheet(
            expand: expand,
            snap: snap,
            initialChildSize: initialChildSize,
            maxChildSize: maxChildSize,
            minChildSize: minChildSize,
            builder: (_, controller) {
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
                child: Column(
                  children: [
                    if (topWidget && isButtonActiveNotifier != null)
                      ValueListenableBuilder<bool>(
                        valueListenable: isButtonActiveNotifier,
                        builder: (context, isActive, _) {
                          return CustomAppBar.buildWithClose(
                            hasNextButton: true,
                            context: context,
                            title: '키 목록',
                            backgroundColor: MyColors.white,
                            isNextButtonActive: isButtonActiveNotifier.value,
                            onBackPressed: () => Navigator.pop(context),
                            onNextPressed: () {
                              if (onTopWidgetButtonClicked != null) {
                                onTopWidgetButtonClicked();
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    Expanded(
                      child: Container(
                        color: MyColors.white,
                        child: SingleChildScrollView(
                          // physics: const ClampingScrollPhysics(),
                          controller: controller,
                          child: child,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: Colors.transparent,
        isDismissible: isDismissible,
        isScrollControlled: isScrollControlled,
        enableDrag: enableDrag,
        useSafeArea: useSafeArea,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9));
  }
}
