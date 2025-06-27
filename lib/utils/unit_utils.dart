import 'package:coconut_vault/enums/currency_enum.dart';

class UnitUtil {
  static double satoshiToBitcoin(int satoshi) {
    return satoshi / 100000000.0;
  }
}

/// 사용자 친화적 형식의 비트코인 단위의 잔액
///
/// @param satoshi 사토시 단위 잔액
/// @returns String 비트코인 단위 잔액 문자열 예) 00,000,000.0000 0000
String _satoshiToBitcoinString(int satoshi, {bool forceEightDecimals = false}) {
  double toBitcoin = UnitUtil.satoshiToBitcoin(satoshi);

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
      integerPart == '-0' ? '-0' : addCommasToIntegerPart(double.parse(integerPart));

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

String addCommasToIntegerPart(double number) {
  // 정수 부분 추출
  String integerPart = number.toInt().toString();

  // 세 자리마다 콤마 추가
  RegExp regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  integerPart = integerPart.replaceAllMapped(regex, (Match match) => '${match[1]},');

  return integerPart;
}

String formatBitcoinValue(int? amount, BitcoinUnit unit, {bool withUnit = false}) {
  if (amount == null) return '';
  String amountText = unit == BitcoinUnit.btc
      ? _satoshiToBitcoinString(amount)
      : addCommasToIntegerPart(amount.toDouble());
  return withUnit ? "$amountText ${unit.symbol()}" : amountText;
}
