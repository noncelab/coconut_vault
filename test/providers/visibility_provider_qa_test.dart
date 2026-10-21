// QA generated host test (overlay). Existing number-format preset cases kept as-is.
// Added (logic_coverage.autofill): VisibilityProvider.updateIsSigningOnlyMode
// Intent (8eadd457 "refactor(지갑개수): 중복된 정보를 제거 - 버그와 데이터 불일치의 원인이 됨"):
//   모드 전환은 패스프레이즈/계정 변경 허용만 동기화한다(서명전용=true, 안전저장=false, 생성자 규칙과 동일).
//   지갑 개수(VAULT_LIST_LENGTH)는 더 이상 저장/삭제하지 않는다. 같은 모드로의 호출은 아무것도 바꾸지 않는다.
import 'package:coconut_vault/config/number_format_config.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/number_format_preset.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<VisibilityProvider> providerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await SharedPrefsRepository().init();
    return VisibilityProvider(isSigningOnlyMode: true);
  }

  tearDown(() {
    NumberFormatConfig.instance.applyPreset(NumberFormatPreset.dotDecimal);
  });

  test('saved number-format preset initializes provider and global formatter', () async {
    final provider = await providerWith({SharedPrefsKeys.kNumberFormatPreset: 'swiss'});

    expect(provider.numberFormatPreset, NumberFormatPreset.swiss);
    expect(provider.decimalSeparator, '.');
    expect(provider.groupingSeparator, '\u2019');
    expect(NumberFormatConfig.instance.preset, NumberFormatPreset.swiss);
  });

  test('unknown saved preset safely falls back to dot-decimal', () async {
    final provider = await providerWith({SharedPrefsKeys.kNumberFormatPreset: 'unknown'});

    expect(provider.numberFormatPreset, NumberFormatPreset.dotDecimal);
    expect(NumberFormatConfig.instance.preset, NumberFormatPreset.dotDecimal);
  });

  test('changing preset persists it, updates formatter, and notifies listeners', () async {
    final provider = await providerWith({SharedPrefsKeys.kNumberFormatPreset: 'dotDecimal'});
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.changeNumberFormatPreset(NumberFormatPreset.commaDecimal);

    expect(provider.numberFormatPreset, NumberFormatPreset.commaDecimal);
    expect(provider.decimalSeparator, ',');
    expect(provider.groupingSeparator, '.');
    expect(NumberFormatConfig.instance.preset, NumberFormatPreset.commaDecimal);
    expect(SharedPrefsRepository().getString(SharedPrefsKeys.kNumberFormatPreset), 'commaDecimal');
    expect(notifications, 1);
  });

  test('first initialization stores a locale-derived supported preset', () async {
    final provider = await providerWith({});

    expect(NumberFormatPreset.values, contains(provider.numberFormatPreset));
    expect(SharedPrefsRepository().getString(SharedPrefsKeys.kNumberFormatPreset), provider.numberFormatPreset.name);
  });

  group('updateIsSigningOnlyMode', () {
    Future<VisibilityProvider> providerFor({required bool signingOnly, Map<String, Object> values = const {}}) async {
      SharedPreferences.setMockInitialValues({SharedPrefsKeys.kNumberFormatPreset: 'dotDecimal', ...values});
      await SharedPrefsRepository().init();
      return VisibilityProvider(isSigningOnlyMode: signingOnly);
    }

    test('안전저장 -> 서명전용: 패스프레이즈/계정 변경 허용을 켜고 저장한다', () async {
      final provider = await providerFor(
        signingOnly: false,
        values: {SharedPrefsKeys.kPassphraseUseEnabled: false, SharedPrefsKeys.kChangeAccountEnabled: false},
      );
      expect(provider.isPassphraseUseEnabled, isFalse);

      await provider.updateIsSigningOnlyMode(true);

      expect(provider.isPassphraseUseEnabled, isTrue);
      expect(provider.isAccountEditEnabled, isTrue);
      expect(SharedPrefsRepository().getBool(SharedPrefsKeys.kPassphraseUseEnabled), isTrue);
      expect(SharedPrefsRepository().getBool(SharedPrefsKeys.kChangeAccountEnabled), isTrue);
    });

    test('서명전용 -> 안전저장: 패스프레이즈/계정 변경 허용을 끄고 저장한다', () async {
      final provider = await providerFor(signingOnly: true);
      expect(provider.isPassphraseUseEnabled, isTrue);

      await provider.updateIsSigningOnlyMode(false);

      expect(provider.isPassphraseUseEnabled, isFalse);
      expect(provider.isAccountEditEnabled, isFalse);
      expect(SharedPrefsRepository().getBool(SharedPrefsKeys.kPassphraseUseEnabled), isFalse);
      expect(SharedPrefsRepository().getBool(SharedPrefsKeys.kChangeAccountEnabled), isFalse);
    });

    test('같은 모드로 호출하면 아무것도 바꾸지 않고 알리지 않는다', () async {
      final provider = await providerFor(
        signingOnly: false,
        values: {SharedPrefsKeys.kPassphraseUseEnabled: true, SharedPrefsKeys.kChangeAccountEnabled: false},
      );
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.updateIsSigningOnlyMode(false);

      expect(provider.isPassphraseUseEnabled, isTrue);
      expect(provider.isAccountEditEnabled, isFalse);
      expect(notifications, 0);
    });

    test('모드 전환은 레거시 VAULT_LIST_LENGTH 키를 쓰지 않는다 (양방향)', () async {
      final provider = await providerFor(signingOnly: false);

      await provider.updateIsSigningOnlyMode(true);
      expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kDeprecatedVaultListLength), isFalse);

      await provider.updateIsSigningOnlyMode(false);
      expect(SharedPrefsRepository().isContainsKey(SharedPrefsKeys.kDeprecatedVaultListLength), isFalse);
    });

    test('전환 후 다시 원래 모드로 돌아가면 다시 동기화된다', () async {
      final provider = await providerFor(signingOnly: false);

      await provider.updateIsSigningOnlyMode(true);
      await provider.updateIsSigningOnlyMode(false);

      expect(provider.isPassphraseUseEnabled, isFalse);
      expect(provider.isAccountEditEnabled, isFalse);
    });
  });
}
