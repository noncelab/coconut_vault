import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:ur/ur.dart';
import 'package:ur/ur_encoder.dart';
import 'package:ur/cbor_lite.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/i_qr_view_data_handler.dart';

class BcUrQrViewHandler implements IQrViewDataHandler {
  final dynamic _source;
  late String _urType;
  late UREncoder _urEncoder;

  BcUrQrViewHandler(this._source, UrType urType, {Map<String, dynamic>? data, int? maxFragmentLen}) {
    _urType = urType.value;
    UR ur;
    final cborEncoder = CBOREncoder();
    switch (urType) {
      case UrType.cryptoPsbt:
        assert(_source is String);
        final input = base64Decode(_source);
        cborEncoder.encodeBytes(input);
        ur = UR(_urType, cborEncoder.getBytes());
        break;
      case UrType.cryptoAccount:
      case UrType.cryptoOutput:
        // String 또는 Uint8List 모두 처리 가능
        if (_source is String) {
          ur = UR(_urType, utf8.encode(_source));
        } else if (_source is Uint8List) {
          ur = UR(_urType, _source);
        } else {
          throw ArgumentError(
            'UrType.cryptoAccount and UrType.cryptoOutput require String or Uint8List, but got ${_source.runtimeType}',
          );
        }
        break;
      case UrType.bytes:
        if (_source is String) {
          final sourceBytes = utf8.encode(_source);
          cborEncoder.encodeBytes(sourceBytes);
          ur = UR(_urType, cborEncoder.getBytes());
        } else if (_source is Uint8List) {
          ur = UR(_urType, _source);
        } else {
          throw ArgumentError('UrType.bytes requires String or Uint8List, but got ${_source.runtimeType}');
        }
        break;
    }

    // QR 버전별 최대 데이터 크기 (alphanumeric 모드, Error Correction Level M 기준)
    // Version 5: 약 108 characters = 864 bits
    // Version 7: 약 180 characters = 1440 bits
    // Version 9: 약 272 characters = 2176 bits
    // UR 헤더 길이: 약 20-30자 (실제로는 더 클 수 있음)
    // 데이터: Bytewords.minimal로 인코딩(1바이트 -> 2자)
    // maxFragmentLen이 지정되지 않은 경우 기본값 80 사용 (Version 9 기준으로 안전한 값)
    final fragmentLen = maxFragmentLen ?? 80;
    _urEncoder = UREncoder(ur, fragmentLen);
  }

  @override
  String nextPart() {
    return _urEncoder.nextPart();
  }

  @override
  String get source => _source;

  /// 단일 프래그먼트인지 확인
  bool get isSinglePart => _urEncoder.isSinglePart;
}
