import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
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
  // Isolate 토큰 생성 및 초기화
  final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  Provider.debugCheckInvalidValueType = null;
  final dbDirectory = await getAppDocumentDirectory(paths: ['objectbox']);
  Repository.initialize(dbDirectory.path);
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  await ScreenProtector.protectDataLeakageWithImage(
      'ScreenProtectImage'); // iOS
  await ScreenProtector.protectDataLeakageOn(); // Android
  await ScreenProtector.preventScreenshotOn(); // iOS and Android

  return runApp(const PowVaultApp());
}
