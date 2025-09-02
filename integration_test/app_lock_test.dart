import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/screens/common/pin_input_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coconut_vault/main.dart' as app;

import 'integration_test_utils.dart';

/// 앱 잠금 상태에서 PIN 일치/불일치, 대기시간, 영구 잠금 적용 여부 테스트
///
/// 실행 명령어:
/// ```bash
/// flutter test integration_test/app_lock_test.dart --flavor regtest
/// ```
///
/// 자세한 내용은 README.md 참고
bool shouldReset = true;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    if (shouldReset) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      SecureStorageRepository().deleteAll();
    }
  });
  group('Pin Check Tests', () {
    testWidgets('Create Vault test', (tester) async {
      await waitForCreateVault(tester);
    });

    testWidgets('Input wrong pin number test (2/8)', (tester) async {
      await waitForPinCheckScreen(tester);
    });
    // 2번 틀린 후 앱 재시작

    testWidgets('Input wrong pin number test (4/8)', (tester) async {
      await waitForPinCheckScreen(tester);
    });
    // 2번 틀린 후 앱 재시작

    testWidgets('Input wrong pin number test (6/8)', (tester) async {
      await waitForPinCheckScreen(tester);
    });
    // 2번 틀린 후 앱 재시작

    testWidgets('Input wrong pin number test (8/8)', (tester) async {
      await waitForPinCheckScreen(tester);
    });
    // 2번 틀린 후 앱 재시작 (영구 잠금 확인)

    // 볼트 초기화
    testWidgets('Reset Data', (tester) async {
      await waitForResetAllData(tester);
    });

    // 볼트 셍성
    testWidgets('Create Vault test', (tester) async {
      await waitForCreateVault(tester, skipScreens: false);
    });

    testWidgets('Input wrong pin number test (2/8)', (tester) async {
      await waitForPinCheckScreen(tester);
    });
    // 2번 틀린 후 앱 재시작

    testWidgets('Input correct pin number test', (tester) async {
      await waitForPinCheckScreen(tester, isForCorrectPin: true);
    });
  });
}

Future<void> waitForCreateVault(WidgetTester tester, {bool skipScreens = true}) async {
  if (skipScreens) {
    await skipScreensUntilVaultList(tester);
  } else {
    // Launch app and wait for tutorial screen
    app.main();
    await tester.pumpAndSettle();
    final Finder addWalletText = find.text(t.vault_list_tab.add_wallet);
    await waitForWidget(tester, addWalletText,
        timeoutMessage: 'Add wallet text not found after 10 seconds');
  }

  // Save pin password 0000
  final authProvider = Provider.of<AuthProvider>(
    tester.element(find.byType(CupertinoApp)),
    listen: false,
  );
  await authProvider.savePin("0000", false);

  // add vault
  final walletProvider = Provider.of<WalletProvider>(
    tester.element(find.byType(CupertinoApp)),
    listen: false,
  );
  await addVault(walletProvider, tester);
  expect(walletProvider.vaultList.length, 1);
  shouldReset = false;
}

Future<void> waitForPinCheckScreen(WidgetTester tester,
    {bool isLastChance = false, bool isForCorrectPin = false}) async {
  app.main();
  await tester.pumpAndSettle();

  // 먼저 PIN 입력 화면이 뜨는지 기다리기
  final Finder pinScreen = find.byType(PinInputScreen);
  await waitForWidget(
    tester,
    pinScreen,
    timeoutMessage: 'PIN 입력 화면이 뜨지 않았습니다.',
  );
  await tester.pump(const Duration(milliseconds: 1000));

  if (isForCorrectPin) {
    for (int i = 0; i < 4; i++) {
      final Finder zeroButton = find.text('0');
      await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
      expect(zeroButton, findsWidgets);
    }

    await tester.pumpAndSettle();
    return;
  }

  // '1' 버튼 찾기
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 3; j++) {
      for (int k = 0; k < 4; k++) {
        final Finder oneButton = find.text('1');
        await waitForWidgetAndTap(tester, oneButton, "oneButton");
        expect(oneButton, findsWidgets);
      }
    }
    if (i == 2 && isLastChance) {
      await tester.pumpAndSettle();
      return;
    }
    for (int refreshScreen = 0; refreshScreen < 6; refreshScreen++) {
      // 재시도 초 갱신
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }

  await tester.pumpAndSettle();
}

Future<void> waitForResetAllData(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 먼저 PIN 입력 화면이 뜨는지 기다리기
  final Finder pinScreen = find.byType(PinInputScreen);
  await waitForWidget(
    tester,
    pinScreen,
    timeoutMessage: 'PIN 입력 화면이 뜨지 않았습니다.',
  );
  await tester.pump(const Duration(milliseconds: 1000));
  // '비밀번호가 기억나지 않나요?' 버튼 찾기
  final Finder forgotButton = find.text(t.forgot_password);
  await waitForWidgetAndTap(tester, forgotButton, "forgotButton");
  expect(forgotButton, findsWidgets);

  // '초기화하기' 버튼 찾기
  final Finder resetButton = find.text(t.alert.forgot_password.btn_reset);
  await waitForWidgetAndTap(tester, resetButton, "resetButton");
  expect(resetButton, findsWidgets);

  await tester.pumpAndSettle();
}

Future<void> skipScreensUntilVaultList(WidgetTester tester) async {
  // Launch app and wait for tutorial screen
  app.main();
  await tester.pumpAndSettle();

  // Wait for and tap the skip button on tutorial screen
  final Finder skipButton = find.widgetWithText(TextButton, t.skip);
  await waitForWidget(tester, skipButton, timeoutMessage: 'Skip button not found after 10 seconds');
  await tester.tap(skipButton);
  await tester.pumpAndSettle();

  // Wait for and tap the understood button on welcome screen
  // final Finder understoodButton = find.widgetWithText(CupertinoButton, t.welcome_screen.understood);
  // await waitForWidget(tester, understoodButton,
  //     timeoutMessage: 'Understood button not found after 10 seconds');
  // await tester.tap(understoodButton);
  // await tester.pumpAndSettle();

  // Wait for and tap the start button on guide screen
  final Finder startButton = find.text(t.start);
  await waitForWidget(tester, startButton,
      timeoutMessage: 'Start button not found after 10 seconds');
  await tester.tap(startButton);
  await tester.pumpAndSettle();

  // Wait for the add wallet text to appear on vault list screen
  final Finder addWalletText = find.text(t.vault_list_tab.add_wallet);
  await waitForWidget(tester, addWalletText,
      timeoutMessage: 'Add wallet text not found after 10 seconds');
}

Future<void> addVault(WalletProvider walletProvider, WidgetTester tester) async {
  // single sig wallet
  final singleSig = SingleSigWalletCreateDto(
    1,
    "Test Wallet1",
    0,
    0,
    "thank split shrimp error own spirit slow glow act evidence globe slight",
    '',
  );

  await walletProvider.addSingleSigVault(singleSig);

  return;
}
