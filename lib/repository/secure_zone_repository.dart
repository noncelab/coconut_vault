import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coconut_vault/services/secure_zone/ios/secure_enclave_keystore.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_keystore.dart';
import 'package:coconut_vault/services/secure_zone/android/hardware_backed_keystore.dart';

class EncryptResult {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Map<String, dynamic>? extra;

  EncryptResult({required this.ciphertext, required this.iv, required this.extra});

  // [version(1)=0x01][ivLen(2, big-endian)][iv][ciphertext]
  Uint8List toCombinedBytes() {
    const int version = 1;
    final ivLen = iv.length;
    final combined = Uint8List(1 + 2 + ivLen + ciphertext.length);
    int off = 0;

    // version
    combined[off++] = version;

    // ivLen (u16 big-endian)
    combined[off++] = (ivLen >> 8) & 0xFF;
    combined[off++] = ivLen & 0xFF;

    // iv
    combined.setRange(off, off + ivLen, iv);
    off += ivLen;

    // ciphertext
    combined.setRange(off, off + ciphertext.length, ciphertext);
    return combined;
  }

  String toCombinedBase64() => base64Encode(toCombinedBytes());

  // Parser
  static (Uint8List iv, Uint8List ciphertext) parseCombinedBytes(Uint8List combined) {
    if (combined.length < 3) {
      throw const FormatException('Combined data too short');
    }
    int off = 0;

    final version = combined[off++];
    if (version != 1) {
      throw FormatException('Unsupported combined format version: $version');
    }

    // u16 big-endian
    final ivLen = (combined[off++] << 8) | combined[off++];
    final minLen = 1 + 2 + ivLen; // header + iv
    if (combined.length < minLen) {
      throw const FormatException('Combined data truncated before IV');
    }

    final iv = combined.sublist(3, 3 + ivLen);
    final ct = combined.sublist(3 + ivLen);
    return (iv, ct);
  }

  static (Uint8List iv, Uint8List ciphertext) fromCombinedBase64(String combinedBase64) {
    final combined = base64Decode(combinedBase64);
    return parseCombinedBytes(combined);
  }
}

class SecureZoneRepository {
  // Singleton
  static final SecureZoneRepository _instance = SecureZoneRepository._internal();
  factory SecureZoneRepository() => _instance;
  SecureZoneRepository._internal() {
    _secureZoneKeystore = Platform.isAndroid ? HardwareBackedKeystore() : SecureEnclaveKeystore();
  }

  late final SecureZoneKeystore _secureZoneKeystore;

  // Public Methods
  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false}) async {
    return await _secureZoneKeystore.generateKey(
      alias: alias,
      userAuthRequired: userAuthRequired,
      perUseAuth: perUseAuth,
    );
  }

  Future<void> deleteKey({required String alias}) async {
    return await _secureZoneKeystore.deleteKey(alias: alias);
  }

  Future<void> deleteKeys({required List<String> aliasList}) async {
    return await _secureZoneKeystore.deleteKeys(aliasList: aliasList);
  }

  Future<EncryptResult> encrypt({required String alias, required Uint8List plaintext}) async {
    final Map<String, dynamic> result = await _secureZoneKeystore.encrypt(alias: alias, plaintext: plaintext);
    final iv = result['iv'] ?? Uint8List(0);

    // ciphertext, iv 제거한 extra 구성
    final extra =
        Map<String, dynamic>.from(result)
          ..remove('ciphertext')
          ..remove('iv');

    return EncryptResult(ciphertext: result['ciphertext'] as Uint8List, iv: iv, extra: extra);
  }

  Future<Uint8List?> decrypt({
    required String alias,
    required Uint8List ciphertext,
    required Uint8List iv,
    bool autoAuth = true,
  }) async {
    return await _secureZoneKeystore.decrypt(alias: alias, ciphertext: ciphertext, iv: iv, autoAuth: autoAuth);
  }
}
