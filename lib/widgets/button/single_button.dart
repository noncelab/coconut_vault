import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';

enum SingleButtonPosition { none, top, middle, bottom }

extension SingleButtonBorderRadiusExtension on SingleButtonPosition {
  BorderRadius get radius {
    switch (this) {
      case SingleButtonPosition.none:
        return BorderRadius.circular(Sizes.size24);
      case SingleButtonPosition.top:
        return const BorderRadius.vertical(top: Radius.circular(Sizes.size24));
      case SingleButtonPosition.middle:
        return BorderRadius.zero;
      case SingleButtonPosition.bottom:
        return const BorderRadius.vertical(bottom: Radius.circular(Sizes.size24));
    }
  }

  EdgeInsets get padding {
    switch (this) {
      case SingleButtonPosition.none:
        return const EdgeInsets.symmetric(horizontal: Sizes.size20, vertical: Sizes.size24);
      case SingleButtonPosition.top:
        return const EdgeInsets.only(left: Sizes.size20, right: Sizes.size20, top: Sizes.size24, bottom: Sizes.size20);
      case SingleButtonPosition.middle:
        return const EdgeInsets.all(Sizes.size20);
      case SingleButtonPosition.bottom:
        return const EdgeInsets.only(left: Sizes.size20, right: Sizes.size20, top: Sizes.size20, bottom: Sizes.size24);
    }
  }
}

class SingleButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onPressed;
  final Widget? rightElement;
  final Widget? leftElement;
  final SingleButtonPosition buttonPosition;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool enableShrinkAnim;
  final double animationEndValue;

  const SingleButton({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.onPressed,
    this.rightElement,
    this.leftElement,
    this.buttonPosition = SingleButtonPosition.none,
    this.enableShrinkAnim = false,
    this.animationEndValue = 0.95,
    this.subtitleStyle,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = _buildButtonContent(context);

    return enableShrinkAnim
        ? ShrinkAnimationButton(
          onPressed: onPressed ?? () {},
          defaultColor: CoconutColors.gray200,
          pressedColor: CoconutColors.gray300,
          borderRadius: 24,
          animationEndValue: animationEndValue,
          child: Container(
            decoration: BoxDecoration(borderRadius: buttonPosition.radius),
            padding: buttonPosition.padding,
            child: buttonContent,
          ),
        )
        : GestureDetector(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(color: CoconutColors.gray200, borderRadius: buttonPosition.radius),
            padding: buttonPosition.padding,
            child: buttonContent,
          ),
        );
  }

  Widget _buildButtonContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leftElement != null) ...{Container(child: leftElement), CoconutLayout.spacing_400w},
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: titleStyle ?? CoconutTypography.body2_14_Bold.setColor(CoconutColors.black),
                    ),
                  ),
                ],
              ),
            ),
            if (subtitle != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle!,
                    style: subtitleStyle ?? CoconutTypography.body3_12_Number.setColor(CoconutColors.gray600),
                  ),
                ),
              ),
            rightElement ?? _rightArrow(),
          ],
        ),
        if (description != null)
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Text(description!, style: CoconutTypography.body3_12_Number.setColor(CoconutColors.gray600)),
          ),
      ],
    );
  }

  Widget _rightArrow() => Icon(Icons.keyboard_arrow_right_rounded, color: CoconutColors.black.withValues(alpha: 0.5));
}
