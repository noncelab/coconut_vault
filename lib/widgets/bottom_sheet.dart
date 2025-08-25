import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';

class MyBottomSheet {
  static Future<T?> showBottomSheet_90<T>(
      {required BuildContext context,
      required Widget child,
      bool isDismissible = true,
      bool enableDrag = true}) async {
    return showModalBottomSheet<T>(
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

  static Future<T?> showBottomSheet_50<T>(
      {required BuildContext context,
      required Widget child,
      bool isDismissible = true,
      bool enableDrag = true}) async {
    return await showModalBottomSheet<T>(
        context: context,
        builder: (context) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width,
                child: child,
              ),
            ),
          );
        },
        backgroundColor: CoconutColors.white,
        isDismissible: isDismissible,
        isScrollControlled: true,
        enableDrag: enableDrag,
        useSafeArea: true);
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

  static Future<T?> showDraggableBottomSheet<T>(
      {required BuildContext context,
      required Widget Function(ScrollController) childBuilder,
      double minChildSize = 0.5,
      double maxChildSize = 0.9}) async {
    final draggableController = DraggableScrollableController();
    bool isAnimating = false;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CoconutColors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          controller: draggableController,
          initialChildSize: minChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (context, scrollController) {
            void handleDrag() {
              if (isAnimating) return;
              final extent = draggableController.size;
              final targetExtent = (extent - minChildSize).abs() < (extent - maxChildSize).abs()
                  ? minChildSize + 0.01
                  : maxChildSize;

              isAnimating = true;
              draggableController
                  .animateTo(
                targetExtent,
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeOut,
              )
                  .whenComplete(() {
                isAnimating = false;
              });
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  handleDrag();
                  return true;
                }
                return false;
              },
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      final delta = -details.primaryDelta! / MediaQuery.of(context).size.height;
                      draggableController.jumpTo(draggableController.size + delta);
                    },
                    onVerticalDragEnd: (details) {
                      handleDrag();
                    },
                    onVerticalDragCancel: () {
                      handleDrag();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Container(
                          width: 55,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CoconutColors.gray400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      child: Padding(
                          padding:
                              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: childBuilder(scrollController)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
