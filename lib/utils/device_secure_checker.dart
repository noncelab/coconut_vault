import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> isDeviceSecured() async {
  try {
    const MethodChannel channel = MethodChannel(methodChannelOS);
    final bool result = await channel.invokeMethod('isDeviceSecure');
    return result;
  } catch (e) {
    return false;
  }
}

Future<void> openSystemSecuritySettings(
  BuildContext context, {
  bool hasDialogShownForIos = false,
  String title = '',
  String description = '',
  String buttonText = '',
}) async {
  if (Platform.isAndroid) {
    const channel = MethodChannel('system_settings');
    await channel.invokeMethod('openSecuritySettings');
  } else if (Platform.isIOS) {
    // 다이얼로그 표시 후 iOS는 앱 설정 화면으로 이동
    if (hasDialogShownForIos) {
      await showDialog(
        context: context,
        builder:
            (context) => CoconutPopup(
              title: title,
              description: description,
              rightButtonText: buttonText,
              onTapRight: () async {
                try {
                  Navigator.of(context).pop();
                  final uri = Uri.parse('app-settings:');
                  await launchUrl(uri);
                } catch (e) {
                  debugPrint('iOS 설정 열기 실패: $e');
                }
              },
            ),
      );
    } else {
      // 다이얼로그 없이 바로 설정으로 이동
      try {
        final uri = Uri.parse('app-settings:');
        await launchUrl(uri);
      } catch (e) {
        debugPrint('iOS 설정 열기 실패: $e');
      }
    }
  }
}
