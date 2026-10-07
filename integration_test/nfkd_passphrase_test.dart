// 패스프레이즈 NFKD 정규화 대응 통합 테스트 (생성 경고, 가져오기 지갑 선택, 다시 입력 검증).
//
// 경고: 매 테스트 시작 전에 앱 데이터(SharedPreferences, secure storage)를 전부 삭제한다.
// 테스트 전용 에뮬레이터에서만 실행할 것. 기기 잠금(PIN)이 설정되어 있어야 하며,
// 보안 모듈 접근 시 뜨는 시스템 PIN 입력은 외부에서 처리해야 한다.
//
// fvm flutter test integration_test/nfkd_passphrase_test.dart --flavor fullRegtest -d <EMULATOR_ID>
import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/main.dart' as app;
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/check_list.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/home/vault_home_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/passphrase_wallet_selection_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/parent_creation_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/passphrase_verification_screen.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'integration_test_utils.dart';
import 'single_sig_creation_helpers.dart';

const _koreanPassphrase = '코코넛2026';
const _appPin = '000000';

/// abandon...about + '코코넛2026'의 MFP. BIP39/BIP32 참조 구현으로 계산한 값
const _nfkdMfp = '86F41C46';
const _legacyMfp = '17F7E6FD';

Future<void> _launch(WidgetTester tester) async {
  await prepareCleanMainnetApp(VaultMode.secureStorage);
  // 앱 비밀번호는 6자리다. 공용 헬퍼가 저장한 값을 6자리로 덮어쓴다.
  await savePinCode(_appPin);
  final preferences = SharedPrefsRepository();
  await preferences.init();
  await preferences.setString(SharedPrefsKeys.kLanguage, 'ko');
  await preferences.setBool(SharedPrefsKeys.kPassphraseUseEnabled, true);
  app.main();
  expect(await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90), isTrue);
}

Future<void> _openMnemonicImportWithPassphrase(WidgetTester tester, String passphrase) async {
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('vault-home-add')).hitTestable(), 'vault add');
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('vault-type-single-sig')), 'single-sig option');
  await openCreationMethod(tester, creationRoutes.mnemonicImport);
  await enterImportedMnemonic(tester);
  final passphraseSwitch = find.descendant(
    of: find.byType(MnemonicImportScreen),
    matching: find.byType(CupertinoSwitch),
  );
  await tester.ensureVisible(passphraseSwitch);
  await tester.tap(passphraseSwitch);
  await tester.pumpAndSettle();
  // 니모닉 12칸 뒤에 있는 패스프레이즈 입력칸
  final passphraseField =
      find.descendant(of: find.byType(MnemonicImportScreen), matching: find.byType(EditableText)).last;
  await tester.ensureVisible(passphraseField);
  await tester.enterText(passphraseField, passphrase);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _tapImportNext(WidgetTester tester) async {
  await waitForWidgetAndTap(
    tester,
    find.descendant(
      of: find.byType(MnemonicImportScreen),
      matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
    ),
    'import next',
  );
}

Future<void> _expectSelectionSheet(WidgetTester tester) async {
  expect(
    await waitForWidget(tester, find.byType(PassphraseWalletSelectionBottomSheet)),
    isTrue,
    reason: 'wallet selection sheet did not appear',
  );
  expect(find.textContaining('86F4', findRichText: true), findsOneWidget);
  expect(find.textContaining('1C46', findRichText: true), findsOneWidget);
  expect(find.textContaining('17F7', findRichText: true), findsOneWidget);
  expect(find.text(t.passphrase_wallet_selection.option_standard), findsOneWidget);
  expect(find.text(t.passphrase_wallet_selection.option_legacy(version: '5.2.0')), findsOneWidget);
}

Future<void> _confirmSelection(WidgetTester tester, PassphraseEncoding encoding) async {
  if (encoding == PassphraseEncoding.legacyUtf8) {
    await waitForWidgetAndTap(tester, find.byKey(const ValueKey('passphrase-encoding-legacyUtf8')), 'legacy option');
  }
  await waitForWidgetAndTap(
    tester,
    find.descendant(
      of: find.byType(PassphraseWalletSelectionBottomSheet),
      matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
    ),
    'selection confirm',
  );
}

