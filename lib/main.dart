import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coconut_vault/app.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';

void main() async {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsRepository().init();
  deleteAllNewSecureStorageData();
  // Isolate 토큰 생성 및 초기화
  final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  if (Platform.isAndroid) {
    try {
      const MethodChannel channel = MethodChannel(methodChannelOS);

      final int version = await channel.invokeMethod('getSdkVersion');
      if (version != 26) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
    } on PlatformException catch (e) {
      Logger.log("Failed to get platform version: '${e.message}'.");
    }
  } else {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  Provider.debugCheckInvalidValueType = null;

  const String? appFlavor =
      String.fromEnvironment('FLUTTER_APP_FLAVOR') != '' ? String.fromEnvironment('FLUTTER_APP_FLAVOR') : null;
  NetworkType.setNetworkType(appFlavor == "mainnet" ? NetworkType.mainnet : NetworkType.regtest);

  /// 현재 MainRouteGuard를 사용하고 있긴 하지만, AppLifecycleState 이벤트가 등록되기 직전 inactive 상태로 전환 시
  /// PrivacyScreen이 보여지지 않는 상황 때문에 ScreenProtector의 PrivacyScreen 기능도 사용합니다.
  await ScreenProtector.protectDataLeakageWithImage(
    'ScreenProtectImage${NetworkType.currentNetworkType.isTestnet ? "Regtest" : ""}',
  ); // iOS에서만 동작
  //await ScreenProtector.protectDataLeakageOn(); // Android는 MainActivity.kt에서 네이티브 설정 완료
  if (!kDebugMode && Platform.isIOS) {
    await ScreenProtector.preventScreenshotOn(); // iOS and Android
  }

  // bluetooth
  await FlutterBluePlus.setOptions(showPowerAlert: false);

  // 리졸버 설정
  // 아래 경고를 위한 조치
  // flutter: Resolver for <lang = kr> not specified!
  // Please configure it via LocaleSettings.setPluralResolver. A fallback is used now.
  LocaleSettings.setPluralResolver(
    language: AppLocale.kr.name,
    cardinalResolver: (n, {zero, one, two, few, many, other}) {
      if (n == 0) return zero ?? other ?? '';
      if (n == 1) return one ?? other ?? '';
      return other ?? '';
    },
  );

  LocaleSettings.setPluralResolver(
    language: AppLocale.en.name,
    cardinalResolver: (n, {zero, one, two, few, many, other}) {
      if (n == 0) return zero ?? other ?? '';
      if (n == 1) return one ?? other ?? '';
      return other ?? '';
    },
  );

  return runApp(const CoconutVaultApp());
}

/// TODO: 개발자들 테스트 하면서 저장됐던 것 지우기 위한 용도
/// 서명 전용 모드 기능 머지 후에는 삭제 하기
Future<void> deleteAllNewSecureStorageData() async {
  const FlutterSecureStorage newStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.passcode, synchronizable: false),
  );

  newStorage.deleteAll();
}
