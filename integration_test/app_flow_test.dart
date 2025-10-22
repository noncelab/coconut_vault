import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/home/vault_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:coconut_vault/main.dart' as app;

import 'integration_test_utils.dart';

/// 백업 데이터 암호화/복호화 및 파일 저장 기능 테스트
///
/// 실행 명령어:
/// ```bash
/// flutter test integration_test/app_flow_test.dart --flavor regtest
/// ```
///
/// 자세한 내용은 README.md 참고
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    final prefs = SharedPrefsRepository();
    await prefs.init();
    await prefs.clearSharedPref();
    await SecureStorageRepository().deleteAll();
    await WalletRepository().loadVaultListJsonArrayString();
  });

  tearDown(() async {
    // await UpdatePreparation.clearUpdatePreparationStorage();
  });

  group('[BackupFile X]', () {
    setUp(() async {
      await setBackupFile(false);
      await skipTutorial(true);
    });

    // 1. 앱 첫 시작 시 Tutorial 화면으로 진입하는 통합테스트
    testWidgets('Tutorial', (tester) async {
      await skipTutorial(false);
      await tutorialFlow(tester);
    });

    // 2. 추가된 지갑이 있을 때 PinCheckScreen -> VaultListScreen으로 진입하는 통합테스트
    testWidgets('[Update O] [Wallet O] PinCheck-VaultList', (tester) async {
      await setIsUpdated(true);
      await setWalletData(true);
      await pinCheckToVaultListFlow(tester);
    });

    testWidgets('[Update X] [Wallet O] PinCheck-VaultList', (tester) async {
      await setIsUpdated(false);
      await setWalletData(true);
      await pinCheckToVaultListFlow(tester);
    });

    // 3. 추가된 지갑이 없을 때 PinCheckScreen을 거치지 않고 바로 VaultListScreen으로 진입하는 통합테스트
    testWidgets('[Update O] [Wallet X] VaultList', (tester) async {
      await setIsUpdated(true);
      await setWalletData(false);
      await vaultListFlow(tester);
    });

    testWidgets('[Update X] [Wallet X] VaultList', (tester) async {
      await setIsUpdated(false);
      await setWalletData(false);
      await vaultListFlow(tester);
    });
  });

  group('[BackupFile O]', () {
    setUp(() async {
      await setBackupFile(true);
      await skipTutorial(true);
    });

    // 4. 복원 파일이 존재하고 앱 업데이트가 완료됐을 때 PinCheckScreen -> VaultListRestorationScreen -> VaultListScreen으로 진입하는 통합테스트
    testWidgets('[Update O] [Wallet O] PinCheck-VaultListRestoration-VaultList', (tester) async {
      await setIsUpdated(true);
      await setWalletData(true);
      await pinCheckToVaultListRestorationFlow(tester);
    });

    testWidgets('[Update O] [Wallet X] PinCheck-VaultListRestoration-VaultList', (tester) async {
      await setIsUpdated(true);
      await setWalletData(false);
      await pinCheckToVaultListRestorationFlow(tester);
    });

    // 5. 복원 파일이 존재하고 앱 업데이트가 안됐을 때 RestorationInfoScreen -> PinCheckScreen -> VaultListRestorationScreen -> VaultList으로 진입하는 통합 테스트
    testWidgets('[Update X] [Wallet O] RestorationInfo-PinCheck-VaultListRestoration-VaultList', (tester) async {
      await setIsUpdated(false);
      await setWalletData(true);
      await restorationInfoFlow(tester);
    });

    testWidgets('[Update X] [Wallet X] RestorationInfo-PinCheck-VaultListRestoration-VaultList', (tester) async {
      await setIsUpdated(false);
      await setWalletData(false);
      await restorationInfoFlow(tester);
    });
  });
}

Future<void> tutorialFlow(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Check TutorialScreen
  final Finder tutorialScreen = find.byType(TutorialScreen);
  await waitForWidget(tester, tutorialScreen, timeoutMessage: 'tutorialScreen not found after 60 seconds');
  await tester.pumpAndSettle();
}

