import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/button/action_bottom_button.dart';

class GuideDialog extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onPressed;

  const GuideDialog({super.key, this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (child != null) child!,
          ActionBottomButton(
            onPressed: onPressed ?? () => Navigator.pop(context),
            text: t.confirm,
          )
        ],
      ),
      backgroundColor: CoconutColors.white,
      contentPadding: const EdgeInsets.all(10.0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
    );
  }
}
