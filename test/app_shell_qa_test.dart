// QA generated host test (logic_coverage.autofill)
// Target: _VaultAppState._getHomeScreenRoute (SecurityCheckStatus.secure 분기)
//   added condition: SharedPrefsRepository().hasPublicVaultList()   (removed: walletCount > 0)
// Intent (8eadd457 "refactor(지갑개수): 중복된 정보를 제거 - 버그와 데이터 불일치의 원인이 됨"):
//   안전 저장 모드에서 보안 검사 통과 후, 공개 vault 목록(VAULT_LIST)에 지갑이 있으면 PIN 확인으로,
//   없으면 홈으로 간다. 별도 지갑 개수 키(VAULT_LIST_LENGTH, 이제 deprecated)는 판단에 쓰지 않는다.
//
// Real: VaultApp/_VaultAppState, SplashScreen, SecurityPrechecker, Auth/Preference/Visibility/Connectivity
//   providers, SharedPrefsRepository.
// Boundary fakes: SharedPreferences mock values, OS method channel (isJailbroken=false, isDeviceSecure=true),
//   connectivity_plus channels (network none), flutter_blue_plus channel (adapter off).
//   pinCheckScreenBuilder is the injected full-build PIN screen; a marker widget stands in for it.
import 'package:coconut_vault/app_shell.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pinMarker = Key('qa-pin-check-marker');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(methodChannelOS), (call) async {
      switch (call.method) {
        case 'isJailbroken':
          return false;
        case 'isDeviceSecure':
          return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (call) async {
      return ['none'];
    });
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_blue_plus/methods'), (call) async {
      switch (call.method) {
        case 'flutterRestart':
        case 'connectedCount':
          return 0;
        case 'getAdapterState':
          return {'adapter_state': 6}; // BmAdapterStateEnum.off
      }
      return null;
    });
    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) => sink.success(['none'])),
    );
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel(methodChannelOS), null);
    messenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), null);
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_blue_plus/methods'), null);
    messenger.setMockStreamHandler(const EventChannel('dev.fluttercommunity.plus/connectivity_status'), null);
  });

  Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.hasShownStartGuide: true,
      SharedPrefsKeys.kVaultMode: VaultMode.secureStorage.name,
      SharedPrefsKeys.kLanguage: 'en',
      SharedPrefsKeys.kNumberFormatPreset: 'dotDecimal',
      ...prefs,
    });
    await SharedPrefsRepository().init();

    await tester.pumpWidget(
      VaultApp(
        isLiteBuild: false,
        routesBuilder: (_) => const {},
        fallbackRoutesBuilder: (_) => const {},
        pinCheckScreenBuilder: (context, onSuccess, onReset, onLocked, onLockReset) => const SizedBox(key: _pinMarker),
        vaultModeSelectionScreenBuilder: (context, onComplete) => const SizedBox(key: Key('qa-mode-selection')),
      ),
    );
    // splash 2s + security precheck 0.5s + post-frame; no pumpAndSettle (indefinite progress indicator).
    // flutter_blue_plus' adapterState stream only emits on real async; alternate real-async slices with fake pumps.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('공개 vault 목록에 지갑이 있으면 보안 검사 후 PIN 확인 화면으로 간다', (tester) async {
    await pumpApp(tester, {SharedPrefsKeys.kVaultListField: '[{"id":1,"vaultType":"singleSignature"}]'});

    expect(find.byKey(_pinMarker), findsOneWidget);
  });

  testWidgets('공개 vault 목록이 비어 있으면("[]") PIN 확인 없이 홈으로 간다', (tester) async {
    await pumpApp(tester, {SharedPrefsKeys.kVaultListField: '[]'});

    expect(find.byKey(_pinMarker), findsNothing);
    expect(find.byType(VaultHomeScreen), findsOneWidget);
  });

  testWidgets('레거시 VAULT_LIST_LENGTH가 남아 있어도 공개 vault 목록이 없으면 홈으로 간다', (tester) async {
    await pumpApp(tester, {SharedPrefsKeys.kDeprecatedVaultListLength: 3});

    expect(find.byKey(_pinMarker), findsNothing);
    expect(find.byType(VaultHomeScreen), findsOneWidget);
  });
}
