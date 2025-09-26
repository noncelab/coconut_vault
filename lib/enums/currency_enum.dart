import 'package:coconut_vault/extensions/int_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/balance_format_util.dart';

enum BitcoinUnit {
  btc,
  sats;

  String get symbol {
    return this == BitcoinUnit.btc ? t.btc : t.sats;
  }

  String displayBitcoinAmount(
    int? amount, {
    String defaultWhenNull = '',
    String defaultWhenZero = '',
    bool shouldCheckZero = false,
    bool withUnit = false,
    bool forceEightDecimals = false,
  }) {
    if (amount == null) return defaultWhenNull;
    if (shouldCheckZero && amount == 0) return defaultWhenZero;

    String amountText = this == BitcoinUnit.btc
        ? BalanceFormatUtil.formatSatoshiToReadableBitcoin(amount, forceEightDecimals: forceEightDecimals)
        : amount.toThousandsSeparatedString();

    return withUnit ? "$amountText $symbol" : amountText;
  }
}
