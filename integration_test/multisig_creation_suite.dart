import 'dart:async';

import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'integration_test_utils.dart';
import 'multisig_creation_helpers.dart';

void runMultisigCreationSuite({
  required FutureOr<void> Function() appMain,
  required VaultMode mode,
  required bool isLite,
}) {
  Future<void> start(WidgetTester tester) async {
    await launchCleanAppWithTwoSingleSigs(tester, appMain, mode);
  }

  testWidgets('creates a 2-of-2 multisig from two internal single-sig wallets', (tester) async {
    await start(tester);
    await openMultisigCreationOptions(tester);
    await startNewMultisigCreation(tester);
    await setQuorumToTwoOfTwo(tester);
    await assignInternalSigner(tester, 0, internalWalletName1);
    await assignInternalSigner(tester, 1, internalWalletName2);
    await submitSignerAssignment(tester);
    if (isLite) {
      expect(await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90), isTrue);
    } else {
      await completeFullMultisigCreation(tester);
    }
    await verifyMultisigSaved(tester, isLite: isLite);
  });
}
