import 'package:flutter/cupertino.dart';
import 'package:coconut_vault/styles.dart';

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
        decoration: BoxDecoration(
            borderRadius: MyBorder.defaultRadius, color: MyColors.lightgrey),
        padding: Paddings.widgetContainer,
        child: child,
      ),
    );
  }
}
