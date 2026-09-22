import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/widgets/card/vault_addition_guide_card.dart';
import 'package:coconut_vault/widgets/check_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'integration_test_utils.dart';

const testSeedQrPayload = '000000000000000000000000000000000000000000000003';

const testMnemonic = <String>[
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'abandon',
  'about',
];

Future<void> prepareCleanMainnetApp(VaultMode mode) async {
  final preferences = SharedPrefsRepository();
  await preferences.init();
  await preferences.clearSharedPref();
  await SecureStorageRepository().deleteAll();
  await preferences.setBool(SharedPrefsKeys.hasShownStartGuide, true);
  await preferences.setString(SharedPrefsKeys.kVaultMode, mode.name);
  if (mode == VaultMode.secureStorage) {
    await savePinCode('0000');
  }
  await WalletRepository().loadVaultListJsonArrayString();
}

Future<void> launchCleanApp(WidgetTester tester, FutureOr<void> Function() appMain, VaultMode mode) async {
  await prepareCleanMainnetApp(mode);
  await appMain();
  expect(
    await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90),
    isTrue,
    reason: 'Vault home did not appear',
  );
}

Future<void> openSingleSigOptions(WidgetTester tester) async {
  await waitForWidgetAndTap(tester, find.byType(VaultAdditionGuideCard), 'empty-vault add card');
  expect(await waitForWidget(tester, find.byType(VaultTypeSelectionScreen)), isTrue);
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('vault-type-single-sig')), 'single-signature option');
  expect(await waitForWidget(tester, find.byType(VaultCreationOptions)), isTrue);
}

Future<void> openCreationMethod(WidgetTester tester, String route, {bool hasSecurityCheck = false}) async {
  final optionIndex = switch (route) {
    AppRoutes.mnemonicCoinflip => 0,
    AppRoutes.mnemonicDiceRoll => 1,
    AppRoutes.mnemonicAutoGen => 2,
    AppRoutes.mnemonicImport => 3,
    AppRoutes.seedQrImport => 4,
    _ => throw ArgumentError.value(route, 'route', 'Unsupported single-signature creation route'),
  };
  await waitForWidgetAndTap(tester, find.byKey(ValueKey('single-sig-option-$optionIndex')), route);
  if (!hasSecurityCheck) return;

  expect(await waitForWidget(tester, find.byType(SecuritySelfCheckScreen)), isTrue);
  final checklistItems = find.byType(ChecklistTile);
  expect(checklistItems, findsNWidgets(10));
  for (var index = 0; index < 10; index++) {
    final item = checklistItems.at(index);
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
  await waitForWidgetAndTap(
    tester,
    find.byKey(const ValueKey('fixed-bottom-button-action')),
    'security self-check next',
  );
}

Future<void> selectTwelveWords(WidgetTester tester, {required bool selectNoPassphrase}) async {
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('word-count-12')), '12 words');
  if (selectNoPassphrase) {
    await waitForWidgetAndTap(tester, find.byKey(const ValueKey('passphrase-no')), 'do not use passphrase');
  }
}

Future<void> enterCoinFlipEntropy(WidgetTester tester) async {
  final heads = find.byKey(const ValueKey('coin-flip-heads'));
  await waitForWidget(tester, heads, timeoutMessage: 'Coin flip input was not found');
  for (var i = 0; i < 128; i++) {
    await tester.tap(heads);
    await tester.pump(const Duration(milliseconds: 12));
  }
  await tester.pumpAndSettle();
}

Future<void> enterDiceEntropy(WidgetTester tester) async {
  final one = find.byKey(const ValueKey('dice-roll-1'));
  await waitForWidget(tester, one, timeoutMessage: 'Dice input was not found');
  for (var i = 0; i < 64; i++) {
    await tester.tap(one);
    await tester.pump(const Duration(milliseconds: 15));
  }
  await tester.pumpAndSettle();
}

Future<void> tapEntropyNext(WidgetTester tester) async {
  final next = find.byKey(const ValueKey('fixed-bottom-tween-right'));
  await waitForWidget(tester, next, timeoutMessage: 'Entropy next button was not found');
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> dismissMnemonicWarning(WidgetTester tester) async {
  await waitForWidgetAndTap(
    tester,
    find.byKey(const ValueKey('mnemonic-warning-dismiss')),
    'mnemonic warning acknowledgement',
  );
}

Future<void> enterImportedMnemonic(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(MnemonicImportScreen)), isTrue);
  for (var i = 0; i < testMnemonic.length; i++) {
    final field = find.byKey(ValueKey('mnemonic_field_12_$i'));
    await tester.ensureVisible(field);
    await tester.enterText(field, testMnemonic[i]);
    await tester.pump(const Duration(milliseconds: 50));
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> waitForSeedQrScan(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(SeedQrImportScreen)), isTrue);
  debugPrint('SeedQR scan required. Present a QR containing: $testSeedQrPayload');
  expect(
    await waitForWidget(
      tester,
      find.byType(SeedQrConfirmationScreen),
      timeoutSeconds: 300,
      timeoutMessage: 'No SeedQR was scanned within five minutes',
    ),
    isTrue,
  );
}

Future<void> expectManualEntropyConfirmation(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(MnemonicConfirmationScreen)), isTrue);
}

Future<void> expectAutoMnemonicVerification(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(MnemonicVerifyScreen)), isTrue);
}

