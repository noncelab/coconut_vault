import 'package:decimal/decimal.dart';

class UnitUtil {
  static double convertSatoshiToBitcoin(int satoshi) {
    return satoshi / 100000000.0;
  }

  /// 부동 소숫점 연산 시 오차가 발생할 수 있으므로 Decimal이용
  static int convertBitcoinToSatoshi(double bitcoin) {
    return (Decimal.parse(bitcoin.toString()) * Decimal.parse('100000000')).toDouble().toInt();
  }
}
