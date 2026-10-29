import 'dart:async';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/view_model/pin_check_view_model.dart';
import 'package:coconut_vault/providers/view_model/pin_setting_view_model.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/services/security/pin_auth_service.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/screens/common/pin_input_screen.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'full_reset_flow_test.dart' show ResetPreferences;

class ViewModelAuth extends ChangeNotifier implements AuthProvider {
  @override
  Future<void> ready = Future.value();
  @override
  bool authenticationUnavailable = false;
  @override
  bool isPermanentlyLocked = false;
  @override
  bool isPinSet = true;
  @override
  bool isPinCharacter = false;
  @override
  bool isBiometricEnabled = false;
  @override
  bool isBiometricSupportedByDevice = false;
  @override
  List<BiometricType> availableBiometrics = [];
  @override
  bool isUnlockAvailable = true;
  @override
  int currentTurn = 0;
  @override
  int currentAttemptInTurn = 0;
  @override
  int remainingAttemptCount = 2;
  @override
  DateTime? unlockAvailableAt;
  @override
  FutureOr<void> Function()? onAuthenticationSuccess;
  Future<bool> Function() verify = () async => true;
  Future<void> Function() save = () async {};
  Future<bool> Function() biometric = () async => false;
  int verifyCalls = 0;
  int saveCalls = 0;
  int resetCalls = 0;
  final List<bool> credentialResets = [];
  @override
  Future<void> resetCredentials({bool preservePermanentLock = false, bool afterWalletDeletion = false}) async {
    credentialResets.add(preservePermanentLock);
    isPinSet = false;
  }

  @override
  Future<bool> verifyPin(String inputPin, {bool isAppLaunchScreen = false}) {
    verifyCalls++;
    return verify();
  }

  @override
  Future<void> savePin(String pin, bool isCharacter) {
    saveCalls++;
    return save();
  }

  @override
  Future<void> resetAuthenticationState({bool preservePermanentLock = false}) async {
    resetCalls++;
  }

