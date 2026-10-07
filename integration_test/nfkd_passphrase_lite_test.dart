// lite 빌드의 패스프레이즈 NFKD 정규화 대응 통합 테스트.
// lite에서도 fullMainnet 3.2.0 이하에서 정규화하지 않고 만든 지갑을 가져올 수 있으므로, fullMainnet과 같이 지갑 선택이 나와야 한다.
//
// 경고: 매 테스트 시작 전에 앱 데이터를 전부 삭제한다. 테스트 전용 에뮬레이터에서만 실행할 것.
//
// fvm flutter test integration_test/nfkd_passphrase_lite_test.dart --flavor liteMainnet -d <EMULATOR_ID>
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/main_lite.dart' as app;
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/passphrase_wallet_selection_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'integration_test_utils.dart';
import 'single_sig_creation_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lite 가져오기: 정규화로 바뀌는 패스프레이즈는 fullMainnet과 같이 지갑을 고르게 한다', (tester) async {
    await prepareCleanMainnetApp(VaultMode.signingOnly);
    final preferences = SharedPrefsRepository();
    await preferences.init();
    await preferences.setString(SharedPrefsKeys.kLanguage, 'ko');
    app.main();
    expect(await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90), isTrue);

    await openSingleSigOptions(tester);
    await openCreationMethod(tester, creationRoutes.mnemonicImport);
    await enterImportedMnemonic(tester);
    final passphraseSwitch = find.descendant(
      of: find.byType(MnemonicImportScreen),
      matching: find.byType(CupertinoSwitch),
    );
    await tester.ensureVisible(passphraseSwitch);
    await tester.tap(passphraseSwitch);
    await tester.pumpAndSettle();
    final passphraseField =
        find.descendant(of: find.byType(MnemonicImportScreen), matching: find.byType(EditableText)).last;
    await tester.ensureVisible(passphraseField);
    await tester.enterText(passphraseField, '코코넛2026');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await waitForWidgetAndTap(
      tester,
      find.descendant(
        of: find.byType(MnemonicImportScreen),
        matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
      ),
      'import next',
    );

    expect(await waitForWidget(tester, find.byType(PassphraseWalletSelectionBottomSheet)), isTrue);
    expect(find.textContaining('86F4', findRichText: true), findsOneWidget);
    expect(find.textContaining('17F7', findRichText: true), findsOneWidget);
    expect(find.text(t.passphrase_wallet_selection.option_legacy(version: '3.2.0')), findsOneWidget);
  });
}
