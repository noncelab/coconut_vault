import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coconut_vault/main.dart' as app;

/// 백업 데이터 암호화/복호화 및 파일 저장 기능 테스트
///
/// 실행 명령어:
/// ```bash
/// # 디버그 모드 (기본)
/// flutter test integration_test/update_preparation_test.dart --flavor regtest
/// # release 모드
/// flutter test integration_test/update_preparation_test.dart --flavor regtest --release
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
    testWidgets('Backup and restore test', (tester) async {
      // Skip tutorial screen
      await skipScreensUntilVaultList(tester);
      final walletProvider = Provider.of<WalletProvider>(
        tester.element(find.byType(CupertinoApp)),
        listen: false,
      );
      int count = await addWallets(walletProvider, tester);
      expect(walletProvider.vaultList.length, count);
      final backupData = await walletProvider.createBackupData();
      expect(backupData, isNotEmpty);
      await walletProvider.deleteAllWallets();
      expect(walletProvider.vaultList.length, 0);

      // 암복호화
      final savedPath =
          await UpdatePreparation.encryptAndSave(data: backupData);
      expect(savedPath, isNotEmpty);
      expect(() async => await UpdatePreparation.validatePreparationState(),
          returnsNormally);
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
  final skipButton = find.widgetWithText(TextButton, t.skip);

  // Wait for the skip button to appear (timeout after 10 seconds)
  bool found = false;
  for (int i = 0; i < 100 && !found; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    found = skipButton.evaluate().isNotEmpty;
  }
  expect(found, true, reason: 'Skip button not found after 10 seconds');

  await tester.tap(skipButton);
  await tester.pumpAndSettle();

  // Wait for and tap the understood button on welcome screen
  final understoodButton =
      find.widgetWithText(CupertinoButton, t.welcome_screen.understood);

  found = false;
  for (int i = 0; i < 100 && !found; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    found = understoodButton.evaluate().isNotEmpty;
  }
  expect(found, true, reason: 'Understood button not found after 10 seconds');

  await tester.tap(understoodButton);
  await tester.pumpAndSettle();

  // Wait for and tap the start button on guide screen
  final startButton = find.text(t.start);

  found = false;
  for (int i = 0; i < 100 && !found; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    found = startButton.evaluate().isNotEmpty;
  }
  expect(found, true, reason: 'Start button not found after 10 seconds');

  await tester.tap(startButton);
  await tester.pumpAndSettle();

  // Wait for the add wallet text to appear on vault list screen
  final addWalletText = find.text(t.vault_list_tab.add_wallet);

  found = false;
  for (int i = 0; i < 100 && !found; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    found = addWalletText.evaluate().isNotEmpty;
  }
  expect(found, true, reason: 'Add wallet text not found after 10 seconds');
}

Future<int> addWallets(
    WalletProvider walletProvider, WidgetTester tester) async {
  // Given: 테스트용 vault 생성 및 저장
  final singleSig = SinglesigWallet(
    1,
    "Test Wallet1",
    0,
    0,
    "thank split shrimp error own spirit slow glow act evidence globe slight",
    '',
  );

  await walletProvider.addSingleSigVault(singleSig);
  return 1;
}
