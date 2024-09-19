import 'package:flutter/cupertino.dart';
import 'package:coconut_vault/screens/app_unavailable_notification_screen.dart';
import 'package:coconut_vault/screens/ios_bluetooth_auth_notification_screen.dart';

void goAppUnavailableNotificationScreen(BuildContext context) {
  runApp(MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.0)),
      child: const CupertinoApp(
          debugShowCheckedModeBanner: false,
          home: AppUnavailableNotificationScreen())));
}

void goBluetoothAuthNotificationScreen(BuildContext context) {
  runApp(MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.0)),
      child: const CupertinoApp(
          debugShowCheckedModeBanner: false,
          home: IosBluetoothAuthNotificationScreen())));
}
