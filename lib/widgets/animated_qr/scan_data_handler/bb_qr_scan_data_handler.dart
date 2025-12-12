import 'dart:convert';

import 'package:coconut_vault/utils/bb_qr/bb_qr_decoder.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_fragmented_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/scan_data_handler_exceptions.dart';

class BbQrScanDataHandler implements IFragmentedQrScanDataHandler {
  BbQrDecoder _bbqrDecoder;
  int? _sequenceLength;
  String? _dataType; // BBQR 데이터 타입 저장
  dynamic _rawResult; // Tx Raw 데이터 저장 (hex)
  String? _psbtBase64; // PSBT base64 문자열 저장

  BbQrScanDataHandler() : _bbqrDecoder = BbQrDecoder();

  @override
  dynamic get result {
    // PSBT인 경우 미리 처리된 base64 문자열 반환
    if (_psbtBase64 != null) {
      return _psbtBase64;
    }
    final result = _rawResult ?? _bbqrDecoder.result;
    return result;
  }

  @override
  double get progress {
    final progress = _rawResult != null ? 1.0 : _bbqrDecoder.progress;
    return progress;
  }

  @override
  bool isCompleted() {
    final completed = _rawResult != null || _bbqrDecoder.isComplete;
    return completed;
  }

  @override
  bool joinData(String data) {
    // 먼저 Raw Tx 데이터인지 확인 (BBQR 헤더가 없는 경우)
    if (!data.startsWith('B\$')) {
      _rawResult = data;
      return true;
    }

    // BBQR 데이터 처리
    if (_sequenceLength == null) {
      final sequenceLength = parseSequenceLength(data);
      if (sequenceLength == null) return false;
      _sequenceLength = sequenceLength;

      if (data.startsWith('B\$') && data.length >= 8) {
        _dataType = data[3];
      }
    }

    final receivePartResult = _bbqrDecoder.receivePart(data);

    if (!receivePartResult && validateFormat(data)) {
      final sequenceValidationResult = validateSequenceLength(data);
      if (!sequenceValidationResult) throw SequenceLengthMismatchException();
    }

    if (_bbqrDecoder.isComplete && _bbqrDecoder.result == null) {
      if (_dataType == 'P') {
        // PSBT인 경우 바이너리 데이터를 base64로 인코딩
        _psbtBase64 = _getPsbtBase64();
      } else if (_dataType == 'T') {
        _bbqrDecoder.parseHexData();
      } else {
        _bbqrDecoder.parseJson();
      }
    }

    return receivePartResult;
  }

  /// PSBT 바이너리 데이터를 base64 문자열로 변환
  String? _getPsbtBase64() {
    try {
      // PSBT는 바이너리 데이터이므로 UTF-8 디코딩을 시도하지 않고
      // 바로 parseHexData()를 사용하여 바이너리 데이터 얻기
      final hexData = _bbqrDecoder.parseHexData();
      if (hexData is String) {
        // hex 문자열을 바이너리로 변환 후 base64로 인코딩
        try {
          // hex 문자열이 짝수 길이인지 확인
          if (hexData.length % 2 != 0) {
            Logger.log('--> BbQrScanDataHandler._getPsbtBase64: hex string length is odd');
            return null;
          }

          final bytes = List<int>.generate(
            hexData.length ~/ 2,
            (i) => int.parse(hexData.substring(i * 2, i * 2 + 2), radix: 16),
          );
          return base64Encode(bytes);
        } catch (e) {
          Logger.log('--> BbQrScanDataHandler._getPsbtBase64: hex decode error: $e');
        }
      }

      return null;
    } catch (e, st) {
      Logger.log('--> BbQrScanDataHandler._getPsbtBase64 error: $e\n$st');
      return null;
    }
  }

  int? parseSequenceLength(String data) {
    try {
      if (!data.startsWith('B\$') || data.length < 8) return null;

      final header = data.substring(0, 8);
      final totalStr = header.substring(4, 6);

      final total = int.parse(totalStr, radix: 36);

      return total;
    } catch (_) {
      return null;
    }
  }

  @override
  bool validateFormat(String data) {
    try {
      // Raw Tx 데이터인 경우 true 반환
      if (data.startsWith('02000000')) {
        return true;
      }

      // BBQR 형식만 검증 (parseJson 호출하지 않음)
      if (!data.startsWith('B\$') || data.length < 8) return false;

      final header = data.substring(0, 8);
      if (header.length != 8) return false;

      // encoding, dataType, total, index 형식 검증
      final encoding = header[2];
      final dataType = header[3];
      final totalStr = header.substring(4, 6);
      final indexStr = header.substring(6, 8);

      // B$2J: json+base32, export wallet 형식
      // B$HT: hex+base32, psbt 형식
      // B$2T: transaction+base32, transaction 형식

      // encoding: 2(base32), Z(zlib+base32) H(hex)
      if (encoding != '2' && encoding != 'Z' && encoding != 'H') return false;
      // dataType: J(Json), P(PSBT), T(Transaction/Text)
      if (!['J', 'P', 'T'].contains(dataType)) return false;

      // total, index가 base36 숫자인지 확인
      try {
        int.parse(totalStr, radix: 36);
        int.parse(indexStr, radix: 36);
      } catch (e) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void reset() {
    _sequenceLength = null;
    _dataType = null;
    _rawResult = null;
    _psbtBase64 = null;
    _bbqrDecoder = BbQrDecoder();
  }

  @override
  int? get sequenceLength => _sequenceLength;

  @override
  bool validateSequenceLength(String data) {
    if (_sequenceLength == null) {
      throw SequenceLengthNotInitializedException();
    }
    return _sequenceLength == parseSequenceLength(data);
  }
}