/// 니모닉 확인 → 이름 입력 → 저장 후 홈으로 돌아와 새 지갑의 id와 MFP를 반환한다.
/// 니모닉 최종 확인 화면에서 패스프레이즈 단계로 넘어가, 입력한 모양 그대로 한 칸씩 보이는지 확인한다.
Future<void> _expectPassphraseConfirmation(WidgetTester tester, List<String> expectedCharacters) async {
  expect(await waitForWidget(tester, find.byType(MnemonicConfirmationScreen)), isTrue);
  await dismissMnemonicWarning(tester);
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('fixed-bottom-button-action')), 'confirm mnemonic');
  final counts = <String, int>{};
  for (final character in expectedCharacters) {
    counts[character] = (counts[character] ?? 0) + 1;
  }
  for (final entry in counts.entries) {
    expect(
      find.descendant(of: find.byType(MnemonicConfirmationScreen), matching: find.text(entry.key)),
      findsNWidgets(entry.value),
      reason: 'passphrase character "${entry.key}" should appear as typed',
    );
  }
}

Future<({int id, String mfp})> _saveWallet(
  WidgetTester tester,
  String name, {
  // 숫자는 단계 표시 등 화면의 다른 텍스트와 겹칠 수 있어 한글 글자만 확인한다.
  List<String> passphraseCharacters = const ['코', '코', '넛'],
}) async {
  // 패스프레이즈가 있으면 최종 확인 단계에서 입력한 모양대로(자모로 분해되지 않고) 보여야 한다.
  await _expectPassphraseConfirmation(tester, passphraseCharacters);
  await waitForWidgetAndTap(tester, find.byKey(const ValueKey('fixed-bottom-button-action')), 'confirm passphrase');
  expect(await waitForWidget(tester, find.byType(VaultNameAndIconSetupScreen)), isTrue);
  await tester.enterText(
    find.descendant(of: find.byType(VaultNameAndIconSetupScreen), matching: find.byType(EditableText)),
    name,
  );
  await tester.pumpAndSettle();
  await waitForWidgetAndTap(
    tester,
    find.descendant(
      of: find.byType(VaultNameAndIconSetupScreen),
      matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
    ),
    'save vault',
  );
  expect(await waitForWidget(tester, find.byType(VaultHomeScreen), timeoutSeconds: 90), isTrue);
  final vault = tester
      .element(find.byType(VaultHomeScreen))
      .read<WalletProvider>()
      .getVaults()
      .firstWhere((vault) => vault.name == name);
  final mfp = (vault.coconutVault as SingleSignatureVault).keyStore.masterFingerprint.toUpperCase();
  return (id: vault.id, mfp: mfp);
}

/// 패스프레이즈 확인하기 화면에서 [passphrase]로 검사하고 성공 여부를 반환한다.
Future<bool> _verifyPassphrase(WidgetTester tester, String passphrase) async {
  final field = find.descendant(
    of: find.descendant(of: find.byType(PassphraseVerificationScreen), matching: find.byType(CoconutTextField)),
    matching: find.byType(EditableText),
  );
  expect(await waitForWidget(tester, field), isTrue);
  await tester.tap(field.first);
  await tester.pump();
  await tester.enterText(field.first, passphrase);
  await tester.pumpAndSettle();
  expect(tester.widget<EditableText>(field.first).controller.text, passphrase);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await waitForWidgetAndTap(
    tester,
    find.descendant(
      of: find.byType(PassphraseVerificationScreen),
      matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
    ),
    'start verification',
  );
  if (await waitForWidget(tester, find.byType(PinCheckScreen), timeoutSeconds: 5)) {
    await tester.pump(const Duration(seconds: 1));
    for (var i = 0; i < _appPin.length; i++) {
      await waitForWidgetAndTap(
        tester,
        find.descendant(of: find.byType(PinCheckScreen), matching: find.text(_appPin[i])).first,
        'pin digit',
      );
    }
  }
  // 검사가 끝나면 입력값이 직전 검사값과 같아져 '검사 시작' 버튼이 비활성이 된다.
  // 로딩·PIN 화면이 모두 사라지고 버튼이 비활성일 때 이번 검사의 결과를 읽는다.
  final startButton = find.descendant(
    of: find.byType(PassphraseVerificationScreen),
    matching: find.byType(FixedBottomButton),
  );
  final loading = find.text(t.verify_passphrase_screen.loading_description);
  // 인증과 로딩 사이의 짧은 틈을 끝난 것으로 오인하지 않도록 3초 연속으로 조건을 만족해야 한다.
  var stableSeconds = 0;
  for (var i = 0; i < 90 && stableSeconds < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
    final finished =
        loading.evaluate().isEmpty &&
        find.byType(PinCheckScreen).evaluate().isEmpty &&
        !tester.widget<FixedBottomButton>(startButton).isActive;
    stableSeconds = finished ? stableSeconds + 1 : 0;
  }
  await tester.pumpAndSettle();
  final success = find.text(t.verify_passphrase_screen.result_title_success);
  final failure = find.text(t.verify_passphrase_screen.result_title_failure);
  if (success.evaluate().isNotEmpty) return true;
  if (failure.evaluate().isNotEmpty) return false;
  fail('verification result did not appear');
}

