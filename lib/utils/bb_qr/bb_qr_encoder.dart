import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:base32/base32.dart';
import 'package:coconut_vault/utils/logger.dart';

class BbQrEncoder {
  static List<String> encode({
    required String data,
    String dataType = 'U',
    String encodingType = 'Z',
    int maxFragmentLength = 1200,
  }) {
    try {
      List<int> rawBytes = utf8.encode(data);
      List<int> processedBytes;

      if (encodingType == 'Z') {
        // ZLibEncoder 대신 Deflate 클래스 직접 사용
        // ZLibEncoder().encode() => RFC 1950 (헤더 O, 체크섬 O) -> 콜드카드 실패 가능성
        // Deflate(bytes).getBytes() => RFC 1951 (헤더 X, 체크섬 X, Raw Deflate)
        processedBytes = Deflate(rawBytes).getBytes();
      } else if (encodingType == '2') {
        processedBytes = rawBytes;
      } else if (encodingType == 'H') {
        processedBytes = rawBytes;
      } else {
        throw Exception('Unsupported encoding type: $encodingType');
      }

      if (processedBytes.isEmpty) {
        Logger.log('--> BbQrEncoder: processedBytes is empty');
        return [];
      }

      List<List<int>> chunks = [];
      for (int i = 0; i < processedBytes.length; i += maxFragmentLength) {
        int end = (i + maxFragmentLength < processedBytes.length) ? i + maxFragmentLength : processedBytes.length;
        chunks.add(processedBytes.sublist(i, end));
      }

      int total = chunks.length;
      if (total > 1295) {
        throw Exception('Data too large: exceeds BBQr fragment limit.');
      }

      List<String> qrStrings = [];

      for (int i = 0; i < total; i++) {
        String totalStr = total.toRadixString(36).toUpperCase().padLeft(2, '0');
        String indexStr = i.toRadixString(36).toUpperCase().padLeft(2, '0');

        String header = 'B\$$encodingType$dataType$totalStr$indexStr';
        String payload;

        if (encodingType == 'H') {
          payload = utf8.decode(chunks[i]);
        } else {
          payload = base32.encode(Uint8List.fromList(chunks[i]));

          payload = payload.replaceAll('=', '');
        }

        qrStrings.add(header + payload);
      }

      return qrStrings;
    } catch (e, st) {
      Logger.log('--> BbQrEncoder.encode error: $e\n$st');
      return [];
    }
  }
}