  @override
  Future<bool> authenticateWithBiometrics({BuildContext? context, bool isSaved = false}) => biometric();
  @override
  List<String> getShuffledNumberList({isPinSettingContext = false}) => List.generate(10, (i) => '$i');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ViewModelAuth auth;
  late int success;
  setUp(() async {
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.isPinEnabled: true});
    await SharedPrefsRepository().init();
    auth = ViewModelAuth();
    success = 0;
  });
  tearDown(() => auth.dispose());

  PinCheckViewModel check({
    Future<void> Function()? biometric,
    PreferenceProvider? preferences,
    Future<bool> Function(Object)? retry,
    Future<void> Function()? permanentlyLocked,
  }) => PinCheckViewModel(
    authProvider: auth,
    pinCheckContext: PinCheckContextEnum.appLaunch,
    onSuccess: () async {
      success++;
    },
    onKeyboardFocus: () async {},
    verifyBiometrics: biometric ?? () async {},
    onReset: () async {},
    onPermanentlyLocked: permanentlyLocked ?? () async {},
    onPermanentLockReset: () async {},
    onResetFailure: retry ?? (_) async => false,
    getPreferenceProvider: () => preferences ?? (throw StateError('unexpected reset')),
  );
  PinSettingViewModel setting({Future<bool> Function()? biometric}) => PinSettingViewModel(
    authProvider: auth,
    greetingVisible: false,
    authenticateBiometrics: biometric ?? () async => false,
    noticeBiometrics: () async {},
    onSaved: () async {
      success++;
    },
    onBeforeSave: () {},
    onProcessingEnd: () {},
  );

  test('check waits for initialization and maps unavailable authentication to disabled input', () async {
    final ready = Completer<void>();
    auth.ready = ready.future;
    final model = check();
    final initialize = model.initialize();
    expect(model.disabled, true);
    await model.onKeyTap('1');
    expect(model.pin, isEmpty);
    auth.authenticationUnavailable = true;
    ready.complete();
    await initialize;
    expect(model.errorMessage, t.errors.pin_processing_error);
    expect(model.disabled, true);
    model.dispose();
  });

  test('PIN verification is exclusive and recovers processing state after failure', () async {
    final gate = Completer<bool>();
    auth.verify = () => gate.future;
    final model = check();
    await model.initialize();
    for (final digit in '12345'.split('')) {
      await model.onKeyTap(digit);
    }
    final pending = model.onKeyTap('6');
    expect(model.isVerifyingPin, true);
    await model.onKeyTap('7');
    expect(auth.verifyCalls, 1);
    gate.completeError(const PinAuthException());
    await pending;
    expect(model.isVerifyingPin, false);
    expect(model.errorMessage, t.errors.pin_processing_error);
    expect(model.pin, isEmpty);
    expect(success, 0);
    model.dispose();
  });

  test('permanent lock initialization resumes deletion and owns retry decision', () async {
    auth.isPermanentlyLocked = true;
    auth.isPinSet = true;
    const channel = MethodChannel('onl.coconut.vault/secure_storage_keys');
    var retries = 0;
    var completed = 0;
    final events = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async {
      if (retries == 0) throw PlatformException(code: 'KEYS_UNAVAILABLE');
      return <String>[];
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final model = check(
      preferences: ResetPreferences(events),
      retry: (_) async {
        retries++;
        return true;
      },
      permanentlyLocked: () async {
        completed++;
      },
    );
    await model.initialize();
    expect(retries, 1);
    expect(completed, 1);
    expect(auth.credentialResets, [true]);
    expect(model.isResetting, false);
    expect(model.disabled, true);
    model.dispose();
  });

  test('manual biometric errors clear processing and leave retry enabled', () async {
    final gate = Completer<void>();
    final model = check(biometric: () => gate.future);
    await model.initialize();
    final pending = model.onKeyTap(kBiometricIdentifier);
    expect(model.isVerifyingPin, true);
    gate.completeError(const PinAuthException());
    await pending;
    expect(model.errorMessage, t.errors.pin_processing_error);
    expect(model.disabled, false);
    model.dispose();
  });

  test('disposing during automatic biometric authentication prevents navigation and state reset', () async {
    final gate = Completer<bool>();
    auth.isBiometricEnabled = true;
    auth.biometric = () => gate.future;
    final model = check();
    final initialize = model.initialize();
    await Future<void>.delayed(Duration.zero);
    model.dispose();
    gate.complete(true);
    await initialize;
    expect(success, 0);
    expect(auth.resetCalls, 0);
    expect(auth.onAuthenticationSuccess, isNull);
  });

  testWidgets('lockout countdown belongs to model and stops when disposed', (tester) async {
    auth.ready = Future.value();
    auth.isUnlockAvailable = false;
    auth.unlockAvailableAt = DateTime.now().add(const Duration(seconds: 3));
    final model = check();
    await model.initialize();
    expect(model.disabled, true);
    await tester.pump(const Duration(seconds: 1));
    expect(model.errorMessage, isNotEmpty);
    model.dispose();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  test('setting rejects duplicate PIN and guards concurrent duplicate checks', () async {
    final gate = Completer<bool>();
    auth.verify = () => gate.future;
    final model = setting();
    model.onPinTypeChanged(PinType.character);
    final pending = model.onKeyTap('test-pin');
    expect(model.isProcessing, true);
    await model.onKeyTap('other-pin');
    model.onPinTypeChanged(PinType.number);
    expect(model.currentPinType, PinType.character);
    expect(auth.verifyCalls, 1);
    gate.complete(true);
    await pending;
    expect(model.step, 0);
    expect(model.pin, isEmpty);
    expect(model.isProcessing, false);
    expect(model.errorMessage, t.errors.duplicate_pin_error);
    model.dispose();
  });

  test('setting mismatch, save failure and retry are handled without a screen', () async {
    auth.verify = () async => false;
    auth.save = () async => throw const PinAuthException();
    final model = setting();
    model.onPinTypeChanged(PinType.character);
    await model.onKeyTap('new-pin');
    expect(model.step, 1);
    await model.onKeyTap('wrong-pin');
    expect(model.errorMessage, t.errors.pin_incorrect_error);
    expect(auth.saveCalls, 0);
    await model.onKeyTap('new-pin');
    expect(model.errorMessage, t.errors.pin_processing_error);
    expect(model.step, 0);
    expect(model.isProcessing, false);
    auth.save = () async {};
    await model.onKeyTap('new-pin');
    await model.onKeyTap('new-pin');
    expect(auth.saveCalls, 2);
    expect(success, 1);
    expect(model.pin, isEmpty);
    expect(model.pinConfirm, isEmpty);
    model.dispose();
  });

  test('biometric setup errors reset processing before saving PIN', () async {
    await SharedPrefsRepository().setBool(SharedPrefsKeys.isPinEnabled, false);
    auth.verify = () async => false;
    auth.isBiometricSupportedByDevice = true;
    auth.availableBiometrics = [BiometricType.face];
    final model = setting(biometric: () async => throw const PinAuthException());
    model.onPinTypeChanged(PinType.character);
    await model.onKeyTap('new-pin');
    await model.onKeyTap('new-pin');
    expect(model.errorMessage, t.errors.pin_processing_error);
    expect(model.isProcessing, false);
    expect(auth.saveCalls, 0);
    model.dispose();
  });

  test('disposing during setting duplicate check prevents confirmation and save', () async {
    final gate = Completer<bool>();
    auth.verify = () => gate.future;
    final model = setting();
    model.onPinTypeChanged(PinType.character);
    final pending = model.onKeyTap('new-pin');
    model.dispose();
    gate.complete(false);
    await pending;
    expect(auth.saveCalls, 0);
    expect(success, 0);
  });

  testWidgets('setting screen renders model progress and duplicate PIN error', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gate = Completer<bool>();
    auth.verify = () => gate.future;
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(value: auth, child: const MaterialApp(home: PinSettingScreen())),
    );
    await tester.pumpAndSettle();
    var input = tester.widget<PinInputScreen>(find.byType(PinInputScreen));
    input.onPinTypeChanged!(PinType.character);
    await tester.pump();
    input = tester.widget<PinInputScreen>(find.byType(PinInputScreen));
    input.onKeyTap('test-pin');
    await tester.pump();
    expect(tester.widget<PinInputScreen>(find.byType(PinInputScreen)).disabled, true);
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(find.text(t.errors.duplicate_pin_error), findsOneWidget);
    expect(tester.widget<PinInputScreen>(find.byType(PinInputScreen)).disabled, false);
    expect(auth.saveCalls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
