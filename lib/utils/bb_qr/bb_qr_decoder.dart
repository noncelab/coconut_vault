import 'dart:convert';
import 'dart:io';
import 'package:base32/base32.dart';
import 'package:coconut_vault/utils/logger.dart';

class BbQrDecoder {
  // ColdCard Q1 Export Multisig Wallet Data
  /// ex: B$ZU0100
  ///     B$2J0700...
  ///    (B$[encoding][dataType][total][index][payload])
  ///
  /// B$: 고정 prefix (BBQR 시작을 표시)
  /// encoding: 압축 및 인코딩 형식:
  ///   - 2 : Base32 (RFC 4648)
  ///   - Z : Zlib raw deflate + Base32
  ///   - H : Hex (payload 자체가 hex string)
  /// dataType: 데이터 유형:
  ///   - J : JSON
  ///   - U : Unicode simple text (UTF-8)
  ///   - P : PSBT
  ///   - T : TXN
  ///   - A/M/S ... 기타 Coldcard 타입
  /// total: 전체 QR 조각 수(2자리 base36 숫자)
  /// index: 현재 QR 조각의 순서(2자리 base36 숫자)
  /// payload: 인코딩된 데이터

  final Map<int, List<int>> _chunks = {};
  int? _expectedTotal;
  bool _isComplete = false;
  dynamic _result;

  String? _encodingType;
  String? _dataType;

  dynamic get result => _result;
  int? get expectedTotal => _expectedTotal;
  int get receivedCount => _chunks.length;
  bool get isComplete => _isComplete;

  String? get encodingType => _encodingType;
  String? get dataType => _dataType;

  bool receivePart(String part) {
    if (!part.startsWith('B\$') || part.length < 9 || _isComplete) {
      return false;
    }

    try {
      final header = part.substring(0, 8);
      final encodingType = header.substring(2, 3);
      final dataType = header.substring(3, 4);
      final totalStr = header.substring(4, 6);
      final indexStr = header.substring(6, 8);
      const dataStartIndex = 8;

      final total = int.parse(totalStr, radix: 36);
      final index = int.parse(indexStr, radix: 36);

      if (total <= 0 || index < 0 || index >= total) {
        Logger.log(
          '--> BbQrDecoder.receivePart: invalid total/index '
          '(total: $total, index: $index)',
        );
        return false;
      }

      _encodingType ??= encodingType;
      _dataType ??= dataType;
      _expectedTotal ??= total;

      if (_encodingType != encodingType || _dataType != dataType || _expectedTotal != total) {
        Logger.log(
          '--> BbQrDecoder.receivePart: header mismatch '
          '(encoding: $_encodingType vs $encodingType, '
          'dataType: $_dataType vs $dataType, '
          'total: $_expectedTotal vs $total)',
        );
        return false;
      }

      if (_chunks.containsKey(index)) {
        return false;
      }

      final payloadData = part.substring(dataStartIndex);
      List<int> rawBytes;

      if (encodingType == 'H') {
        // HEX: utf8 bytes로 저장
        rawBytes = utf8.encode(payloadData);
      } else if (encodingType == '2' || encodingType == 'Z') {
        // Base32: 압축해제하지 않고, base32 → raw deflate bytes만 저장
        rawBytes = base32.decode(payloadData);
      } else {
        // 알 수 없는 encoding 타입
        Logger.log('--> BbQrDecoder.receivePart: unknown encoding $encodingType');
        return false;
      }

      _chunks[index] = rawBytes;

      if (_chunks.length == _expectedTotal) {
        _isComplete = true;
      }
      return true;
    } catch (e, st) {
      Logger.log('--> BbQrDecoder.receivePart error: $e\n$st');
      return false;
    }
  }

  /// 모든 조각이 모였는지 확인
  bool checkComplete() => _isComplete;

  /// 내부: 조각들을 index 순서대로 합친 raw bytes
  ///
  /// - encoding == 'Z' 인 경우: 아직 압축 해제 전(raw deflate)
  /// - encoding == '2' 인 경우: 원본 바이너리
  /// - encoding == 'H' 인 경우: ASCII hex 문자열의 UTF-8 bytes
  List<int>? _combinedBytes() {
    if (!_isComplete || _expectedTotal == null) return null;

    final combinedBytes = <int>[];
    for (int i = 0; i < _expectedTotal!; i++) {
      final chunk = _chunks[i];
      if (chunk == null) {
        return null;
      }
      combinedBytes.addAll(chunk);
    }
    return combinedBytes;
  }

