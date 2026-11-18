import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/app_lite.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/start_guide/lite_onboarding_screen.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => LocaleSettings.instance.loadAllLocales());
  setUp(() {
    NetworkType.setNetworkType(NetworkType.mainnet);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) => sink.success(['none'])),
    );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      null,
    );
    await LocaleSettings.setLocale(AppLocale.en);
  });

  for (final lite in [false, true]) {
    testWidgets('${lite ? 'Lite' : 'Full'} entry point starts a new Thai installation in Thai', (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('th', 'TH');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      SharedPreferences.setMockInitialValues({});
      await SharedPrefsRepository().init();
      await tester.pumpWidget(lite ? const CoconutVaultLiteApp() : const CoconutVaultApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      final screen = find.byType(lite ? LiteStartGuideScreen : WelcomeScreen);
      expect(screen, findsOneWidget);
      final provider = tester.element(screen).read<VisibilityProvider>();
      expect(provider.appLanguage.code, 'th');
      expect(LocaleSettings.currentLocale, AppLocale.th);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), 'th');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
