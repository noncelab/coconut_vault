import 'dart:async';

import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/pin_input_screen.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_reset_flow_test.dart' show ResetPreferences;
import 'pin_view_models_test.dart' show ViewModelAuth;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> prepare(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsRepository().init();
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
  }

  testWidgets('unavailable authentication recommends restart and requires confirmation before wallet reset', (
    tester,
  ) async {
    await prepare(tester);
    final auth = ViewModelAuth()..authenticationUnavailable = true;
    final visibility = VisibilityProvider(isSigningOnlyMode: false);
    final events = <String>[];
    var completed = 0;
    const keyChannel = MethodChannel('onl.coconut.vault/secure_storage_keys');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Empty wallet storage; use the actual cleaner and reset usecase.
    messenger.setMockMethodCallHandler(keyChannel, (_) async => <String>[]);
    addTearDown(() => messenger.setMockMethodCallHandler(keyChannel, null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<VisibilityProvider>.value(value: visibility),
          InheritedProvider<PreferenceProvider>.value(value: ResetPreferences(events)),
        ],
        child: MaterialApp(
          home: PinCheckScreen(pinCheckContext: PinCheckContextEnum.appLaunch, onReset: () => completed++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.errors.pin_storage_unavailable), findsOneWidget);
    expect(tester.widget<PinInputScreen>(find.byType(PinInputScreen)).disabled, true);
    await tester.tap(find.text('1'), warnIfMissed: false);
    await tester.pump();
    expect(auth.verifyCalls, 0);
    expect(tester.widget<PinInputScreen>(find.byType(PinInputScreen)).pin, isEmpty);

    await tester.tap(find.text(t.errors.pin_storage_reset_button));
    await tester.pumpAndSettle();
    expect(find.text(t.errors.pin_storage_reset_warning), findsOneWidget);
    expect(auth.credentialResets, isEmpty);
    expect(events, isEmpty);
    await tester.tap(find.text(t.no));
    await tester.pumpAndSettle();
    expect(completed, 0);
    expect(auth.credentialResets, isEmpty);
    await tester.tap(find.text(t.errors.pin_storage_reset_button));
    await tester.pumpAndSettle();
    expect(find.text(t.yes), findsOneWidget);
    await tester.tap(find.text(t.yes));
    await tester.pumpAndSettle();
    expect(auth.credentialResets, [false]);
    expect(events, ['preferences']);
    expect(completed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    visibility.dispose();
  });

  testWidgets('PIN is saved only after confirmation; save failure restores the first setting step', (tester) async {
    await prepare(tester);
    final gate = Completer<void>();
    final auth =
        ViewModelAuth()
          ..verify = (() async => false)
          ..save = (() => gate.future);
    var completed = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(home: PinSettingScreen(onComplete: () => completed++)),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> enterPin() async {
      for (final digit in '123456'.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await enterPin();
    expect(find.text(t.pin_setting_screen.enter_again), findsOneWidget);
    expect(tester.widget<PinInputScreen>(find.byType(PinInputScreen)).step, 1);
    expect(auth.verifyCalls, 1);
    expect(auth.saveCalls, 0);
    await enterPin();
    expect(auth.saveCalls, 1);
    expect(tester.widget<PinInputScreen>(find.byType(PinInputScreen)).disabled, true);
    gate.completeError(const PinAuthException());
    await tester.pumpAndSettle();

    final input = tester.widget<PinInputScreen>(find.byType(PinInputScreen));
    expect(input.step, 0);
    expect(input.pin, isEmpty);
    expect(input.disabled, false);
    expect(find.text(t.pin_setting_screen.new_password), findsOneWidget);
    expect(find.text(t.errors.pin_processing_error), findsOneWidget);
    expect(completed, 0);
    expect(tester.takeException(), isNull);

    // A fresh PIN can be entered after the failure.
    await tester.tap(find.text('7'));
    await tester.pump();
    expect(tester.widget<PinInputScreen>(find.byType(PinInputScreen)).pin, '7');
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
  });
}
