import 'dart:typed_data';

class ConversionUtil {
  /// 16진수 문자열을 바이트 배열로 변환
  static Uint8List hexToBytes(String hex) {
    hex = hex.replaceAll(' ', '').replaceAll('\n', '');
    final out = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  /// 16진수 문자열을 정수로 변환
  static int hexToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  /// 4바이트 Uint8List를 big endian 정수로 변환
  static int uint8ListToInt(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    return bd.getUint32(0, Endian.big);
  }

  static String bytesToHex(Uint8List bytes, {bool upperCase = false}) {
    final StringBuffer buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return upperCase ? buffer.toString().toUpperCase() : buffer.toString();
  }

  static Uint8List bitsToBytes(List<int> bits) {
    assert(bits.every((bit) => bit == 0 || bit == 1));

    List<int> eightBits = [];
    if (bits.length < 8) {
      for (int i = 8 - bits.length; i > 0; i--) {
        eightBits.add(0);
      }
      eightBits.addAll(bits);
    } else {
      eightBits.addAll(bits);
    }
    Uint8List bytes = Uint8List(eightBits.length ~/ 8);
    for (int i = 0; i < eightBits.length; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        byte = (byte << 1) | eightBits[i + j];
      }
      bytes[i ~/ 8] = byte;
    }
    return bytes;
  }
}
