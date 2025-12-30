import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:ur/ur.dart';

class UrBytesConverter {
  static String? convertToText(UR ur) {
    try {
      final decodedCbor = cbor.decode(ur.cbor);

      if (decodedCbor is CborBytes) {
        final bytes = decodedCbor.bytes;
        try {
          return utf8.decode(bytes);
        } catch (e) {
          return null;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Map<dynamic, dynamic>? convertToMap(UR ur) {
    try {
      final decodedCbor = cbor.decode(ur.cbor);
      if (decodedCbor is Map) {
        return decodedCbor as Map<dynamic, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static dynamic convert(UR ur) {
    try {
      final decodedCbor = cbor.decode(ur.cbor);

      if (decodedCbor is CborBytes) {
        final bytes = decodedCbor.bytes;
        try {
          return utf8.decode(bytes);
        } catch (e) {
          return decodedCbor;
        }
      }

      return decodedCbor;
    } catch (e) {
      return null;
    }
  }
}
