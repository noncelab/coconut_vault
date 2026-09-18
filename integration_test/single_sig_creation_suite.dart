import 'dart:async';

import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_dice_roll_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_confirmation_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'integration_test_utils.dart';
import 'single_sig_creation_helpers.dart';

void runSingleSigCreationSuite({
  required FutureOr<void> Function() appMain,
  required VaultMode mode,
  required bool isLite,
}) {
  Future<void> start(WidgetTester tester) async {
    await launchCleanApp(tester, appMain, mode);
    await openSingleSigOptions(tester);
  }

  testWidgets('creates entropy from coin flips', (tester) async {
    await start(tester);
    await openCreationMethod(tester, creationRoutes.coin, hasSecurityCheck: true);
    expect(await waitForWidget(tester, find.byType(MnemonicCoinflipScreen)), isTrue);
    await selectTwelveWords(tester, selectNoPassphrase: isLite || mode == VaultMode.signingOnly);
    await enterCoinFlipEntropy(tester);
    await tapEntropyNext(tester);
    await continueManualEntropyToFinalConfirmation(tester);
    await completeSingleSigCreation(tester, isLite: isLite, fullVaultName: 'Coin Flip Vault');
  });

  testWidgets('creates entropy from dice rolls', (tester) async {
    await start(tester);
    await openCreationMethod(tester, creationRoutes.dice, hasSecurityCheck: true);
    expect(await waitForWidget(tester, find.byType(MnemonicDiceRollScreen)), isTrue);
    await selectTwelveWords(tester, selectNoPassphrase: isLite || mode == VaultMode.signingOnly);
    await enterDiceEntropy(tester);
    await tapEntropyNext(tester);
    await continueManualEntropyToFinalConfirmation(tester);
    await completeSingleSigCreation(tester, isLite: isLite, fullVaultName: 'Dice Roll Vault');
  });

  testWidgets('creates an automatic mnemonic', (tester) async {
    await start(tester);
    await openCreationMethod(tester, creationRoutes.auto, hasSecurityCheck: true);
    expect(await waitForWidget(tester, find.byType(MnemonicAutoGenScreen)), isTrue);
    await selectTwelveWords(tester, selectNoPassphrase: isLite || mode == VaultMode.signingOnly);
    await dismissMnemonicWarning(tester);
    await tester.drag(find.byType(MnemonicAutoGenScreen), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tapEntropyNext(tester);
    await solveMnemonicVerification(tester);
    await completeSingleSigCreation(tester, isLite: isLite, fullVaultName: 'Auto Generated Vault');
  });

  testWidgets('imports a mnemonic and creates a wallet', (tester) async {
    await start(tester);
    await openCreationMethod(tester, creationRoutes.mnemonicImport);
    await enterImportedMnemonic(tester);
    await waitForWidgetAndTap(tester, find.byKey(const ValueKey('fixed-bottom-button-action')), 'mnemonic import next');
    await completeSingleSigCreation(tester, isLite: isLite, fullVaultName: 'Imported Vault');
  });

  testWidgets('imports SeedQR with a semi-manual camera step', (tester) async {
    await start(tester);
    await openCreationMethod(tester, creationRoutes.seedQr);
    await waitForSeedQrScan(tester);
    expect(find.byType(SeedQrConfirmationScreen), findsOneWidget);
    await completeSeedQrCreation(tester, isLite: isLite, fullVaultName: 'Seed QR Vault');
  });
}
