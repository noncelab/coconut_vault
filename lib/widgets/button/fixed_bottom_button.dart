import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class FixedBottomButton extends StatefulWidget {
  static const fixedBottomButtonDefaultHeight = 50.0;
  static const fixedBottomButtonDefaultBottomPadding = 30.0;

  const FixedBottomButton({
    super.key,
    required this.onButtonClicked,
    required this.text,
    this.showGradient = true,
    this.isVisibleAboveKeyboard = true,
    this.isActive = true,
    this.buttonHeight,
    this.horizontalPadding = CoconutLayout.defaultPadding,
    this.bottomPadding = FixedBottomButton.fixedBottomButtonDefaultBottomPadding,
    this.gradientPadding,
    this.subWidget,
    this.backgroundColor = CoconutColors.primary,
    this.textColor = CoconutColors.white,
    this.pressedBackgroundColor,
  });

  final Function onButtonClicked;
  final String text;
  final bool showGradient;
  final bool isVisibleAboveKeyboard;
  final bool isActive;
  final double? buttonHeight;
  final double horizontalPadding;
  final double bottomPadding;
  final EdgeInsets? gradientPadding;
  final Widget? subWidget;
  final Color backgroundColor;
  final Color textColor;
  final Color? pressedBackgroundColor;

  @override
  State<FixedBottomButton> createState() => _FixedBottomButtonState();
}

class _FixedBottomButtonState extends State<FixedBottomButton> {
  @override
  Widget build(BuildContext context) {
    double keyboardHeight =
        (widget.isVisibleAboveKeyboard ? MediaQuery.of(context).viewInsets.bottom : 0);
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
                  padding: widget.gradientPadding ??
                      const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 150),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CoconutColors.gray100.withOpacity(0.1),
                        CoconutColors.white,
                      ],
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
                CoconutButton(
                  onPressed: () {
                    widget.onButtonClicked();
                  },
                  width: MediaQuery.sizeOf(context).width,
                  disabledBackgroundColor: CoconutColors.gray400,
                  disabledForegroundColor: CoconutColors.gray600,
                  isActive: widget.isActive,
                  height: widget.buttonHeight ?? FixedBottomButton.fixedBottomButtonDefaultHeight,
                  backgroundColor: widget.backgroundColor,
                  foregroundColor: widget.textColor,
                  pressedTextColor: widget.textColor,
                  text: widget.text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
