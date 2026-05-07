import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';

class AssignablePillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isAssigned;
  final Widget? iconWidget;
  final String text;
  final Color activeColor;
  final double? width;
  final double? height;

  const AssignablePillButton({
    super.key,
    this.onPressed,
    required this.isAssigned,
    this.iconWidget,
    required this.text,
    required this.activeColor,
    this.width,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    final innerChild = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null) ...[iconWidget!, CoconutLayout.spacing_300w],
          Flexible(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(
                text,
                style: CoconutTypography.body1_16,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) {
      return Container(
        decoration: BoxDecoration(
          color: isAssigned ? activeColor.withAlpha(16) : CoconutColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isAssigned ? activeColor : CoconutColors.gray200, width: 1),
        ),
        child: innerChild,
      );
    }

    return ShrinkAnimationButton(
      onPressed: onPressed!,
      defaultColor: isAssigned ? activeColor.withAlpha(16) : CoconutColors.white,
      pressedColor: isAssigned ? activeColor.withAlpha(70) : CoconutColors.gray150,
      borderRadius: 100,
      borderWidth: 1,
      border: Border.all(color: isAssigned ? activeColor : CoconutColors.gray200, width: 1),
      child: innerChild,
    );
  }
}
