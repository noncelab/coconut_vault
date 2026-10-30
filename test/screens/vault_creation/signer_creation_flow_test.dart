import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_language.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/build_config.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/signer_assignment_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_completion_coordinator.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/signer_creation_fakes.dart';

// 키 배정 화면 → 단일 서명 지갑 생성 → 키 배정 화면 복귀를 실제 화면과 Navigator로 확인한다.
// full 빌드는 그냥 실행하고, lite 빌드 경로는 --dart-define=FLUTTER_APP_FLAVOR=liteRegtest로 실행한다.

const _nextButton = ValueKey('fake-mnemonic-next');
const _startButton = ValueKey('fake-creation-option');

/// 팝업은 한글 줄바꿈용 word joiner(U+2060)를 넣으므로 빼고 비교한다.
Finder _findPopupText(String text) => find.byWidgetPredicate(
  (widget) => widget is Text && (widget.data ?? widget.textSpan?.toPlainText())?.replaceAll('\u2060', '') == text,
);

class _FakeVisibilityProvider extends ChangeNotifier implements VisibilityProvider {
  @override
  AppLanguage get appLanguage => AppLanguage.ko;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 단일 서명 지갑 생성 방법 선택 화면 대역. 실제 화면처럼 생성 화면을 위에 쌓는다.
class _FakeCreationOptionsScreen extends StatelessWidget {
  final String mnemonic;

  const _FakeCreationOptionsScreen({required this.mnemonic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        key: _startButton,
        onPressed:
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FakeMnemonicScreen(mnemonic: mnemonic))),
        child: const Text('start'),
      ),
    );
  }
}

/// 니모닉 생성·확인 화면 대역. 진입 시 생성 상태를 비우고, '다음'에서 secret을 넣고 완료 단계로 넘어간다.
class _FakeMnemonicScreen extends StatefulWidget {
  final String mnemonic;

  const _FakeMnemonicScreen({required this.mnemonic});

  @override
  State<_FakeMnemonicScreen> createState() => _FakeMnemonicScreenState();
}

class _FakeMnemonicScreenState extends State<_FakeMnemonicScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletCreationProvider>().resetAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        key: _nextButton,
        onPressed: () async {
          context.read<WalletCreationProvider>().setSecretAndPassphrase(
            Uint8List.fromList(utf8.encode(widget.mnemonic)),
            null,
          );
          await proceedToVaultCreationCompletion(
            context,
            replaceCurrentRoute: true,
            routeArguments: {'name': 'new key'},
          );
        },
        child: const Text('next'),
      ),
    );
  }
}

class _Harness {
  final walletProvider = FakeWalletProvider();
  final creationProvider = WalletCreationProvider()..setQuorumRequirement(2, 3);
  final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get navigator => navigatorKey.currentState!;

