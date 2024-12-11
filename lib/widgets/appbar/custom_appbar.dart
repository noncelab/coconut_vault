import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/label_testnet.dart';

class CustomAppBar {
  ValueNotifier<bool> isButtonActiveNotifier = ValueNotifier<bool>(false);

  static AppBar build({
    required String title,
    required BuildContext context,
    required bool hasRightIcon,
    VoidCallback? onRightIconPressed,
    VoidCallback? onBackPressed,
    IconButton? rightIconButton,
    bool isBottom = false,
    Color? backgroundColor = MyColors.white,
    bool showTestnetLabel = true,
    bool? setSearchBar = false,
  }) {
    Widget? titleWidget = Column(
      children: [
        Text(title),
        showTestnetLabel
            ? const Column(
                children: [
                  SizedBox(
                    height: 3,
                  ),
                  TestnetLabelWidget(),
                ],
              )
            : Container(
                width: 1,
              ),
      ],
    );

    return AppBar(
        title: titleWidget,
        centerTitle: true,
        backgroundColor: backgroundColor,
        titleTextStyle:
            Styles.navHeader.merge(const TextStyle(color: MyColors.black)),
        toolbarTextStyle: Styles.appbarTitle,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: isBottom
                    ? const Icon(Icons.close_rounded)
                    : SvgPicture.asset('assets/svg/back.svg'),
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed();
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        actions: [
          if (hasRightIcon && rightIconButton == null)
            IconButton(
              color: MyColors.black,
              focusColor: MyColors.transparentGrey,
              icon: const Icon(CupertinoIcons.ellipsis_vertical, size: 22),
              onPressed: () {
                if (onRightIconPressed != null) {
                  onRightIconPressed();
                }
              },
            )
          else if (hasRightIcon && rightIconButton != null)
            rightIconButton
        ],
        flexibleSpace: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.transparent,
                ))));
  }

  static AppBar buildWithNext({
    required String title,
    required BuildContext context,
    required VoidCallback onNextPressed,
    VoidCallback? onBackPressed,
    bool hasBackdropFilter = true,
    bool isActive = true,
    bool isBottom = false,
    String buttonName = '다음',
    Color backgroundColor = MyColors.white,
  }) {
    return AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: backgroundColor,
        titleTextStyle:
            Styles.navHeader.merge(const TextStyle(color: MyColors.black)),
        toolbarTextStyle: Styles.appbarTitle,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: isBottom
                    ? const Icon(Icons.close_rounded, size: 22)
                    : SvgPicture.asset('assets/svg/back.svg'),
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed();
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: GestureDetector(
              onTap: isActive ? onNextPressed : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                      color: isActive
                          ? Colors.transparent
                          : MyColors.transparentBlack_06),
                  color: isActive ? MyColors.darkgrey : MyColors.lightgrey,
                ),
                child: Center(
                  child: Text(
                    buttonName,
                    style: Styles.label2.merge(
                      TextStyle(
                        color: isActive
                            ? Colors.white
                            : MyColors.transparentBlack_30,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        flexibleSpace: hasBackdropFilter
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              )
            : Container());
  }

  static AppBar buildWithSave(
      {required String title,
      required BuildContext context,
      required VoidCallback onPressedSave,
      bool isActive = true,
      bool isBottom = false}) {
    return AppBar(
        title: Text(
          title,
        ),
        centerTitle: true,
        backgroundColor: MyColors.white,
        titleTextStyle:
            Styles.navHeader.merge(const TextStyle(color: MyColors.black)),
        toolbarTextStyle: Styles.appbarTitle,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: isBottom
                    ? const Icon(Icons.close_rounded, size: 22)
                    : SvgPicture.asset('assets/svg/back.svg'),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
        actions: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: GestureDetector(
                  onTap: isActive ? onPressedSave : null,
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                            color: isActive
                                ? Colors.transparent
                                : MyColors.transparentBlack_06),
                        color:
                            isActive ? MyColors.darkgrey : MyColors.lightgrey,
                      ),
                      child: Center(
                          child: Text('저장',
                              style: Styles.subLabel.merge(TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : MyColors.transparentBlack_30,
                                  fontSize: 11)))))))
        ],
        flexibleSpace: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.transparent,
                ))));
  }

  static AppBar buildWithClose({
    required String title,
    required BuildContext context,
    Color? backgroundColor,
    VoidCallback? onBackPressed,
    bool hasNextButton = false,
    bool isNextButtonActive = false,
    String nextButtonText = '선택',
    VoidCallback? onNextPressed,
  }) {
    return AppBar(
      centerTitle: true,
      backgroundColor: backgroundColor ?? Colors.transparent,
      title: Text(title),
      titleTextStyle:
          Styles.navHeader.merge(const TextStyle(color: MyColors.black)),
      toolbarTextStyle: Styles.appbarTitle,
      leading: IconButton(
        onPressed: onBackPressed ??
            () {
              Navigator.pop(context);
            },
        icon: const Icon(
          Icons.close_rounded,
          color: MyColors.black,
          size: 22,
        ),
      ),
      actions: [
        if (hasNextButton && onNextPressed != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: GestureDetector(
              onTap: isNextButtonActive ? onNextPressed : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                      color: isNextButtonActive
                          ? Colors.transparent
                          : MyColors.transparentBlack_06),
                  color: isNextButtonActive
                      ? MyColors.darkgrey
                      : MyColors.lightgrey,
                ),
                child: Center(
                  child: Text(
                    nextButtonText,
                    style: Styles.label2.merge(
                      TextStyle(
                        color: isNextButtonActive
                            ? Colors.white
                            : MyColors.transparentBlack_30,
                        fontWeight: isNextButtonActive
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
  }
}
