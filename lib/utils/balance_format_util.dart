import 'package:coconut_vault/extensions/int_extensions.dart';
import 'package:coconut_vault/utils/unit_utils.dart';

class BalanceFormatUtil {
  /// 사용자 친화적 형식의 비트코인 잔액 보이기
  /// balance_format_util_test.dart 참고
  static String formatSatoshiToReadableBitcoin(int satoshi, {bool forceEightDecimals = false}) {
    double toBitcoin = UnitUtil.convertSatoshiToBitcoin(satoshi);

    String bitcoinString;
    if (toBitcoin % 1 == 0) {
      bitcoinString =
          forceEightDecimals ? toBitcoin.toStringAsFixed(8) : toBitcoin.toInt().toString();
    } else {
      bitcoinString = toBitcoin.toStringAsFixed(8);
      if (!forceEightDecimals) {
        bitcoinString = bitcoinString.replaceFirst(RegExp(r'0+$'), '');
      }
    }

    // Split the integer and decimal parts
    List<String> parts = bitcoinString.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    final integerPartFormatted =
        integerPart == '-0' ? '-0' : int.parse(integerPart).toThousandsSeparatedString();

    String decimalPartGrouped = '';
    if (decimalPart.isNotEmpty) {
      if (decimalPart.length <= 4) {
        decimalPartGrouped = decimalPart;
      } else {
        decimalPart = decimalPart.padRight(8, '0');
        // Group the decimal part into blocks of 4 digits
        decimalPartGrouped =
            RegExp(r'.{1,4}').allMatches(decimalPart).map((match) => match.group(0)).join(' ');
      }
    }

    if (integerPartFormatted == '0' && decimalPartGrouped == '') {
      return '0';
    }

    return decimalPartGrouped.isNotEmpty
        ? '$integerPartFormatted.$decimalPartGrouped'
        : integerPartFormatted;
  }
}
