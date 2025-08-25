import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/app_update_preparation_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:provider/provider.dart';
import 'package:coconut_vault/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'integration_test_utils.dart';

/// 백업 데이터 암호화/복호화 및 파일 저장 기능 테스트
///
/// 실행 명령어:
/// ```bash
/// flutter test integration_test/update_preparation_test.dart --flavor regtest
/// ```
///
/// 자세한 내용은 README.md 참고
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 모든 값 제거
    SecureStorageRepository().deleteAll();
  });

  tearDown(() async {
    // 각 테스트 후 암호화된 파일들과 저장된 키 삭제
    await UpdatePreparation.clearUpdatePreparationStorage();
  });

  group('UpdatePreparation Integration Tests', () {
    // 업데이트 준비 프로세스에서 싱글시그니처 월렛의 니모닉을 검증합니다.
    testWidgets('Mnemonic check test', (tester) async {
      await mnemonicCheckFlow(tester, false);
    });

    // 니모닉 확인시 대문자 입력이 가능해야 합니다.
    testWidgets('Mnemonic check uppercase test', (tester) async {
      await mnemonicCheckFlow(tester, true);
    });

    testWidgets('Backup and restore test', (tester) async {
      // Skip tutorial screen
      await skipScreensUntilVaultList(tester);
      final walletProvider = Provider.of<WalletProvider>(
        tester.element(find.byType(CupertinoApp)),
        listen: false,
      );
      int count = await addWallets(walletProvider: walletProvider);
      expect(walletProvider.vaultList.length, count);
      final backupData = await walletProvider.createBackupData();
      expect(backupData, isNotEmpty);
      await walletProvider.deleteAllWallets();
      expect(walletProvider.vaultList.length, 0);

      // 암복호화
      final savedPath = await UpdatePreparation.encryptAndSave(data: backupData);
      expect(savedPath, isNotEmpty);
      expect(() async => await UpdatePreparation.validatePreparationState(), returnsNormally);
      final decryptedData = await UpdatePreparation.readAndDecrypt();
      expect(decryptedData, backupData);

      await walletProvider.restoreFromBackupData(decryptedData);
      expect(walletProvider.vaultList.length, count);
    });
  });
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
  final Finder understoodButton = find.widgetWithText(CupertinoButton, t.welcome_screen.understood);
  await waitForWidget(tester, understoodButton,
      timeoutMessage: 'Understood button not found after 10 seconds');
  await tester.tap(understoodButton);
  await tester.pumpAndSettle();

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

Future<void> mnemonicCheckFlow(WidgetTester tester, bool uppercase) async {
  await skipScreensUntilVaultList(tester);

  // Save pin password 0000
  final authProvider = Provider.of<AuthProvider>(
    tester.element(find.byType(CupertinoApp)),
    listen: false,
  );
  await authProvider.savePin("0000", false);

  // Add Wallets on VaultListScreen
  final walletProvider = Provider.of<WalletProvider>(
    tester.element(find.byType(CupertinoApp)),
    listen: false,
  );
  int count = await addWallets(walletProvider: walletProvider);
  expect(walletProvider.vaultList.length, count);

  count += await addSingleSigWallets(walletProvider: walletProvider);
  expect(walletProvider.vaultList.length, count);

  // VaultListScreen to UpdatePreparationScreen
  await showUpdatePreparationScreen(tester);

  final updatePreparationProvider = Provider.of<AppUpdatePreparationViewModel>(
    tester.element(find.text(t.settings_screen.prepare_update)),
    listen: false,
  );

  List<VaultListItemBase> singleSignVaults =
      walletProvider.getVaultsByWalletType(WalletType.singleSignature);
  // Check if mnemonic is loaded
  expect(updatePreparationProvider.isMnemonicLoaded, true);

  // Find TextInput for mnemonic validation
  final Finder textInput = find.byType(CoconutTextField);
  await waitForWidgetAndTap(tester, textInput, "textInput");

  for (int i = 0; i < singleSignVaults.length; i++) {
    // Load vault's mnemonicList
    List<String> vaultMnemonicList = await walletProvider
        .getSecret(singleSignVaults[i].id)
        .then((mnemonic) => mnemonic.split(' '));

    String title = t.prepare_update.enter_nth_word_of_wallet(
      wallet_name: updatePreparationProvider.walletName,
      n: updatePreparationProvider.mnemonicWordIndex,
    );

    // Check title Text
    final Finder titleText = find.text(title);
    expect(titleText, findsOneWidget);

    // Input mnemonic to TextInput
    String mnemonic = vaultMnemonicList[updatePreparationProvider.mnemonicWordIndex - 1];
    await tester.enterText(textInput, uppercase ? mnemonic.toUpperCase() : mnemonic);
    await tester.pumpAndSettle();
  }

  // Check if Logic is finished
  expect(updatePreparationProvider.isMnemonicValidationFinished, true);
}

Future<void> showUpdatePreparationScreen(WidgetTester tester) async {
  // Click more button on vault List screen (VaultList to SettingScreen)
  final Finder moreButton = find.byType(IconButton).last;
  await waitForWidgetAndTap(tester, moreButton, "moreButton");

  // Click settings text on drop down menu (VaultList to SettingScreen)
  final Finder settingButtonOnDropdownMenu = find.text(t.settings);
  await waitForWidgetAndTap(tester, settingButtonOnDropdownMenu, "settingButtonOnDropdownMenu");

  // Click prepare_update text on menu
  final Finder updatePreparationText = find.text(t.settings_screen.prepare_update);
  await waitForWidgetAndTap(tester, updatePreparationText, "updatePreparationText");

  // Input Password 0000
  final Finder zeroButton = find.text('0');
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");
  await waitForWidgetAndTap(tester, zeroButton, "zeroButton");

  // Click confirm text on update preparation screen
  final Finder confirmText = find.text(t.confirm);
  await waitForWidgetAndTap(tester, confirmText, "confirmText");
}