Future<void> _openPassphraseVerification(WidgetTester tester, int walletId) async {
  Navigator.pushNamed(
    tester.element(find.byType(VaultHomeScreen)),
    AppRoutes.passphraseVerification,
    arguments: {'id': walletId},
  );
  await tester.pumpAndSettle();
}

/// 탭루트 생성 흐름의 니모닉 퀴즈를 푼다. 정답 니모닉은 [TaprootWalletCreationProvider]에 있다.
Future<void> _solveTaprootMnemonicVerification(WidgetTester tester) async {
  expect(await waitForWidget(tester, find.byType(MnemonicVerifyScreen)), isTrue);
  final words = utf8
      .decode(tester.element(find.byType(MnemonicVerifyScreen)).read<TaprootWalletCreationProvider>().secret)
      .split(' ');
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
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('생성: 정규화로 바뀌는 패스프레이즈에 강화 경고, 공백만 있으면 공백 경고', (tester) async {
    await _launch(tester);
    await openSingleSigOptions(tester);
    await openCreationMethod(tester, creationRoutes.auto, hasSecurityCheck: true);
    expect(await waitForWidget(tester, find.byType(MnemonicAutoGenScreen)), isTrue);
    await selectTwelveWords(tester, selectNoPassphrase: false);
    await waitForWidgetAndTap(tester, find.byKey(const ValueKey('passphrase-yes')), 'use passphrase');
    await dismissMnemonicWarning(tester);
    await tester.drag(find.byType(MnemonicAutoGenScreen), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tapEntropyNext(tester);

    final fields = find.descendant(of: find.byType(MnemonicAutoGenScreen), matching: find.byType(EditableText));
    expect(await waitForWidget(tester, fields), isTrue);
    Future<void> enterBoth(String passphrase, String confirm) async {
      await tester.enterText(fields.at(0), passphrase);
      await tester.enterText(fields.at(1), confirm);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }

    final normalizationWarning = find.textContaining(t.mnemonic_generate_screen.passphrase_warning_normalization);

    await enterBoth(_koreanPassphrase, _koreanPassphrase);
    expect(normalizationWarning, findsOneWidget);
    expect(find.textContaining(t.mnemonic_generate_screen.passphrase_warning(words: '코, 넛')), findsOneWidget);

    await enterBoth(_koreanPassphrase, '다른값');
    expect(find.textContaining(t.mnemonic_generate_screen.passphrase_not_matched), findsOneWidget);

    await enterBoth('co conut', 'co conut');
    expect(find.textContaining(t.mnemonic_generate_screen.passphrase_warning_space), findsOneWidget);
    expect(normalizationWarning, findsNothing);

    await enterBoth('coconut', 'coconut');
    expect(normalizationWarning, findsNothing);
    expect(find.textContaining(t.mnemonic_generate_screen.passphrase_warning_space), findsNothing);
  });

  testWidgets('생성: 최종 확인 화면에 패스프레이즈를 입력한 모양 그대로 보여준다 (일본어 탁음, 호환 문자)', (tester) async {
    await _launch(tester);
    await openSingleSigOptions(tester);
    await openCreationMethod(tester, creationRoutes.auto, hasSecurityCheck: true);
    expect(await waitForWidget(tester, find.byType(MnemonicAutoGenScreen)), isTrue);
    await selectTwelveWords(tester, selectNoPassphrase: false);
    await waitForWidgetAndTap(tester, find.byKey(const ValueKey('passphrase-yes')), 'use passphrase');
    await dismissMnemonicWarning(tester);
    await tester.drag(find.byType(MnemonicAutoGenScreen), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tapEntropyNext(tester);
    final fields = find.descendant(of: find.byType(MnemonicAutoGenScreen), matching: find.byType(EditableText));
    expect(await waitForWidget(tester, fields), isTrue);
    await tester.enterText(fields.at(0), 'がｶ①');
    await tester.enterText(fields.at(1), 'がｶ①');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await waitForWidgetAndTap(
      tester,
      find.descendant(
        of: find.byType(MnemonicAutoGenScreen),
        matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
      ),
      'passphrase next',
    );
    await solveMnemonicVerification(tester);
    await _expectPassphraseConfirmation(tester, ['が', 'ｶ', '①']);
  });

  testWidgets('가져오기: 최종 확인 화면에 패스프레이즈를 입력한 모양 그대로 보여준다 (일본어 탁음, 호환 문자)', (tester) async {
    await _launch(tester);
    await _openMnemonicImportWithPassphrase(tester, 'がｶ①');
    await _tapImportNext(tester);
    expect(await waitForWidget(tester, find.byType(PassphraseWalletSelectionBottomSheet)), isTrue);
    await _confirmSelection(tester, PassphraseEncoding.nfkd);
    await _expectPassphraseConfirmation(tester, ['が', 'ｶ', '①']);
  });

  testWidgets('탭루트 부모 키 생성: 최종 확인 화면에 패스프레이즈를 입력한 모양 그대로 보여준다', (tester) async {
    await _launch(tester);
    await waitForWidgetAndTap(tester, find.byKey(const ValueKey('vault-home-add')).hitTestable(), 'vault add');
    expect(await waitForWidget(tester, find.byType(VaultTypeSelectionScreen)), isTrue);
    await waitForWidgetAndTap(tester, find.text(t.taproot.taproot_inheritance_wallet), 'taproot option');
    await waitForWidgetAndTap(
      tester,
      find.text(t.taproot.taproot_creation_option.parent_creation_title),
      'parent creation',
    );
    expect(await waitForWidget(tester, find.byType(ParentCreationScreen)), isTrue);
    Future<void> next(String name) async {
      final button = find.byKey(const ValueKey('fixed-bottom-button-action')).hitTestable();
      await waitForWidget(tester, button, timeoutMessage: '$name next not found');
      await tester.tap(button.last);
      await tester.pumpAndSettle();
    }

    await next('intro');
    await waitForWidgetAndTap(tester, find.text(t.taproot.parent_creation_screen.step_1.single_sig_wallet), 'single');
    await next('wallet type');
    await waitForWidgetAndTap(tester, find.text(t.taproot.common.prepare_key_option1_title), 'create key');
    await next('key preparation');
    await waitForWidgetAndTap(tester, find.text(t.taproot.common.new_option3), 'auto generate');
    await next('creation option');

    // 보안 자가 점검
    expect(await waitForWidget(tester, find.byType(SecuritySelfCheckScreen)), isTrue);
    final checklistItems = find.byType(ChecklistTile);
    for (var index = 0; index < checklistItems.evaluate().length; index++) {
      final item = checklistItems.at(index);
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    await next('security self-check');

    expect(await waitForWidget(tester, find.byType(MnemonicAutoGenScreen)), isTrue);
    await selectTwelveWords(tester, selectNoPassphrase: false);
    await waitForWidgetAndTap(tester, find.byKey(const ValueKey('passphrase-yes')), 'use passphrase');
    await dismissMnemonicWarning(tester);
    await tester.drag(find.byType(MnemonicAutoGenScreen), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tapEntropyNext(tester);
    final fields = find.descendant(of: find.byType(MnemonicAutoGenScreen), matching: find.byType(EditableText));
    expect(await waitForWidget(tester, fields), isTrue);
    await tester.enterText(fields.at(0), 'がｶ①');
    await tester.enterText(fields.at(1), 'がｶ①');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await waitForWidgetAndTap(
      tester,
      find.descendant(
        of: find.byType(MnemonicAutoGenScreen),
        matching: find.byKey(const ValueKey('fixed-bottom-button-action')),
      ),
      'passphrase next',
    );
    await _solveTaprootMnemonicVerification(tester);
    await _expectPassphraseConfirmation(tester, ['が', 'ｶ', '①']);
  });

  testWidgets('가져오기: 정규화로 바뀌지 않는 패스프레이즈는 선택 없이 진행한다', (tester) async {
    await _launch(tester);
    await _openMnemonicImportWithPassphrase(tester, 'coconut');
    await _tapImportNext(tester);
    expect(await waitForWidget(tester, find.byType(MnemonicConfirmationScreen)), isTrue);
    expect(find.byType(PassphraseWalletSelectionBottomSheet), findsNothing);
  });

  testWidgets('가져오기: 선택 시트를 닫으면 입력값을 유지한 채 가져오기 화면에 머문다', (tester) async {
    await _launch(tester);
    await _openMnemonicImportWithPassphrase(tester, _koreanPassphrase);
    await _tapImportNext(tester);
    await _expectSelectionSheet(tester);

    await tester.tapAt(const Offset(20, 120)); // 시트 바깥(배리어)
    await tester.pumpAndSettle();

    expect(find.byType(PassphraseWalletSelectionBottomSheet), findsNothing);
    expect(find.byType(MnemonicImportScreen), findsOneWidget);
    expect(find.text(_koreanPassphrase), findsOneWidget);
  });

  testWidgets('가져오기·검증: NFKD/이전 방식 지갑을 각각 가져오고 다시 입력한 패스프레이즈로 확인한다', (tester) async {
    await _launch(tester);

    // 기본값(NFKD)으로 가져오기
    await _openMnemonicImportWithPassphrase(tester, _koreanPassphrase);
    await _tapImportNext(tester);
    await _expectSelectionSheet(tester);
    await _confirmSelection(tester, PassphraseEncoding.nfkd);
    final nfkdWallet = await _saveWallet(tester, 'NFKD Vault');
    expect(nfkdWallet.mfp, _nfkdMfp);

    // 같은 지갑을 같은 방식으로 다시 가져오면 중복
    await _openMnemonicImportWithPassphrase(tester, _koreanPassphrase);
    await _tapImportNext(tester);
    await _expectSelectionSheet(tester);
    await _confirmSelection(tester, PassphraseEncoding.nfkd);
    expect(await waitForWidget(tester, find.text(t.toast.mnemonic_already_added), timeoutSeconds: 10), isTrue);

    // 이전 방식은 다른 지갑이므로 추가된다
    await _tapImportNext(tester);
    await _expectSelectionSheet(tester);
    await _confirmSelection(tester, PassphraseEncoding.legacyUtf8);
    final legacyWallet = await _saveWallet(tester, 'Legacy Vault');
    expect(legacyWallet.mfp, _legacyMfp);

    // 다시 입력한 패스프레이즈 검증: 두 지갑 모두 같은 입력으로 통과하고, 틀린 입력은 실패
    await _openPassphraseVerification(tester, nfkdWallet.id);
    expect(await _verifyPassphrase(tester, _koreanPassphrase), isTrue);
    expect(await _verifyPassphrase(tester, '코코넛2025'), isFalse);
    Navigator.of(tester.element(find.byType(PassphraseVerificationScreen))).pop();
    await tester.pumpAndSettle();

    await _openPassphraseVerification(tester, legacyWallet.id);
    expect(await _verifyPassphrase(tester, _koreanPassphrase), isTrue);
    expect(await _verifyPassphrase(tester, '코코넛2025'), isFalse);
  });
}
