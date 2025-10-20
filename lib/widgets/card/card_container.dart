import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';

class CardContainer extends StatelessWidget {
  const CardContainer({super.key, this.color, this.child, this.onPressed});

  final String? color;
  final Widget? child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 124,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: CoconutBorder.defaultRadius, color: CoconutColors.gray150),
        padding: CoconutPadding.widgetContainer,
        child: child,
      ),
    );
  }
}
