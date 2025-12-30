import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/cupertino.dart';

TextStyle optionStyle = CoconutTypography.body2_14_Bold.merge(
  TextStyle(color: CoconutColors.black.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
);

// 전역 변수로 Dialog 상태 관리
bool _isDialogVisible = false;

Future<void> showAlertDialog({
  required BuildContext context,
  String? title,
  String? content,
  VoidCallback? onConfirmPressed,
}) async {
  if (_isDialogVisible) return;

  _isDialogVisible = true;
  await showCupertinoModalPopup<void>(
    context: context,
    barrierDismissible: onConfirmPressed == null,
    builder:
        (BuildContext context) => CupertinoAlertDialog(
          title: title != null ? Text(title, style: CoconutTypography.body1_16_Bold) : null,
          content: content != null ? Text(content) : null,
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              /// This parameter indicates this action is the default,
              /// and turns the action's text to bold text.
              isDefaultAction: true,
              onPressed: () {
                if (onConfirmPressed != null) {
                  onConfirmPressed();
                }

                Navigator.pop(context);
                _isDialogVisible = false;
              },
              child: Text(t.confirm, style: optionStyle),
            ),
          ],
        ),
  ).then((_) {
    _isDialogVisible = false;
  });
}
