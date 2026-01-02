import 'dart:convert';
import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:archive/archive.dart';
import 'package:coconut_vault/utils/logger.dart';

class BbQrEncoder {
  final int maxChunkSize;
  final String encodingType; // 예: 'Z' (zlib)
  final String dataType; // 예: 'P' (PSBT)

  BbQrEncoder({
    this.maxChunkSize = 800, // Qr 버전 27에 더 적합한 크기
    this.encodingType = 'Z',
    this.dataType = 'P',
  });

  List<String> encodeBase64(String base64String) {
    final originalBytes = Uint8List.fromList(base64.decode(base64String));

    // raw deflate (RFC1951)
    final compressed = Uint8List.fromList(Deflate(originalBytes).getBytes());

    final chunks = _chunkBytes(compressed, maxChunkSize);
    final total = chunks.length;

    final encodedChunks = <String>[];
    for (int i = 0; i < total; i++) {
      final base32Data = base32.encode(Uint8List.fromList(chunks[i])).replaceAll(RegExp(r'=+$'), '');

      final totalStr = total.toRadixString(36).padLeft(2, '0').toUpperCase();
      final indexStr = i.toRadixString(36).padLeft(2, '0').toUpperCase();

      final header = 'B\$Z$dataType$totalStr$indexStr'; // Z = (raw deflate) + base32
      encodedChunks.add('$header$base32Data');
    }
    return encodedChunks;
  }

  List<List<int>> _chunkBytes(List<int> bytes, int chunkSize) {
    final chunks = <List<int>>[];
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
      chunks.add(bytes.sublist(i, end));
    }
    return chunks;
  }

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
