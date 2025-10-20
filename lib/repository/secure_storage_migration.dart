import 'package:coconut_vault/utils/logger.dart' show Logger;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageMigration {
  // 이전 설정
  static const FlutterSecureStorage _oldStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // 새로운 설정 (KeychainAccessibility.passcode 적용)
  static const FlutterSecureStorage _newStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      groupId: 'group.onl.coconut.vault.secure',
      accessibility: KeychainAccessibility.passcode,
      synchronizable: false,
    ),
  );

  static Future<void> migrateAllIfNeeded() async {
    try {
      final Map<String, String> oldData = await _oldStorage.readAll();
      if (oldData.isEmpty) {
        Logger.log('ⓘ No data found in old secure storage.');
        return;
      }

      for (final entry in oldData.entries) {
        final key = entry.key;
        final value = entry.value;

        final newValue = await _newStorage.read(key: key);
        if (newValue != null) {
          Logger.log('⏭️ [$key] already exists, skipping migration.');
          continue;
        }

        await _newStorage.write(key: key, value: value);
        Logger.log('✅ migrated [$key]');

        await _oldStorage.delete(key: key);
      }

      Logger.log('🎉 Secure storage migration completed successfully.');
    } catch (e) {
      Logger.log('⚠️ Secure storage migration failed: $e');
    }
  }
}
