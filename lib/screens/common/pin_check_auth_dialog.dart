import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

/// 생체 인증 실패 다이얼로그
Future<void> showAuthenticationFailedDialog(
    BuildContext context, bool hasAlreadyRequestedBioPermission) async {
  await showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text(
          hasAlreadyRequestedBioPermission == true
              ? t.permission.biometric.required
              : t.permission.biometric.denied,
          style: const TextStyle(
            color: CoconutColors.black,
          ),
        ),
        content: Text(
          t.permission.biometric.how_to_allow,
          style: const TextStyle(
            color: CoconutColors.black,
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              t.close,
              style: CoconutTypography.body2_14.merge(
                const TextStyle(
                  color: CoconutColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              t.permission.biometric.btn_move_to_setting,
              style: CoconutTypography.body2_14_Bold.setColor(Colors.blueAccent),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
          ),
        ],
      );
    },
  );
}

Future<void> openAppSettings() async {
  const url = 'app-settings:';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  }
}
