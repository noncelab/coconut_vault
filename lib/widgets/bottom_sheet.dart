import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';

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
        backgroundColor: CoconutColors.white,
        isDismissible: isDismissible,
        isScrollControlled: true,
        enableDrag: enableDrag,
        useSafeArea: true,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9));
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
        backgroundColor: CoconutColors.white,
        isDismissible: isDismissible,
        isScrollControlled: true,
        enableDrag: enableDrag,
        useSafeArea: true,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95));
  }

  static void showBottomSheet_50(
      {required BuildContext context,
      required Widget child,
      bool isDismissible = true,
      bool enableDrag = true}) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return child;
        },
        backgroundColor: CoconutColors.white,
        isDismissible: isDismissible,
        isScrollControlled: true,
        enableDrag: enableDrag,
        useSafeArea: true,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5));
  }

  static void showBottomSheet({
    required String title,
    required BuildContext context,
    required Widget child,
    TextStyle? titleTextStyle,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isCloseButton = false,
    EdgeInsetsGeometry titlePadding = const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                              ? const Icon(Icons.close_rounded, color: CoconutColors.black)
                              : Container(width: 16),
                        ),
                      ),
                      Text(
                        title,
                        style: titleTextStyle ?? CoconutTypography.body2_14_Bold,
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
      backgroundColor: CoconutColors.white,
      isDismissible: isDismissible,
      isScrollControlled: true,
      enableDrag: enableDrag,
      useSafeArea: true,
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
                    topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                child: Column(
                  children: [
                    if (topWidget && isButtonActiveNotifier != null)
                      ValueListenableBuilder<bool>(
                        valueListenable: isButtonActiveNotifier,
                        builder: (context, isActive, _) {
                          return CoconutAppBar.build(
                            context: context,
                            title: t.key_list, // fixme: 특정 화면 컨텍스트를 포함하고 있음
                            backgroundColor: CoconutColors.white,
                            onBackPressed: () => Navigator.pop(context),
                            actionButtonList: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: GestureDetector(
                                  onTap: isButtonActiveNotifier.value
                                      ? () {
                                          if (onTopWidgetButtonClicked != null) {
                                            onTopWidgetButtonClicked();
                                          }
                                          Navigator.pop(context);
                                        }
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: isButtonActiveNotifier.value
                                            ? Colors.transparent
                                            : CoconutColors.black.withOpacity(0.06),
                                      ),
                                      color: isButtonActiveNotifier.value
                                          ? CoconutColors.gray800
                                          : CoconutColors.gray150,
                                    ),
                                    child: Center(
                                      child: Text(
                                        t.select,
                                        style: CoconutTypography.body2_14.merge(
                                          TextStyle(
                                            fontSize: 11,
                                            color: isButtonActiveNotifier.value
                                                ? Colors.white
                                                : CoconutColors.black.withOpacity(0.3),
                                            fontWeight: isButtonActiveNotifier.value
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else if (topWidget)
                      CoconutAppBar.build(
                        isBottom: true,
                        context: context,
                        title: t.import,
                        backgroundColor: CoconutColors.white,
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
                        color: CoconutColors.white,
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9));
  }
}
