import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';

class ActionBottomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Widget? left;
  final TextStyle? textStyle;

  const ActionBottomButton({super.key, required this.onPressed, required this.text, this.left, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      height: 64,
      child: CupertinoButton(
        color: CoconutColors.black,
        disabledColor: CoconutColors.white.withValues(alpha: 0.15),
        borderRadius: CoconutBorder.defaultRadius,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (left != null) ...[left!, const SizedBox(width: 5)],
            Text(text, style: CoconutTypography.body1_16_Bold.merge(textStyle)),
          ],
        ),
      ),
    );
  }
}
