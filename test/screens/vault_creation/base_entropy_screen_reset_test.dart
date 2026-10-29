import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

class _FakeVisibilityProvider extends ChangeNotifier implements VisibilityProvider {
  @override
  bool get isPassphraseUseEnabled => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestEntropyScreen extends BaseMnemonicEntropyScreen {
  const _TestEntropyScreen({super.isTaproot}) : super(entropyType: EntropyType.auto, isEmbedded: true);

  @override
  State<_TestEntropyScreen> createState() => _TestEntropyScreenState();
}

class _TestEntropyScreenState extends BaseMnemonicEntropyScreenState<_TestEntropyScreen> {
  @override
  String get screenTitle => '';

  @override
  Widget buildEntropyWidget() => const SizedBox();
}

Future<void> _pump(WidgetTester tester, WalletCreationProvider creationProvider, {bool isTaproot = false}) {
  return tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<VisibilityProvider>(create: (_) => _FakeVisibilityProvider()),
        Provider<WalletCreationProvider>.value(value: creationProvider),
      ],
      child: MaterialApp(home: Scaffold(body: _TestEntropyScreen(isTaproot: isTaproot))),
    ),
  );
}

void main() {
  // 멀티시그 키 배정 화면의 "볼트에 키 없음" 다이얼로그를 거쳐 니모닉 생성으로 넘어온 상황
  WalletCreationProvider leftoverMultisigState() => WalletCreationProvider()..setQuorumRequirement(2, 3);

  testWidgets('진입 시 이전 멀티시그 정족수를 비워 단일키 지갑으로 판별된다', (tester) async {
    final creationProvider = leftoverMultisigState();

    await _pump(tester, creationProvider);
    creationProvider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode(_mnemonic)), Uint8List.fromList([1]));

    expect(creationProvider.requiredSignatureCount, isNull);
    expect(creationProvider.totalSignatureCount, isNull);
    expect(creationProvider.walletType, WalletType.singleSignature);
  });

  testWidgets('taproot 흐름에서는 WalletCreationProvider를 건드리지 않는다', (tester) async {
    final creationProvider = leftoverMultisigState();

    await _pump(tester, creationProvider, isTaproot: true);

    expect(creationProvider.requiredSignatureCount, 2);
    expect(creationProvider.totalSignatureCount, 3);
  });
}
