import 'dart:convert';

import 'package:coconut_vault/packages/bc-ur-dart/lib/ur_decoder.dart';
import 'package:coconut_vault/utils/bb_qr/bb_qr_decoder.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/ur_bytes_converter.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';

/// Coordinator BSMS QR 데이터 처리 핸들러
/// 허용: UR, BBQR, Json, Text
enum CoordinatorBsmsQrDataFormat { ur, bbqr, json, text }

class CoordinatorBsmsQrDataHandler implements IQrScanDataHandler {
  URDecoder _urDecoder;
  BbQrDecoder _bbQrDecoder;

  StringBuffer? _textBuffer;
  StringBuffer? _jsonBuffer;
  dynamic _jsonParsed;

  CoordinatorBsmsQrDataFormat? _dataFormat;

  bool? get isFragmentedDataScanned =>
      _dataFormat == null
          ? null
          : (_dataFormat == CoordinatorBsmsQrDataFormat.ur || _dataFormat == CoordinatorBsmsQrDataFormat.bbqr);

  CoordinatorBsmsQrDataHandler() : _urDecoder = URDecoder(), _bbQrDecoder = BbQrDecoder();

  @override
  dynamic get result {
    switch (_dataFormat) {
      case CoordinatorBsmsQrDataFormat.ur:
        return UrBytesConverter.convertToText(_urDecoder.result);
      case CoordinatorBsmsQrDataFormat.bbqr:
        if (!_bbQrDecoder.isComplete) return null;
        if (_bbQrDecoder.dataType == 'J') {
          return _bbQrDecoder.parseJson();
        }
        return _bbQrDecoder.getCombinedText();
      case CoordinatorBsmsQrDataFormat.json:
        return _jsonParsed ?? _jsonBuffer?.toString();
      case CoordinatorBsmsQrDataFormat.text:
        return _textBuffer?.toString();
      default:
        return null;
    }
  }

  @override
  double get progress {
    switch (_dataFormat) {
      case CoordinatorBsmsQrDataFormat.ur:
        return _urDecoder.estimatedPercentComplete();
      case CoordinatorBsmsQrDataFormat.bbqr:
        return _bbQrDecoder.progress;
      case CoordinatorBsmsQrDataFormat.json:
      case CoordinatorBsmsQrDataFormat.text:
        return isCompleted() ? 1.0 : 0.0;
      default:
        return 0.0;
    }
  }

  @override
  bool joinData(String data) {
    if (!validateFormat(data)) {
      return false;
    }

    final format = _detectFormat(data);
    if (format == null) {
      return false;
    }

    // 입력 포맷이 변경되면 리셋 후 다시 시작
    if (_dataFormat != null && _dataFormat != format) {
      Logger.log(
        '--> CoordinatorBsmsQrDataHandler: format changed '
        'from $_dataFormat to $format, resetting decoder.',
      );
      reset();
    }

    _dataFormat ??= format;

    switch (format) {
      case CoordinatorBsmsQrDataFormat.ur:
        return _urDecoder.receivePart(data);
      case CoordinatorBsmsQrDataFormat.bbqr:
        return _bbQrDecoder.receivePart(data);
      case CoordinatorBsmsQrDataFormat.json:
        _jsonBuffer ??= StringBuffer();
        _jsonBuffer!.write(data);
        _jsonParsed = json.decode(_jsonBuffer.toString());
        return true;
      case CoordinatorBsmsQrDataFormat.text:
        _textBuffer ??= StringBuffer();
        _textBuffer!.write(data);
        return true;
    }
  }

  @override
  bool validateFormat(String data) {
    return _detectFormat(data) != null;
  }

  CoordinatorBsmsQrDataFormat? _detectFormat(String data) {
    final normalized = data.trim().toLowerCase();

    if (normalized.startsWith('ur:')) {
      return CoordinatorBsmsQrDataFormat.ur;
    }
    if (normalized.startsWith('b\$')) {
      return CoordinatorBsmsQrDataFormat.bbqr;
    }
    if (normalized.startsWith('#')) {
      return CoordinatorBsmsQrDataFormat.text;
    }
    if (normalized.startsWith('{')) {
      return CoordinatorBsmsQrDataFormat.json;
    }

    return null;
  }

  @override
  bool isCompleted() {
    switch (_dataFormat) {
      case CoordinatorBsmsQrDataFormat.ur:
        return _urDecoder.isComplete();
      case CoordinatorBsmsQrDataFormat.bbqr:
        return _bbQrDecoder.isComplete;
      case CoordinatorBsmsQrDataFormat.text:
        return _textBuffer != null && _textBuffer!.isNotEmpty;
      case CoordinatorBsmsQrDataFormat.json:
        return _jsonParsed != null;
      default:
        return false;
    }
  }

  @override
  void reset() {
    _urDecoder = URDecoder();
    _bbQrDecoder = BbQrDecoder();
    _dataFormat = null;
    _textBuffer = null;
    _jsonBuffer = null;
    _jsonParsed = null;
  }
}
