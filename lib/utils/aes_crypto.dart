import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class Aes256Crypto {
  static const _keyLength = 32; // AES-256 키 길이 (32 bytes = 256 bits)
  static const _ivLength = 16; // AES 블록 크기 (16 bytes = 128 bits)

  /// 랜덤 IV를 생성합니다.
  static IV generateIv() {
    return IV.fromSecureRandom(_ivLength);
  }

  /// AES-256-CBC 모드로 데이터를 암호화합니다.
  /// [data]: 암호화할 데이터
  /// [key]: 암호화 키 (32바이트)
  /// [iv]: 초기화 벡터 (16바이트)
  /// 반환값: Base64로 인코딩된 암호화된 데이터
  static String encryptCbc({
    required String data,
    required Key key,
    required IV iv,
  }) {
    if (key.length != _keyLength) {
      throw ArgumentError('Invalid key length: ${key.length} bytes. Expected: $_keyLength bytes');
    }
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  /// AES-256-CBC 모드로 데이터를 복호화합니다.
  /// [encryptedData]: Base64로 인코딩된 암호화된 데이터
  /// [key]: 복호화 키 (32바이트)
  /// [iv]: 암호화에 사용된 초기화 벡터 (16바이트)
  /// 반환값: 복호화된 데이터
  static String decryptCbc({
    required String encryptedData,
    required Key key,
    required IV iv,
  }) {
    if (key.length != _keyLength) {
      throw ArgumentError('Invalid key length: ${key.length} bytes. Expected: $_keyLength bytes');
    }
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = Encrypted.fromBase64(encryptedData);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// AES-256-CBC 모드로 데이터를 암호화하고 IV를 포함하여 반환합니다.
  /// [data]: 암호화할 데이터
  /// [key]: 암호화 키
  /// 반환값: IV와 암호문이 포함된 맵
  static Map<String, String> encryptWithIvCbc({
    required String data,
    required Key key,
  }) {
    final iv = generateIv();
    final encrypted = encryptCbc(
      data: data,
      key: key,
      iv: iv,
    );

    return {
      'iv': base64.encode(iv.bytes),
      'encrypted': encrypted,
    };
  }

  /// AES-256-CBC 모드로 IV가 포함된 암호화된 데이터를 복호화합니다.
  /// [encryptedData]: encryptWithIvCbc로 암호화된 데이터
  /// [key]: 복호화 키
  /// 반환값: 복호화된 데이터
  static String decryptWithIvCbc({
    required Map<String, String> encryptedData,
    required Key key,
  }) {
    final iv = IV(base64.decode(encryptedData['iv']!));
    return decryptCbc(
      encryptedData: encryptedData['encrypted']!,
      key: key,
      iv: iv,
    );
  }

  /// IV와 암호문이 결합된 문자열을 복호화합니다.
  /// [combinedData]: IV(16바이트) + 암호문이 결합된 문자열
  /// [key]: 복호화 키 (32바이트)
  /// 반환값: 복호화된 데이터
  static String decryptWithCombinedIv({
    required String combinedData,
    required Key key,
  }) {
    // 문자열을 바이트 리스트로 변환
    final List<int> bytes = combinedData.codeUnits;

    // IV와 암호문 분리 (앞의 16바이트가 IV)
    final iv = IV(Uint8List.fromList(bytes.sublist(0, _ivLength)));
    final encryptedData = String.fromCharCodes(bytes.sublist(_ivLength));

    return decryptCbc(
      encryptedData: encryptedData,
      key: key,
      iv: iv,
    );
  }
}