Future<void> vaultListFlow(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Check VaultListScreen
  final Finder vaultListScreen = find.byType(VaultListScreen);
  await waitForWidget(tester, vaultListScreen, timeoutMessage: 'VaultListScreen not found after 60 seconds');
  await tester.pumpAndSettle();
}

Future<void> pinCheckToVaultListFlow(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Check PinCheckScreen
  final Finder pinCheckScreen = find.byType(PinCheckScreen);
  await waitForWidget(tester, pinCheckScreen, timeoutMessage: 'pinCheckScreen not found after 60 seconds');
  await tester.pumpAndSettle();

  // Input Password 0000
  final Finder zeroButton = find.text('0');
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");

  // Check VaultListScreen
  final Finder vaultListScreen = find.byType(VaultListScreen);
  await waitForWidget(tester, vaultListScreen, timeoutMessage: 'VaultListScreen not found after 60 seconds');
  await tester.pumpAndSettle();
}

Future<void> pinCheckToVaultListRestorationFlow(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Check PinCheckScreen
  final Finder pinCheckScreen = find.byType(PinCheckScreen);
  await waitForWidget(tester, pinCheckScreen, timeoutMessage: 'pinCheckScreen not found after 60 seconds');
  await tester.pumpAndSettle();

  // Input Password 0000
  final Finder zeroButton = find.text('0');
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");

  // Check vaultListRestorationScreen
  // final Finder vaultListRestorationScreen = find.byType(VaultListRestorationScreen);
  // await waitForWidget(
  //   tester,
  //   vaultListRestorationScreen,
  //   timeoutMessage: 'vaultListRestorationScreen not found after 60 seconds',
  // );
  // await tester.pumpAndSettle();

  // Wait for restoration
  // final Finder startVaultText = find.text(t.vault_list_restoration.start_vault);
  // await waitForWidgetAndTap(tester, startVaultText, "startVaultText");

  // Check VaultListScreen
  final Finder vaultListScreen = find.byType(VaultListScreen);
  await waitForWidget(tester, vaultListScreen, timeoutMessage: 'VaultListScreen not found after 60 seconds');
  await tester.pumpAndSettle();
}

Future<void> restorationInfoFlow(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Check RestorationInfoScreen
  // final Finder restorationInfoScreen = find.byType(RestorationInfoScreen);
  // await waitForWidget(
  //   tester,
  //   restorationInfoScreen,
  //   timeoutMessage: 'restorationInfoScreen not found after 60 seconds',
  // );
  // await tester.pumpAndSettle();

  // Click CoconutButton
  final Finder coconutButton = find.byType(CoconutButton);
  await waitForWidgetAndTap(tester, coconutButton, "coconutButton");

  // Click PinCheckScreen
  final Finder pinCheckScreen = find.byType(PinCheckScreen);
  await waitForWidget(tester, pinCheckScreen, timeoutMessage: 'pinCheckScreen not found after 60 seconds');
  await tester.pumpAndSettle();

  // Input Password 0000
  final Finder zeroButton = find.text('0');
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");

  // Check VaultListRestorationScreen
  // final Finder vaultListRestorationScreen = find.byType(VaultListRestorationScreen);
  // await waitForWidget(
  //   tester,
  //   vaultListRestorationScreen,
  //   timeoutMessage: 'vaultListRestorationScreen not found after 60 seconds',
  // );

  // Wait for restoration
  // final Finder startVaultText = find.text(t.vault_list_restoration.start_vault);
  // await waitForWidgetAndTap(tester, startVaultText, "startVaultText");

  // Check VaultListScreen
  final Finder vaultListScreen = find.byType(VaultListScreen);
  await waitForWidget(tester, vaultListScreen, timeoutMessage: 'VaultListScreen not found after 60 seconds');
  await tester.pumpAndSettle();
}
