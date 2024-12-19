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
            maxWidth: 480,
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
          maxWidth: 480,
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
      constraints: const BoxConstraints(
          maxWidth: 480)
    );
  }

  static Future<T?> showDraggableScrollableSheet<T>({
    required BuildContext context,
    Widget? child,
    Widget Function(ScrollController)? childBuilder,
    ValueNotifier<bool>? isButtonActiveNotifier,
    bool enableDrag = true,
    Color backgroundColor = Colors.transparent,
    bool isDismissible = true,
    bool isScrollControlled = true,
    DraggableScrollableController? controller,
    bool useSafeArea = true,
    bool expand = true,
    bool snap = true,
    double initialChildSize = 1,
    double maxChildSize = 1,
    double minChildSize = 0.95,
    double maxHeight = 0.9,
    bool topWidget = false,
    bool enableSingleChildScroll = true,
    ScrollPhysics? physics,
    VoidCallback? onTopWidgetButtonClicked,
    VoidCallback? onBackPressed,
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
            controller: controller,
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
                      )
                    else if (topWidget)
                      CustomAppBar.buildWithClose(
                        hasNextButton: true,
                        context: context,
                        title: '가져오기',
                        backgroundColor: MyColors.white,
                        onBackPressed: () {
                          if (onBackPressed != null) {
                            onBackPressed();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    Expanded(
                      child: Container(
                        color: MyColors.white,
                        child: enableSingleChildScroll
                            ? SingleChildScrollView(
                                physics: physics,
                                controller: controller,
                                child: childBuilder!(controller),
                              )
                            : child,
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
