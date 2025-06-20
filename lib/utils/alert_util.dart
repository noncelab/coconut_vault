import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';

TextStyle optionStyle = CoconutTypography.body2_14_Bold.merge(
  TextStyle(
    color: CoconutColors.black.withOpacity(0.7),
    fontWeight: FontWeight.w500,
  ),
);

// 전역 변수로 Dialog 상태 관리
bool _isDialogVisible = false;

void showAlertDialog(
    {required BuildContext context,
    String? title,
    String? content,
    VoidCallback? onConfirmPressed}) {
  if (_isDialogVisible) return;

  _isDialogVisible = true;
  showCupertinoModalPopup<void>(
    context: context,
    barrierDismissible: onConfirmPressed == null,
    builder: (BuildContext context) => CupertinoAlertDialog(
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
          child: Text('확인', style: optionStyle),
        ),
      ],
    ),
  ).then((_) {
    _isDialogVisible = false;
  });
}

void showConfirmDialog(
    {required BuildContext context,
    String? title,
    String? content,
    VoidCallback? onConfirmPressed}) {
  if (_isDialogVisible) return;

  _isDialogVisible = true;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: title != null
          ? Text(title, style: CoconutTypography.body1_16_Bold)
          : Text('주의', style: CoconutTypography.body1_16_Bold),
      content: content != null
          ? Text(content,
              style: CoconutTypography.body2_14.merge(
                TextStyle(
                  color: CoconutColors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ))
          : Text('정말로 진행하시겠어요?',
              style: CoconutTypography.body2_14.merge(
                TextStyle(
                  color: CoconutColors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              )),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('아니오', style: optionStyle),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            if (onConfirmPressed != null) {
              onConfirmPressed();
            }
            Navigator.pop(context);
            _isDialogVisible = false;
          },
          child: Text('네',
              style: optionStyle.merge(const TextStyle(color: CoconutColors.warningText))),
        ),
      ],
    ),
  ).then((_) {
    _isDialogVisible = false;
  });
}
