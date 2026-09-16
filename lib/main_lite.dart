import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app_lite.dart';
import 'package:coconut_vault/constants/app_language.dart';
import 'package:coconut_vault/constants/build_config.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';

/// 라이트(서명 전용) 버전 엔트리포인트.
///
/// `flutter build --flavor liteMainnet -t lib/main_lite.dart`
/// 안전 저장 모드 레거시 마이그레이션/정리 코드는 라이트에서 불필요하여 제외합니다.
void main() async {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = SharedPrefsRepository();
  await sharedPrefs.init();
  // 라이트 버전은 서명 전용 모드로 고정 (일부 코드가 kIsLiteBuild 대신 저장된 모드를 직접 조회함)
  await sharedPrefs.setString(SharedPrefsKeys.kVaultMode, VaultMode.signingOnly.name);
  // Isolate 토큰 생성 및 초기화
  final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  Provider.debugCheckInvalidValueType = null;

  setNetworkTypeFromAppFlavor();

  /// AppLifecycleState 이벤트가 등록되기 전에 앱 상태가 inactive/background로 젼환되는 경우 (튜토리얼, 앱 사용 불가 화면)
  /// PrivacyScreen이 보여지지 않는 상황 때문에 ScreenProtector의 PrivacyScreen 기능도 사용합니다.
  if (Platform.isIOS) {
    await ScreenProtector.protectDataLeakageWithImage(
      'ScreenProtectImage${NetworkType.currentNetworkType.isTestnet ? "Regtest" : ""}',
    );
  }
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
    language: AppLanguage.ko.name,
    cardinalResolver: (n, {zero, one, two, few, many, other}) {
      if (n == 0) return zero ?? other ?? '';
      if (n == 1) return one ?? other ?? '';
      return other ?? '';
    },
  );

  LocaleSettings.setPluralResolver(
    language: AppLanguage.en.name,
    cardinalResolver: (n, {zero, one, two, few, many, other}) {
      if (n == 0) return zero ?? other ?? '';
      if (n == 1) return one ?? other ?? '';
      return other ?? '';
    },
  );

  return runApp(const CoconutVaultLiteApp());
}
