import 'dart:typed_data';

class SecureZonePayloadCodec {
  static Uint8List buildPlaintext({required Uint8List secret, required Uint8List? passphrase}) {
    const int version = 1;
    final bool hasPass = passphrase != null && passphrase.isNotEmpty;

    // big-endian 4바이트 길이
    Uint8List u32be(int n) =>
        Uint8List(4)
          ..[0] = (n >> 24) & 0xFF
          ..[1] = (n >> 16) & 0xFF
          ..[2] = (n >> 8) & 0xFF
          ..[3] = n & 0xFF;

    final secretLen = u32be(secret.length);
    final passLen = u32be(hasPass ? passphrase.length : 0);

    final bytes = BytesBuilder();
    bytes.add([version]); // 1 byte
    bytes.add([hasPass ? 0x01 : 0x00]); // 1 byte flags
    bytes.add(secretLen); // 4 bytes
    bytes.add(secret); // secret
    bytes.add(passLen); // 4 bytes
    if (hasPass) {
      bytes.add(passphrase); // passphrase
    }
    return bytes.toBytes();
  }

  static ({Uint8List secret, Uint8List? passphrase}) parsePlaintext(Uint8List bytes) {
    int off = 0;

    // 길이 검사 헬퍼
    void requireLen(int need) {
      if (off + need > bytes.length) {
        throw const FormatException('Malformed plaintext (out of range)');
      }
    }

    // 4바이트 BE 정수 읽기
    int readU32be() {
      requireLen(4);
      final v = (bytes[off] << 24) | (bytes[off + 1] << 16) | (bytes[off + 2] << 8) | (bytes[off + 3]);
      off += 4;
      return v;
    }

    // 1) version
    requireLen(1);
    final version = bytes[off++];
    if (version != 1) {
      throw FormatException('Unsupported version: $version');
    }

    // 2) flags
    requireLen(1);
    final flags = bytes[off++];
    final hasPass = (flags & 0x01) != 0;

    // 3) secret length + secret
    final secretLen = readU32be();
    if (secretLen < 0) throw const FormatException('Negative secret length');
    requireLen(secretLen);
    final secret = bytes.sublist(off, off + secretLen);
    off += secretLen;

    // 4) passphrase length + passphrase (optional)
    final passLen = readU32be();
    if (passLen < 0) throw const FormatException('Negative passphrase length');
    if (passLen > 0) {
      requireLen(passLen);
    }
    final pass = passLen > 0 ? bytes.sublist(off, off + passLen) : null;
    off += passLen;

    // 5) flags와 길이 일관성 체크
    if (hasPass && passLen == 0) {
      throw const FormatException('Flags indicate passphrase but length is zero');
    }
    if (!hasPass && passLen > 0) {
      throw const FormatException('Flags indicate no passphrase but length is non-zero');
    }

    return (secret: Uint8List.fromList(secret), passphrase: pass != null ? Uint8List.fromList(pass) : null);
  }
}
