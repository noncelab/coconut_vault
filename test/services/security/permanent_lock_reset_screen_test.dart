import 'dart:async';

import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockedAuth extends ChangeNotifier implements AuthProvider {
  Completer<void> reset = Completer<void>();
  int resetCalls = 0;
  @override
  Future<void> get ready => Future.value();
  @override
  bool get isPermanentlyLocked => true;
  @override
  bool get isPinSet => false;
  @override
  bool get isPinCharacter => false;
  @override
  bool get isBiometricEnabled => false;
  @override
  bool get authenticationUnavailable => false;
  @override
  List<String> getShuffledNumberList({isPinSettingContext = false}) => List.generate(10, (i) => '$i');
  @override
  Future<void> clearPermanentLock() {
    resetCalls++;
    return reset.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('failed permanent lock reset removes input overlay and allows retry', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsRepository().init();
    final auth = LockedAuth();
    final visibility = VisibilityProvider(isSigningOnlyMode: false);
    var completed = 0;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<VisibilityProvider>.value(value: visibility),
        ],
        child: MaterialApp(
          home: PinCheckScreen(pinCheckContext: PinCheckContextEnum.appLaunch, onPermanentLockReset: () => completed++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> confirmReset() async {
      await tester.tap(find.text(t.errors.restart_vault));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.yes));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    // Avoid pumpAndSettle while the progress indicator is active.
    await tester.tap(find.text(t.errors.restart_vault));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.yes));
    await tester.pump();
    expect(auth.resetCalls, 1);
    expect(find.byType(AbsorbPointer), findsWidgets);
    auth.reset.completeError(const PinAuthException());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(t.errors.pin_processing_error), findsOneWidget);
    expect(find.byType(Positioned).evaluate().where((e) => (e.widget as Positioned).child is AbsorbPointer), isEmpty);
    expect(completed, 0);

    auth.reset = Completer<void>()..complete();
    await confirmReset();
    expect(auth.resetCalls, 2);
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    visibility.dispose();
  });
}
