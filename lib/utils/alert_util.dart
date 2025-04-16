import 'package:flutter/cupertino.dart';
import 'package:coconut_vault/styles.dart';

const TextStyle titleStyle = Styles.body1Bold;
const TextStyle contentStyle = Styles.label;
TextStyle optionStyle = Styles.label.merge(const TextStyle(fontWeight: FontWeight.bold));

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
      title: title != null ? Text(title, style: titleStyle) : null,
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
      title: title != null ? Text(title, style: titleStyle) : const Text('주의', style: titleStyle),
      content: content != null
          ? Text(content, style: contentStyle)
          : const Text('정말로 진행하시겠어요?', style: contentStyle),
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
          child: Text('네', style: optionStyle.merge(const TextStyle(color: MyColors.warningText))),
        ),
      ],
    ),
  ).then((_) {
    _isDialogVisible = false;
  });
}
