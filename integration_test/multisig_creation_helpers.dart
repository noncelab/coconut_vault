import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_creation_options_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'integration_test_utils.dart';
import 'single_sig_creation_helpers.dart';

const _testMnemonic1 = <String>[
  'primary',
  'exotic',
  'display',
  'destroy',
  'wrap',
  'zoo',
  'among',
  'scan',
  'length',
  'despair',
  'lend',
  'yard',
];

const _testMnemonic2 = <String>[
  'dwarf',
  'aim',
  'crash',
  'town',
  'chalk',
  'device',
  'bulb',
  'simple',
  'space',
  'draft',
  'ball',
  'canoe',
];

const _internalWalletName1 = 'Test Single-Sig 1';
const _internalWalletName2 = 'Test Single-Sig 2';
const _multisigName = 'Test Multisig';

Future<List<SingleSigVaultListItem>> prepareTwoInternalSingleSigs(WalletProvider walletProvider) async {
  final dto1 = SingleSigWalletCreateDto(
    null,
    _internalWalletName1,
    0,
    0,
    utf8.encode(_testMnemonic1.join(' ')),
    Uint8List(0),
  );
  final dto2 = SingleSigWalletCreateDto(
    null,
    _internalWalletName2,
    0,
    0,
    utf8.encode(_testMnemonic2.join(' ')),
    Uint8List(0),
  );

  try {
    final wallet1 = await walletProvider.addSingleSigVault(dto1);
    final wallet2 = await walletProvider.addSingleSigVault(dto2);
    return [wallet1, wallet2];
  } finally {
    dto1.wipe();
    dto2.wipe();
  }
}

Future<void> launchCleanAppWithTwoSingleSigs(
  WidgetTester tester,
  FutureOr<void> Function() appMain,
  VaultMode mode,
) async {
  await prepareCleanMainnetApp(mode);
  await appMain();
  expect(
    await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90),
    isTrue,
    reason: 'Vault home did not appear',
  );
  final walletProvider = tester.element(find.byType(VaultHomeScreen)).read<WalletProvider>();
  await prepareTwoInternalSingleSigs(walletProvider);
  await tester.pumpAndSettle();
  expect(walletProvider.getVaults(), hasLength(2));
}

Future<void> openMultisigCreationOptions(WidgetTester tester) async {
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('vault-home-add')), 'vault add button');
  expect(await waitForWidget(tester, find.byType(VaultTypeSelectionScreen)), isTrue);
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('vault-type-multisig')), 'multisig option');
  expect(await waitForWidget(tester, find.byType(MultisigCreationOptionsScreen)), isTrue);
}

Future<void> startNewMultisigCreation(WidgetTester tester) async {
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('multisig-option-new')), 'new multisig option');
  expect(await waitForWidget(tester, find.byType(MultisigQuorumSelectionScreen)), isTrue);
}

Future<void> setQuorumToTwoOfTwo(WidgetTester tester) async {
  final totalStepper = find.byKey(const Key('total_key_count'));
  await waitForWidget(tester, totalStepper, timeoutMessage: 'Total key stepper was not found');
  final stepperButtons = find.descendant(of: totalStepper, matching: find.byType(GestureDetector));
  expect(stepperButtons, findsNWidgets(2));
  await tester.tap(stepperButtons.first);
  await tester.pumpAndSettle();

  await tester.pump(const Duration(milliseconds: 600));
  final nextButton = find.byKey(const ValueKey('fixed-bottom-button-action'));
  await waitForWidget(tester, nextButton, timeoutMessage: 'Quorum next button was not found');
  await tester.tap(nextButton);
  await tester.pumpAndSettle();
}

Future<void> assignInternalSigner(WidgetTester tester, int slotIndex, String walletName) async {
  expect(await waitForWidget(tester, find.byType(SignerAssignmentScreen)), isTrue);
  final slot = find.byKey(ValueKey('signer-assignment-slot-$slotIndex'));
  await waitForWidgetAndTap(tester, slot, 'signer assignment slot $slotIndex');

  await waitForWidgetAndTap(
    tester,
    find.byKey(const ValueKey('signer-assignment-internal-key')),
    'use internal key option',
  );

  final walletRow = find.text(walletName);
  await waitForWidgetAndTap(tester, walletRow, 'internal wallet "$walletName"');
}

Future<void> submitSignerAssignment(WidgetTester tester) async {
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('fixed-bottom-button-action')), 'signer assignment next');
}

Future<void> completeFullMultisigCreation(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(VaultNameAndIconSetupScreen)), isTrue);
  final nameField = find.descendant(of: find.byType(VaultNameAndIconSetupScreen), matching: find.byType(EditableText));
  expect(nameField, findsOneWidget);
  await tester.enterText(nameField, _multisigName);
  await tester.pumpAndSettle();
  await waitForWidgetAndTap(
    tester,
    find.descendant(
      of: find.byType(VaultNameAndIconSetupScreen),
      matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
    ),
    'save multisig',
  );

  expect(
    await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90),
    isTrue,
    reason: 'Vault home did not appear after multisig creation',
  );
}

Future<void> verifyMultisigSaved(WidgetTester tester, {required bool isLite}) async {
  expect(await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90), isTrue);
  final walletProvider = tester.element(find.byType(VaultHomeScreen)).read<WalletProvider>();
  final vaults = walletProvider.getVaults();
  expect(vaults, hasLength(3), reason: 'Expected 2 single-sig + 1 multisig wallets');

  final multisigVaults = vaults.whereType<MultisigVaultListItem>();
  expect(multisigVaults, hasLength(1));
  final multisig = multisigVaults.first;
  expect(multisig.requiredSignatureCount, 2);
  expect(multisig.signers, hasLength(2));

  if (isLite) {
    final expectedName = _expectedLiteMultisigName(walletProvider, multisig);
    expect(multisig.name, expectedName);
    expect(multisig.iconIndex, CustomIcons.icons.indexOf(CustomIcons.coconut));
    expect(multisig.colorIndex, CoconutColors.colorPalette.indexOf(CoconutColors.gray600));
  } else {
    expect(multisig.name, _multisigName);
  }
}

String _expectedLiteMultisigName(WalletProvider walletProvider, MultisigVaultListItem multisig) {
  final sanitizedSigners = walletProvider.sanitizeSignerMfp(multisig.signers);
  final vault = MultisignatureVault.fromKeyStoreList(
    sanitizedSigners.map((s) => s.keyStore).toList(),
    multisig.requiredSignatureCount,
    addressType: AddressType.p2wsh,
  );
  final checksum = vault.descriptor.split('#').last;
  return 'Multisig $checksum';
}

const internalWalletName1 = _internalWalletName1;
const internalWalletName2 = _internalWalletName2;
