import 'package:coconut_vault/config/number_format_config.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/enums/number_format_preset.dart';
import 'package:coconut_vault/extensions/int_extensions.dart';
import 'package:coconut_vault/utils/balance_format_util.dart';
import 'package:flutter_test/flutter_test.dart';

// 모든 프리셋(dot·comma 외 swiss·frenchSpace 포함): 설정 시트의 예시 라벨이 앱이 실제로 그리는 금액과 같고,
// BTC·sats 표기가 프리셋의 구분자를 따르는지 확인합니다.
void main() {
  tearDown(() => NumberFormatConfig.instance.applyPreset(NumberFormatPreset.dotDecimal));

  const exampleSats = 123456789012; // 1,234.5678 9012 BTC

  for (final preset in NumberFormatPreset.values) {
    group(preset.name, () {
      setUp(() => NumberFormatConfig.instance.applyPreset(preset));

      test('settings label equals the amount the app renders for it', () {
        expect(BalanceFormatUtil.formatSatoshiToReadableBitcoin(exampleSats), preset.displayLabel);
      });

      test('BTC uses the preset decimal and grouping separators', () {
        final d = preset.decimalSeparator;
        final g = preset.groupingSeparator;
        expect(BalanceFormatUtil.formatSatoshiToReadableBitcoin(23456), '0${d}0002 3456');
        expect(BalanceFormatUtil.formatSatoshiToReadableBitcoin(150000), '0${d}0015');
        expect(BalanceFormatUtil.formatSatoshiToReadableBitcoin(100000000000), '1${g}000');
        expect(BalanceFormatUtil.formatSatoshiToReadableBitcoin(-123456789012), '-1${g}234${d}5678 9012');
        expect(BitcoinUnit.btc.displayBitcoinAmount(23456), '0${d}0002 3456');
      });

      test('sats use the preset grouping separator', () {
        final g = preset.groupingSeparator;
        expect(12345678.toThousandsSeparatedString(), '12${g}345${g}678');
        expect(999.toThousandsSeparatedString(), '999');
        expect((-1234567).toThousandsSeparatedString(), '-1${g}234${g}567');
        expect(BitcoinUnit.sats.displayBitcoinAmount(12345678), '12${g}345${g}678');
      });
    });
  }
}
