import 'package:coconut_vault/constants/external_links.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/screens/common/qrcode_bottom_sheet.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/settings/app_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../fixtures/thai_test_font.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final launched = <String>[];
  setUpAll(() async {
    await LocaleSettings.instance.loadAllLocales();
    await loadThaiTestFont();
  });
  setUp(() {
    launched.clear();
    PackageInfo.setMockInitialValues(
      appName: 'Coconut Vault',
      packageName: 'test',
      version: '1',
      buildNumber: '1',
      buildSignature: '',
    );
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (call) async {
      if (call.method == 'canLaunch') return true;
      if (call.method == 'launch') {
        launched.add((call.arguments as Map)['url'] as String);
        return true;
      }
      return null;
    });
    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) => sink.success(['wifi'])),
    );
  });
  tearDown(() async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), null);
    messenger.setMockStreamHandler(const EventChannel('dev.fluttercommunity.plus/connectivity_status'), null);
    await LocaleSettings.setLocale(AppLocale.en);
  });

  for (final locale in AppLocale.values) {
    for (final privacy in [false, true]) {
      testWidgets(
        '${locale.name}: ${privacy ? 'privacy' : 'terms'} QR selects the correct language',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await LocaleSettings.setLocale(locale);
          await tester.pumpWidget(MaterialApp(theme: withThaiFontFallback(ThemeData()), home: const AppInfoScreen()));
          await tester.pumpAndSettle();
          final title = privacy ? t.app_info_screen.privacy_policy : t.app_info_screen.terms_of_service;
          await tester.scrollUntilVisible(find.text(title), 300, scrollable: find.byType(Scrollable).first);
          await Scrollable.ensureVisible(tester.element(find.text(title)), alignment: 0.5);
          await tester.pumpAndSettle();
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
          final qr = tester.widget<QrcodeBottomSheet>(find.byType(QrcodeBottomSheet));
          final expected =
              privacy
                  ? (locale == AppLocale.th ? 'https://www.coconut.onl/en/privacy' : PRIVACY_POLICY_URL)
                  : (locale == AppLocale.th ? 'https://www.coconut.onl/en/tos' : TERMS_OF_SERVICE_URL);
          expect(qr.qrData, expected);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
        skip: locale == AppLocale.th && !hasThaiTestFont,
      );
    }

    testWidgets('${locale.name}: tutorial modal shows the correct page address', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await LocaleSettings.setLocale(locale);
      await tester.pumpWidget(
        MaterialApp(
          theme: withThaiFontFallback(ThemeData()),
          home: const TutorialScreen(screenStatus: TutorialScreenStatus.modal),
        ),
      );
      await tester.pumpAndSettle();
      final expectedAddress = locale == AppLocale.th ? 'tutorial.coconut.onl/en' : 'tutorial.coconut.onl';
      expect(find.textContaining(expectedAddress), findsOneWidget);
      if (locale == AppLocale.th) expect(find.text('tutorial.coconut.onl'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, skip: locale == AppLocale.th && !hasThaiTestFont);

    testWidgets('${locale.name}: tutorial opens the English page only for Thai', (tester) async {
      await LocaleSettings.setLocale(locale);
      final connectivity = ConnectivityProvider(hasSeenGuide: false);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: connectivity,
          child: MaterialApp(
            theme: withThaiFontFallback(ThemeData()),
            home: const TutorialScreen(screenStatus: TutorialScreenStatus.entrance),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(connectivity.isNetworkOn, isTrue);
      await tester.tap(find.text(t.view_tutorial));
      await tester.pumpAndSettle();
      expect(launched, [locale == AppLocale.th ? 'https://tutorial.coconut.onl/en/' : COCONUT_TUTORIAL_URL]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      connectivity.dispose();
    }, skip: locale == AppLocale.th && !hasThaiTestFont);
  }
}
