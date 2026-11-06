import 'package:coconut_vault/config/number_format_config.dart';

extension IntFormatting on int {
  String toThousandsSeparatedString() {
    return _formatWithGroupingSeparator(toString(), NumberFormatConfig.instance.groupingSeparator);
  }
}

String _formatWithGroupingSeparator(String integer, String groupingSeparator) {
  final isNegative = integer.startsWith('-');
  final digits = isNegative ? integer.substring(1) : integer;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(groupingSeparator);
    }
    buffer.write(digits[i]);
  }
  return isNegative ? '-${buffer.toString()}' : buffer.toString();
}
