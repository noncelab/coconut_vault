class UnitUtil {
  static double satoshiToBitcoin(int satoshi) {
    return satoshi / 100000000.0;
  }
}

/// 사용자 친화적 형식의 비트코인 단위의 잔액
///
/// @param satoshi 사토시 단위 잔액
/// @returns String 비트코인 단위 잔액 문자열 예) 00,000,000.0000 0000
String satoshiToBitcoinString(int satoshi) {
  var toBitcoin = UnitUtil.satoshiToBitcoin(satoshi);

  String bitcoinString;
  if (toBitcoin % 1 == 0) {
    bitcoinString = toBitcoin.toInt().toString();
  } else {
    bitcoinString = toBitcoin.toStringAsFixed(8); // Ensure it has 8 decimal places
  }

  // Split the integer and decimal parts
  List<String> parts = bitcoinString.split('.');
  String integerPart = parts[0];
  String decimalPart = parts.length > 1 ? parts[1] : '';

  final integerPartFormatted = addCommasToIntegerPart(double.parse(integerPart));

  // Group the decimal part into blocks of 4 digits
  final decimalPartGrouped =
      RegExp(r'.{1,4}').allMatches(decimalPart).map((match) => match.group(0)).join(' ');

  if (integerPartFormatted == '0' && decimalPartGrouped == '') {
    return '0';
  }
  String lastDotRemovedString = '$integerPartFormatted.$decimalPartGrouped';
  if (lastDotRemovedString.endsWith('.')) {
    return lastDotRemovedString.substring(0, lastDotRemovedString.length - 1);
  }
  return lastDotRemovedString;
}

String addCommasToIntegerPart(double number) {
  // 정수 부분 추출
  String integerPart = number.toInt().toString();

  // 세 자리마다 콤마 추가
  RegExp regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  integerPart = integerPart.replaceAllMapped(regex, (Match match) => '${match[1]},');

  return integerPart;
}
