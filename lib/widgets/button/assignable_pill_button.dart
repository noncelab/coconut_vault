import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';

class AssignablePillButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isApproved;
  final Widget? iconWidget;
  final String text;
  final Color activeColor;

  const AssignablePillButton({
    super.key,
    required this.onPressed,
    required this.isApproved,
    this.iconWidget,
    required this.text,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShrinkAnimationButton(
      onPressed: onPressed,
      defaultColor: isApproved ? activeColor.withAlpha(16) : CoconutColors.white,
      pressedColor: isApproved ? activeColor.withAlpha(70) : CoconutColors.gray150,
      borderRadius: 100,
      borderWidth: 1,
      border: Border.all(color: isApproved ? activeColor : CoconutColors.gray200, width: 1),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }
}