  /// raw deflate(Zlib raw) 압축 해제
  List<int> _decompressRawDeflate(List<int> compressed) {
    // ZLibCodec(raw: true) => raw deflate (no header/footer)
    return ZLibCodec(raw: true).decode(compressed);
  }

  /// 조각을 합쳐서 UTF-8 문자열 반환
  ///
  /// - encodingType == 'Z' → 전체를 합친 후 한 번에 raw deflate 해제 → UTF-8
  /// - encodingType == '2' → 그대로 UTF-8로 디코딩
  /// - encodingType == 'H' → ASCII hex string 이므로 UTF-8 문자열로 반환
  String? getCombinedText() {
    final combined = _combinedBytes();
    if (combined == null) return null;

    List<int> bytes;

    if (_encodingType == 'Z') {
      try {
        bytes = _decompressRawDeflate(combined);
      } catch (e, st) {
        Logger.log('--> BbQrDecoder.getCombinedText: zlib error: $e\n$st');
        return null;
      }
    } else {
      bytes = combined;
    }

    try {
      return utf8.decode(bytes);
    } catch (e, st) {
      Logger.log('--> BbQrDecoder.getCombinedText: utf8 decode error: $e\n$st');
      return null;
    }
  }

  /// 아래 필요한지 확인할 것
  /// 기존 이름과 호환을 위해 유지 (실제론 일반 텍스트일 수 있음)
  String? getCombinedJsonString() => getCombinedText();

  /// JSON 파싱 결과 반환 (J 타입일 때 사용)
  dynamic parseJson() {
    final jsonString = getCombinedText();
    if (jsonString == null) {
      return null;
    }
    try {
      _result = json.decode(jsonString);
      return _result;
    } catch (e, st) {
      Logger.log('--> BbQrDecoder.parseJson: json decode error: $e\n$st');
      return null;
    }
  }

  /// Hex/바이너리 데이터 파싱 결과 반환
  ///
  /// - encoding == 'H':
  ///     payload 전체가 hex 문자열 → 그대로 반환 (필요시 추가 파싱)
  /// - encoding == '2' 또는 'Z':
  ///     바이너리 → hex string 으로 변환
  ///     (앞에 '303230' 이면 ASCII 문자열로 한 번 더 해석)
  dynamic parseHexData() {
    final combined = _combinedBytes();
    if (combined == null) return null;

    try {
      if (_encodingType == 'H') {
        // HEX 인 경우: combined 는 ASCII hex string 의 UTF-8 bytes
        final hexString = utf8.decode(combined);
        _result = hexString;

        // 필요시 hexString 을 다시 바이너리/문자열로 해석할 수도 있음
        if (hexString.startsWith('303230')) {
          final list = List.generate(hexString.length ~/ 2, (i) {
            return int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16);
          });
          _result = String.fromCharCodes(list);
        }

        return _result;
      } else {
        // 2 / Z: 바이너리 → (필요시 압축 해제) → hex string
        List<int> bytes;
        if (_encodingType == 'Z') {
          bytes = _decompressRawDeflate(combined);
        } else {
          bytes = combined;
        }

        String hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

        // 첫 바이트가 '303230' 이면 ASCII 문자열로 변환 시도
        if (hex.startsWith('303230')) {
          final list = List.generate(hex.length ~/ 2, (i) {
            return int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
          });
          _result = String.fromCharCodes(list);
        } else {
          _result = hex;
        }
        return _result;
      }
    } catch (e, st) {
      Logger.log('--> BbQrDecoder.parseHexData: error: $e\n$st');
      return null;
    }
  }

  /// 진행률 (0~1)
  double get progress {
    if (_expectedTotal == null || _expectedTotal == 0) return 0;
    final p = (_chunks.length / _expectedTotal!).clamp(0, 1);
    return p.toDouble();
  }

  /// 상태 초기화
  void reset() {
    _chunks.clear();
    _expectedTotal = null;
    _isComplete = false;
    _result = null;
    _encodingType = null;
    _dataType = null;
  }
}