  SignerAssignmentViewModel viewModelOf(WidgetTester tester) => Provider.of<SignerAssignmentViewModel>(
    tester.element(find.byKey(const ValueKey('signer-assignment-slot-0'))),
    listen: false,
  );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<VisibilityProvider>(create: (_) => _FakeVisibilityProvider()),
          ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          Provider<WalletCreationProvider>.value(value: creationProvider),
          ChangeNotifierProvider<AuthProvider>(create: (_) => _FakeAuthProvider()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('home')),
          routes: {
            AppRoutes.signerAssignment: (_) => const SignerAssignmentScreen(),
            AppRoutes.vaultCreationOptions: (_) => const _FakeCreationOptionsScreen(mnemonic: mnemonicA),
            AppRoutes.vaultNameSetup: (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map;
              return VaultNameAndIconSetupScreen(name: args['name']);
            },
          },
        ),
      ),
    );
    navigator.pushNamed(AppRoutes.signerAssignment);
    await tester.pumpAndSettle();
    // 키 배정 화면의 초기 로딩 지연
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  /// [slot] 자리에서 '이 볼트의 키 사용하기' → '네'로 생성 방법 선택 화면까지 간다.
  Future<void> goCreateSignerFor(WidgetTester tester, int slot) async {
    await tester.tap(find.byKey(ValueKey('signer-assignment-slot-$slot')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('signer-assignment-internal-key')));
    await tester.pumpAndSettle();
    expect(_findPopupText(t.alert.empty_vault.title), findsOneWidget);
    await tester.tap(_findPopupText(t.yes));
    await tester.pumpAndSettle();
    expect(find.byKey(_startButton), findsOneWidget);
  }

  /// 생성 화면에서 '다음'을 누르고, full 빌드면 이름 화면에서 완료까지 누른다.
  Future<void> createAndSave(WidgetTester tester) async {
    await tester.tap(find.byKey(_startButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_nextButton));
    await tester.pumpAndSettle();
    if (!kIsLiteBuild) {
      await tester.tap(find.text(t.complete));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  setUpAll(() => NetworkType.setNetworkType(NetworkType.regtest));

  testWidgets('저장하면 키 배정 화면으로 돌아와 그 자리에 새 키가 배정된다', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);

    await harness.goCreateSignerFor(tester, 1);
    await harness.createAndSave(tester);

    expect(find.byType(SignerAssignmentScreen), findsOneWidget);
    expect(find.byType(VaultNameAndIconSetupScreen), findsNothing);
    final viewModel = harness.viewModelOf(tester);
    expect(viewModel.assignedVaultList[1].importKeyType, ImportKeyType.internal);
    expect(viewModel.assignedVaultList[0].importKeyType, isNull);
    expect(harness.creationProvider.isCreatingSignerForMultisig, isFalse);
    expect(harness.creationProvider.secret, isEmpty);
  });

  testWidgets('니모닉을 만든 뒤 저장하지 않고 돌아오면 생성 상태가 남지 않는다', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.goCreateSignerFor(tester, 1);
    await tester.tap(find.byKey(_startButton));
    await tester.pumpAndSettle();
    // '다음'을 눌러 secret이 들어간 상태를 만든 뒤 화면 이동 없이 돌아온다
    harness.creationProvider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode(mnemonicA)), null);

    harness.navigator.pop(); // 생성 화면
    await tester.pumpAndSettle();
    harness.navigator.pop(); // 생성 방법 선택 화면
    await tester.pumpAndSettle();

    expect(find.byType(SignerAssignmentScreen), findsOneWidget);
    expect(harness.creationProvider.secret, isEmpty);
    expect(harness.creationProvider.isCreatingSignerForMultisig, isFalse);
    harness.viewModelOf(tester).saveSignersToProvider([]);
    expect(harness.creationProvider.walletType, WalletType.multiSignature);
  });

  testWidgets('뒤로 나왔다가 다른 자리에서 다시 만들면 그 자리에만 배정된다', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.goCreateSignerFor(tester, 1);
    harness.navigator.pop();
    await tester.pumpAndSettle();

    await harness.goCreateSignerFor(tester, 2);
    await harness.createAndSave(tester);

    final viewModel = harness.viewModelOf(tester);
    expect(viewModel.assignedVaultList[2].importKeyType, ImportKeyType.internal);
    expect(viewModel.assignedVaultList[1].importKeyType, isNull);
  });

  testWidgets('다른 자리에 가져온 키와 같은 키를 만들면 배정하지 않고 알린다', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    final sameKey = makeSingleSig(id: 0, mnemonic: mnemonicA);
    harness
        .viewModelOf(tester)
        .setAssignedVaultList(
          0,
          ImportKeyType.external,
          false,
          SignerBsms.parse(sameKey.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false)),
          null,
          HardwareWalletType.keystone,
        );
    await tester.pumpAndSettle();

    await harness.goCreateSignerFor(tester, 1);
    await harness.createAndSave(tester);

    expect(_findPopupText(t.alert.duplicate_key.title), findsOneWidget);
    final viewModel = harness.viewModelOf(tester);
    expect(viewModel.assignedVaultList[1].importKeyType, isNull);
    expect(viewModel.assignableSignerOptions, isEmpty);
  });
}