Future<void> solveMnemonicVerification(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(MnemonicVerifyScreen)), isTrue);
  final context = tester.element(find.byType(MnemonicVerifyScreen));
  final words = utf8.decode(context.read<WalletCreationProvider>().secret).split(' ');

  for (var quiz = 0; quiz < 5; quiz++) {
    var position = -1;
    for (var index = 0; index < words.length; index++) {
      if (find.byKey(ValueKey('mnemonic-verify-position-$index')).evaluate().isNotEmpty) {
        position = index;
        break;
      }
    }
    expect(position, isNonNegative, reason: 'Mnemonic verification position was not found');
    await waitForWidgetAndTap(
      tester,
      find.byKey(ValueKey('mnemonic-verify-option-${words[position]}')),
      'correct mnemonic option',
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  expect(await waitForWidget(tester, find.byType(MnemonicConfirmationScreen)), isTrue);
}

Future<void> continueManualEntropyToFinalConfirmation(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(MnemonicConfirmationScreen)), isTrue);
  await dismissMnemonicWarning(tester);
  await waitForWidgetAndTap(
    tester,
    find.byKey(const ValueKey('fixed-bottom-button-action')),
    'mnemonic confirmation next',
  );
  await solveMnemonicVerification(tester);
}

String _expectedLiteVaultName(BuildContext context) {
  final creationProvider = context.read<WalletCreationProvider>();
  return _masterFingerprintName(creationProvider.secret, passphrase: creationProvider.passphrase);
}

String _expectedLiteSeedQrVaultName(WidgetTester tester) {
  final screen = tester.widget<SeedQrConfirmationScreen>(find.byType(SeedQrConfirmationScreen));
  return _masterFingerprintName(screen.scannedData);
}

String _masterFingerprintName(Uint8List secret, {Uint8List? passphrase}) {
  Seed? seed;
  KeyStore? keyStore;
  try {
    seed = Seed.fromMnemonic(secret, passphrase: passphrase);
    keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh);
    return keyStore.masterFingerprint.toUpperCase();
  } finally {
    keyStore?.wipeSeed();
    seed?.wipe();
  }
}

Future<void> completeSingleSigCreation(
  WidgetTester tester, {
  required bool isLite,
  required String fullVaultName,
}) async {
  expect(await waitForWidget(tester, find.byType(MnemonicConfirmationScreen)), isTrue);
  final expectedLiteName =
      isLite ? _expectedLiteVaultName(tester.element(find.byType(MnemonicConfirmationScreen))) : null;
  await dismissMnemonicWarning(tester);
  await waitForWidgetAndTap(
    tester,
    find.byKey(const ValueKey('fixed-bottom-button-action')),
    'final mnemonic confirmation',
  );

  if (!isLite) {
    expect(await waitForWidget(tester, find.byType(VaultNameAndIconSetupScreen)), isTrue);
    final nameField = find.descendant(
      of: find.byType(VaultNameAndIconSetupScreen),
      matching: find.byType(EditableText),
    );
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, fullVaultName);
    await tester.pumpAndSettle();
    await waitForWidgetAndTap(
      tester,
      find.descendant(
        of: find.byType(VaultNameAndIconSetupScreen),
        matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
      ),
      'save vault',
    );
  }

  expect(
    await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90),
    isTrue,
    reason: 'Vault home did not appear after wallet creation',
  );
  final walletProvider = tester.element(find.byType(VaultHomeScreen)).read<WalletProvider>();
  final vaults = walletProvider.getVaults();
  expect(vaults, hasLength(1));
  final vault = vaults.single;

  if (isLite) {
    expect(vault.name, expectedLiteName);
    expect(vault.iconIndex, CustomIcons.icons.indexOf(CustomIcons.coconut));
    expect(vault.colorIndex, CoconutColors.colorPalette.indexOf(CoconutColors.gray600));
  } else {
    expect(vault.name, fullVaultName);
  }
}

Future<void> completeSeedQrCreation(WidgetTester tester, {required bool isLite, required String fullVaultName}) async {
  expect(await waitForWidget(tester, find.byType(SeedQrConfirmationScreen)), isTrue);
  final expectedLiteName = isLite ? _expectedLiteSeedQrVaultName(tester) : null;
  await dismissMnemonicWarning(tester);
  await waitForWidgetAndTap(
    tester,
    find.byKey(const ValueKey('fixed-bottom-button-action')),
    'SeedQR confirmation next',
  );

  if (!isLite) {
    expect(await waitForWidget(tester, find.byType(VaultNameAndIconSetupScreen)), isTrue);
    final nameField = find.descendant(
      of: find.byType(VaultNameAndIconSetupScreen),
      matching: find.byType(EditableText),
    );
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, fullVaultName);
    await tester.pumpAndSettle();
    await waitForWidgetAndTap(
      tester,
      find.descendant(
        of: find.byType(VaultNameAndIconSetupScreen),
        matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
      ),
      'save SeedQR vault',
    );
  }

  expect(await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90), isTrue);
  final vaults = tester.element(find.byType(VaultHomeScreen)).read<WalletProvider>().getVaults();
  expect(vaults, hasLength(1));
  final vault = vaults.single;
  if (isLite) {
    expect(vault.name, expectedLiteName);
    expect(vault.iconIndex, CustomIcons.icons.indexOf(CustomIcons.coconut));
    expect(vault.colorIndex, CoconutColors.colorPalette.indexOf(CoconutColors.gray600));
  } else {
    expect(vault.name, fullVaultName);
  }
}

const creationRoutes = (
  coin: AppRoutes.mnemonicCoinflip,
  dice: AppRoutes.mnemonicDiceRoll,
  auto: AppRoutes.mnemonicAutoGen,
  mnemonicImport: AppRoutes.mnemonicImport,
  seedQr: AppRoutes.seedQrImport,
);
