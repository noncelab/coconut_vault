import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/number_format_preset.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/settings/language_bottom_sheet.dart';
import 'package:coconut_vault/screens/settings/settings_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/thai_test_font.dart';

class _FailingImportWalletProvider extends ChangeNotifier implements WalletProvider {
  @override
  bool isSeedDuplicated(Uint8List secret, Uint8List passphrase) => throw const FormatException('test import failure');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LocaleSettings.instance.loadAllLocales();
    await loadThaiTestFont();
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.en));

  for (final scale in [1.0, 2.0]) {
    testWidgets('Thai language is last and selectable at 320px / ${scale}x', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        SharedPrefsKeys.kLanguage: 'en',
        SharedPrefsKeys.kNumberFormatPreset: 'swiss',
        SharedPrefsKeys.kIsBtcUnit: false,
      });
      await SharedPrefsRepository().init();
      final provider = VisibilityProvider(isSigningOnlyMode: true);
      await tester.pump();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            navigatorKey: navigator,
            theme: withThaiFontFallback(ThemeData()),
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Settings'))));
      await tester.pumpAndSettle();
      showModalBottomSheet<void>(
        context: navigator.currentContext!,
        isScrollControlled: true,
        builder: (_) => const SizedBox(height: 284, child: LanguageBottomSheet()),
      );
      await tester.pumpAndSettle();
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('ไทย'), 60, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('ไทย')).dy, greaterThan(tester.getTopLeft(find.text('日本語')).dy));
      await tester.tap(find.text('ไทย'));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageBottomSheet), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(provider.appLanguage.code, 'th');
      expect(LocaleSettings.currentLocale, AppLocale.th);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kLanguage), 'th');
      expect(provider.numberFormatPreset, NumberFormatPreset.swiss);
      expect(provider.isBtcUnit, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    }, skip: !hasThaiTestFont);
  }

  testWidgets('settings show Thai as the current language', (tester) async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.kLanguage: 'th',
      SharedPrefsKeys.kVaultMode: VaultMode.signingOnly.name,
    });
    await SharedPrefsRepository().init();
    await LocaleSettings.setLocale(AppLocale.th);
    final visibility = VisibilityProvider(isSigningOnlyMode: true);
    final preference = PreferenceProvider();
    final auth = AuthProvider();
    final scrollController = ScrollController();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: visibility),
          ChangeNotifierProvider.value(value: preference),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(
          theme: withThaiFontFallback(ThemeData()),
          home: Scaffold(body: SettingsScreen(scrollController: scrollController)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ไทย'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('ไทย'), findsOneWidget);
    expectThaiGlyphs(tester, find.byType(SettingsScreen));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    visibility.dispose();
    preference.dispose();
    auth.dispose();
    scrollController.dispose();
  }, skip: !hasThaiTestFont);

  for (final signingOnly in [false, true]) {
    testWidgets('Thai mnemonic import error uses a translated confirmation in ${signingOnly ? 'Lite' : 'Full'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        SharedPrefsKeys.kLanguage: 'th',
        SharedPrefsKeys.kVaultMode: (signingOnly ? VaultMode.signingOnly : VaultMode.secureStorage).name,
      });
      await SharedPrefsRepository().init();
      await LocaleSettings.setLocale(AppLocale.th);
      final visibility = VisibilityProvider(isSigningOnlyMode: signingOnly);
      final creation = WalletCreationProvider();
      final wallets = _FailingImportWalletProvider();
      addTearDown(visibility.dispose);
      addTearDown(creation.resetAll);
      addTearDown(wallets.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: visibility),
            ChangeNotifierProvider<WalletProvider>.value(value: wallets),
            Provider.value(value: creation),
          ],
          child: MaterialApp(
            theme: withThaiFontFallback(ThemeData()),
            home: const CustomLoadingOverlay(child: MnemonicImportScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Public BIP39 test vector; exercise the screen's real input, validation and Next action.
      final words = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'
          .split(' ');
      for (var index = 0; index < words.length; index++) {
        await tester.enterText(
          find.descendant(of: find.byKey(ValueKey('mnemonic_field_12_$index')), matching: find.byType(EditableText)),
          words[index],
        );
        await tester.pump();
      }
      await tester.tap(find.text(t.mnemonic_import_screen.title));
      await tester.pumpAndSettle();
      expect(tester.widget<FixedBottomButton>(find.byType(FixedBottomButton)).isActive, isTrue);
      await tester.tap(find.text(t.next));
      await tester.pumpAndSettle();
      final popup = find.byType(CoconutPopup);
      expect(popup, findsOneWidget);
      expect(find.descendant(of: popup, matching: find.text(t.errors.creation_error)), findsOneWidget);
      expect(find.descendant(of: popup, matching: find.text('FormatException: test import failure')), findsOneWidget);
      expect(find.descendant(of: popup, matching: find.text('ตกลง')), findsOneWidget);
      expect(find.descendant(of: popup, matching: find.text('OK')), findsNothing);
      if (hasThaiTestFont) expectThaiGlyphs(tester, popup);
      await tester.tap(find.descendant(of: popup, matching: find.text('ตกลง')));
      await tester.pumpAndSettle();
      expect(popup, findsNothing);
      expect(find.byType(MnemonicImportScreen), findsOneWidget);
      expect(creation.secret, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
