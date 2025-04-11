import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/app_update_preparation_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coconut_vault/main.dart' as app;

import 'integration_test_utils.dart';

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
    testWidgets('Mnemonic check test', (tester) async {
      await skipScreensUntilVaultList(tester);

      // Save pin password 0000
      final authProvider = Provider.of<AuthProvider>(
        tester.element(find.byType(CupertinoApp)),
        listen: false,
      );
      await authProvider.savePin("0000");

      // add wallets
      final walletProvider = Provider.of<WalletProvider>(
        tester.element(find.byType(CupertinoApp)),
        listen: false,
      );
      int count = await addWallets(walletProvider, tester);
      expect(walletProvider.vaultList.length, count);

      count += await addSingleSigWallets(walletProvider, tester);
      expect(walletProvider.vaultList.length, count);

      // vault list screen to update preparation screen
      await showUpdatePreparationScreen(tester);

      final updatePreparationProvider =
          Provider.of<AppUpdatePreparationViewModel>(
        tester.element(find.text(t.settings_screen.prepare_update)),
        listen: false,
      );

      List<VaultListItemBase> singleSignVaults =
          walletProvider.getVaultsByWalletType(WalletType.singleSignature);
      List<String> mnemonicListToInput = [];

      // Check if vaultMnemonicItems were created correctly (name, index, mnemonic)
      expect(updatePreparationProvider.isMnemonicLoaded, true);
      expect(singleSignVaults.length,
          updatePreparationProvider.vaultMnemonicItems.length);

      for (int i = 0; i < singleSignVaults.length; i++) {
        VaultMnemonicItem vaultMnemonicItem =
            updatePreparationProvider.vaultMnemonicItems[i];
        List<String> vaultMnemonicList = await walletProvider
            .getSecret(singleSignVaults[i].id)
            .then((secret) => secret.mnemonic.split(' '));

        expect(vaultMnemonicItem.vaultName, singleSignVaults[i].name);
        expect(vaultMnemonicItem.mnemonicWordIndex < vaultMnemonicList.length,
            true);
        expect(vaultMnemonicItem.mnemonicWord,
            hashString(vaultMnemonicList[vaultMnemonicItem.mnemonicWordIndex]));
        mnemonicListToInput
            .add(vaultMnemonicList[vaultMnemonicItem.mnemonicWordIndex]);
      }

      // Check if Logic works correctly (text, index)
      final Finder textInput = find.byType(CoconutTextField);
      await waitForWidgetAndTap(tester, textInput, "textInput");

      for (int i = 0; i < mnemonicListToInput.length; i++) {
        VaultMnemonicItem vaultMnemonicItem =
            updatePreparationProvider.vaultMnemonicItems[i];
        String title = t.prepare_update.enter_nth_word_of_wallet(
          wallet_name: vaultMnemonicItem.vaultName,
          n: vaultMnemonicItem.mnemonicWordIndex + 1,
        );

        final Finder titleText = find.text(title);
        expect(titleText, findsOneWidget);
        expect(updatePreparationProvider.currentMnemonicIndex, i);

        await tester.enterText(textInput, mnemonicListToInput[i]);
        await tester.pumpAndSettle();
      }

      // Check if Logic finished correctly
      expect(updatePreparationProvider.isMnemonicFinished, true);
      expect(updatePreparationProvider.currentMnemonicIndex,
          mnemonicListToInput.length - 1);

      updatePreparationProvider.proceedNextMnemonic();
      expect(updatePreparationProvider.currentMnemonicIndex,
          mnemonicListToInput.length - 1);
    });

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
  final Finder skipButton = find.widgetWithText(TextButton, t.skip);
  await waitForWidget(tester, skipButton,
      timeoutMessage: 'Skip button not found after 10 seconds');
  await tester.tap(skipButton);
  await tester.pumpAndSettle();

  // Wait for and tap the understood button on welcome screen
  final Finder understoodButton =
      find.widgetWithText(CupertinoButton, t.welcome_screen.understood);
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

Future<void> showUpdatePreparationScreen(WidgetTester tester) async {
  // Click more button on vault List screen (VaultList to SettingScreen)
  final Finder moreButton = find.byIcon(CupertinoIcons.ellipsis);
  await waitForWidgetAndTap(tester, moreButton, "moreButton");

  // Click settings text on drop down menu (VaultList to SettingScreen)
  final Finder settingButtonOnDropdownMenu = find.text(t.settings);
  await waitForWidgetAndTap(
      tester, settingButtonOnDropdownMenu, "settingButtonOnDropdownMenu");

  // Click prepare_update text on menu
  final Finder updatePreparationText =
      find.text(t.settings_screen.prepare_update);
  await waitForWidgetAndTap(
      tester, updatePreparationText, "updatePreparationText");

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

Future<int> addSingleSigWallets(
    WalletProvider walletProvider, WidgetTester tester) async {
  final singleSig2 = SinglesigWallet(
    2,
    "New Wallet3",
    0,
    0,
    "primary exotic display destroy wrap zoo among scan length despair lend yard",
    '',
  );

  final singleSig3 = SinglesigWallet(
    3,
    "Test Wallet4",
    0,
    0,
    "dwarf aim crash town chalk device bulb simple space draft ball canoe",
    '',
  );

  await walletProvider.addSingleSigVault(singleSig2);
  await walletProvider.addSingleSigVault(singleSig3);
  return 2;
}

Future<int> addWallets(
    WalletProvider walletProvider, WidgetTester tester) async {
  // single sig wallet
  final singleSig = SinglesigWallet(
    1,
    "Test Wallet1",
    0,
    0,
    "thank split shrimp error own spirit slow glow act evidence globe slight",
    '',
  );

  await walletProvider.addSingleSigVault(singleSig);

  // multisig wallet
  String internalWalletBsms = '''
BSMS 1.0
00
[E0C42931/48'/1'/0'/2']Vpub5nNFgHQhQCGEaWtoLrnzWjDvngmwS9A8qT8g1tjkWrbvYwLGrcYupy8jFXmJqyFd9u6aeRTvuLKMrGZ8jdfbarYvLS8rK4Z8Qp5uvKjLTNt
ttt
''';
  String outsideWalletBsms = '''
BSMS 1.0
00
[858FA201/48'/1'/0'/2']Vpub5ncWX3M18jrGdytgNZfayhkzj37RpXHH5k11QsEC4BBJZga64W92KFDVg8CRoEyBAm4eZqXUTKEgx991ri14aWkBhAsgjak5pMHa8wjYirr
여여려
''';
  List<KeyStore> keyStores = [
    KeyStore.fromSignerBsms(internalWalletBsms),
    KeyStore.fromSignerBsms(outsideWalletBsms)
  ];
  List<MultisigSigner> signers = [
    MultisigSigner(
      id: 0,
      innerVaultId: 1,
      name: "Inside Wallet",
      iconIndex: 0,
      colorIndex: 0,
      signerBsms: internalWalletBsms,
      keyStore: keyStores[0],
    ),
    MultisigSigner(
      id: 0,
      signerBsms: outsideWalletBsms,
      name: outsideWalletBsms.split('\n')[3] ?? '',
      memo: 'memo test',
      keyStore: keyStores[1],
    ),
  ];

  await walletProvider.addMultisigVault(
    "Test Wallet2",
    0,
    0,
    signers,
    2,
  );

  return 2;
}
