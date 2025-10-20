import 'package:coconut_vault/utils/logger.dart' show Logger;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OldSecureStorageCleaner {
  // 이전 설정
  static const FlutterSecureStorage _oldStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> cleanAll() async {
    try {
      await _oldStorage.deleteAll();
      final Map<String, String> oldData = await _oldStorage.readAll();
      if (oldData.isEmpty) {
        Logger.log('ⓘ No data found in old secure storage.');
        return;
      }
    } catch (e) {
      Logger.log('⚠️ Secure storage cleanup failed: $e');
    }
  }
}
