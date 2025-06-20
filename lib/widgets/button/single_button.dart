import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

enum SingleButtonPosition { none, top, middle, bottom }

extension SingleButtonBorderRadiusExtension on SingleButtonPosition {
  BorderRadius get radius {
    switch (this) {
      case SingleButtonPosition.none:
        return BorderRadius.circular(Sizes.size24);
      case SingleButtonPosition.top:
        return const BorderRadius.vertical(
          top: Radius.circular(Sizes.size24),
        );
      case SingleButtonPosition.middle:
        return BorderRadius.zero;
      case SingleButtonPosition.bottom:
        return const BorderRadius.vertical(
          bottom: Radius.circular(Sizes.size24),
        );
    }
  }

  EdgeInsets get padding {
    switch (this) {
      case SingleButtonPosition.none:
        return const EdgeInsets.symmetric(horizontal: Sizes.size20, vertical: Sizes.size24);
      case SingleButtonPosition.top:
        return const EdgeInsets.only(
            left: Sizes.size20, right: Sizes.size20, top: Sizes.size24, bottom: Sizes.size20);
      case SingleButtonPosition.middle:
        return const EdgeInsets.all(Sizes.size20);
      case SingleButtonPosition.bottom:
        return const EdgeInsets.only(
            left: Sizes.size20, right: Sizes.size20, top: Sizes.size20, bottom: Sizes.size24);
    }
  }
}

class SingleButton extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onPressed;
  final Widget? rightElement;
  final Widget? leftElement;
  final SingleButtonPosition buttonPosition;

  const SingleButton(
      {super.key,
      required this.title,
      this.description,
      this.onPressed,
      this.rightElement,
      this.leftElement,
      this.buttonPosition = SingleButtonPosition.none});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: CoconutColors.black.withOpacity(0.6),
            borderRadius: buttonPosition.radius,
          ),
          padding: buttonPosition.padding,
          child: Row(
            children: [
              if (leftElement != null) ...{
                Container(child: leftElement),
                const SizedBox(width: 12),
              },
              Expanded(child: Text(title, style: CoconutTypography.body2_14_Bold)),
              rightElement ?? _rightArrow(),
            ],
          ),
        ));
  }

  Widget _rightArrow() =>
      Icon(Icons.keyboard_arrow_right_rounded, color: CoconutColors.black.withOpacity(0.5));
}
