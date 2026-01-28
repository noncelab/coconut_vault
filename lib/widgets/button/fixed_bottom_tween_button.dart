import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';

class FixedBottomTweenButton extends StatefulWidget {
  static const fixedBottomButtonDefaultHeight = 50.0;
  static const fixedBottomButtonDefaultBottomPadding = 16.0;

  const FixedBottomTweenButton({
    super.key,
    required this.leftButtonClicked,
    required this.rightButtonClicked,
    required this.leftText,
    required this.rightText,
    this.leftButtonRatio = 0.5, // 왼쪽 버튼이 차지하는 비율 (0.0 ~ 1.0)
    this.showGradient = true,
    this.isVisibleAboveKeyboard = true,
    this.isLeftButtonActive = true,
    this.isRightButtonActive = true,
    this.buttonHeight,
    this.horizontalPadding = CoconutLayout.defaultPadding,
    this.bottomPadding = FixedBottomTweenButton.fixedBottomButtonDefaultBottomPadding,
    this.gradientPadding,
    this.subWidget,
    this.leftButtonBackgroundColor = CoconutColors.gray200,
    this.rightButtonBackgroundColor = CoconutColors.black,
    this.leftButtonBorderColor = CoconutColors.gray200,
    this.rightButtonBorderColor = CoconutColors.black,
    this.leftButtonTextColor = CoconutColors.black,
    this.rightButtonTextColor = CoconutColors.white,
    this.buttonSpacing = 8.0, // 두 버튼 사이의 간격
  });

  final Function leftButtonClicked;
  final Function rightButtonClicked;
  final String leftText;
  final String rightText;
  final double leftButtonRatio;
  final bool showGradient;
  final bool isVisibleAboveKeyboard;
  final bool isLeftButtonActive;
  final bool isRightButtonActive;
  final double? buttonHeight;
  final double horizontalPadding;
  final double bottomPadding;
  final EdgeInsets? gradientPadding;
  final Widget? subWidget;
  final Color leftButtonBackgroundColor;
  final Color rightButtonBackgroundColor;
  final Color leftButtonBorderColor;
  final Color rightButtonBorderColor;
  final Color leftButtonTextColor;
  final Color rightButtonTextColor;
  final double buttonSpacing;

  @override
  State<FixedBottomTweenButton> createState() => _FixedBottomTweenButtonState();
}

class _FixedBottomTweenButtonState extends State<FixedBottomTweenButton> {
  @override
  Widget build(BuildContext context) {
    double keyboardHeight = (widget.isVisibleAboveKeyboard ? MediaQuery.of(context).viewInsets.bottom : 0);

    // 전체 너비에서 패딩과 버튼 간격을 제외한 실제 버튼 영역
    final totalWidth = MediaQuery.sizeOf(context).width - (widget.horizontalPadding * 2) - widget.buttonSpacing;
    final leftButtonWidth = totalWidth * widget.leftButtonRatio;
    final rightButtonWidth = totalWidth * (1 - widget.leftButtonRatio);

    double buttonHeight =
        widget.buttonHeight ??
        (Platform.isAndroid
            ? FixedBottomButton.fixedBottomButtonDefaultHeight
            : FixedBottomButton.fixedBottomButtonDefaultHeight + 8);

    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Stack(
        children: [
          if (widget.showGradient)
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboardHeight,
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  padding: widget.gradientPadding ?? const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 150),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [CoconutColors.gray100.withValues(alpha: 0.1), CoconutColors.white],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: widget.horizontalPadding,
            right: widget.horizontalPadding,
            bottom: keyboardHeight + widget.bottomPadding,
            child: Column(
              children: [
                widget.subWidget ?? Container(),
                CoconutLayout.spacing_300h,
                Row(
                  children: [
                    // 왼쪽 버튼
                    SizedBox(
                      width: leftButtonWidth,
                      child: CoconutButton(
                        onPressed: () {
                          widget.leftButtonClicked();
                        },
                        disabledBackgroundColor: CoconutColors.gray150,
                        disabledForegroundColor: CoconutColors.gray350,
                        isActive: widget.isLeftButtonActive,
                        height: buttonHeight,
                        backgroundColor: widget.leftButtonBackgroundColor,
                        foregroundColor: widget.leftButtonTextColor,
                        pressedTextColor: widget.leftButtonTextColor,
                        borderColor: widget.leftButtonBorderColor,
                        text: widget.leftText,
                        textStyle: CoconutTypography.body1_16_Bold,
                        pressedBackgroundColor: CoconutColors.gray200,
                      ),
                    ),
                    SizedBox(width: widget.buttonSpacing),
                    // 오른쪽 버튼
                    SizedBox(
                      width: rightButtonWidth,
                      child: CoconutButton(
                        onPressed: () {
                          widget.rightButtonClicked();
                        },
                        disabledBackgroundColor: CoconutColors.gray150,
                        disabledForegroundColor: CoconutColors.gray350,
                        isActive: widget.isRightButtonActive,
                        height: buttonHeight,
                        backgroundColor: widget.rightButtonBackgroundColor,
                        foregroundColor: widget.rightButtonTextColor,
                        pressedTextColor: widget.rightButtonTextColor,
                        borderColor: widget.rightButtonBorderColor,
                        text: widget.rightText,
                        textStyle: CoconutTypography.body1_16_Bold,
                        pressedBackgroundColor: CoconutColors.gray200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
