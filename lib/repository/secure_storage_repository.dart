import 'dart:convert';

import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageRepository {
  SecureStorageRepository._internal();

  static final SecureStorageRepository _instance = SecureStorageRepository._internal();
  static const AndroidOptions androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    sharedPreferencesName: 'SecureStorage_v2',
    preferencesKeyPrefix: 'v2_',
  );
  static const IOSOptions iosOptions = IOSOptions(accessibility: KeychainAccessibility.passcode, synchronizable: false);

  static const FlutterSecureStorage _storage = FlutterSecureStorage(aOptions: androidOptions, iOptions: iosOptions);

  factory SecureStorageRepository() {
    return _instance;
  }

  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      Logger.log('write: error: $e');
      if (e.toString().contains('-25299') || e.toString().contains('already exists')) {
        await _storage.delete(key: key);
        await _storage.write(key: key, value: value);
      } else {
        rethrow; // 다른 에러는 그대로 전파
      }
    }
  }

  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      Logger.error('--> read: error: $e');
      return null;
    }
  }

  Future<void> writeBytes({required String key, required Uint8List value}) async {
    try {
      await _storage.write(key: key, value: utf8.decode(value));
    } catch (e) {
      // 키체인에 이미 존재하는 경우 삭제 후 다시 저장
      if (e.toString().contains('-25299') || e.toString().contains('already exists')) {
        await _storage.delete(key: key);
        await _storage.write(key: key, value: utf8.decode(value));
      } else {
        rethrow; // 다른 에러는 그대로 전파
      }
    }
  }

  Future<Uint8List?> readBytes({required String key}) async {
    String? decoded = await _storage.read(key: key);
    if (decoded == null) return null;
    return utf8.encode(decoded);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<List<String>> getAllKeys() async {
    final Map<String, String> allValues = await _storage.readAll();
    return allValues.keys.toList();
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
