import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/model/manager/wallet_list_manager.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/utils/database_path_util.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';

void main() async {
  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsService().init();
  await WalletListManager().init();
  // Isolate 토큰 생성 및 초기화
  final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  if (Platform.isAndroid) {
    try {
      const MethodChannel channel = MethodChannel(methodChannelOS);

      final int version = await channel.invokeMethod('getSdkVersion');
      if (version != 26) {
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
    } on PlatformException catch (e) {
      Logger.log("Failed to get platform version: '${e.message}'.");
    }
  } else {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  Provider.debugCheckInvalidValueType = null;
  // coconut 0.6 버전까지만 사용, 0.7버전부터 필요 없어짐
  final dbDirectory = await getAppDocumentDirectory(paths: ['objectbox']);
  // coconut_lib 0.6까지 사용하던 db 경로 데이터 삭제
  try {
    if (dbDirectory.existsSync()) {
      dbDirectory.deleteSync(recursive: true);
    }
  } catch (_) {
    // ignore
  }

  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  await ScreenProtector.protectDataLeakageWithImage(
      'ScreenProtectImage'); // iOS
  await ScreenProtector.protectDataLeakageOn(); // Android
  await ScreenProtector.preventScreenshotOn(); // iOS and Android

  return runApp(const CoconutVaultApp());
}
