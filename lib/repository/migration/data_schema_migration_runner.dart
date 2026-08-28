import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/migration/v1_to_v2.dart';
import 'package:coconut_vault/repository/migration/v2_to_v3.dart';

class DataSchemaMigrationRunner {
  static Future<void> persistCurrentVaultDataSchemaVersion(SharedPrefsRepository sharedPrefs, int version) async {
    await sharedPrefs.setInt(SharedPrefsKeys.kDataSchemeVersion, version);
  }

  static Future<List<int>> runDataSchemaMigrations(
    int from,
    int to,
    List<dynamic> vaultJsonList,
    SharedPrefsRepository sharedPrefs,
    Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo, [
    Future<WalletPrivacyInfo> Function(int id, WalletType walletType)? readPrivacyInfo,
  ]) async {
    var currentVersion = from;
    var currentVaultJsonList = vaultJsonList;
    var migratedTaprootWalletIds = <int>[];
    if (currentVersion < 2 && to >= 2) {
      currentVaultJsonList = await migrateV1toV2(currentVaultJsonList, sharedPrefs, savePrivacyInfo);
      await persistCurrentVaultDataSchemaVersion(sharedPrefs, 2);
      currentVersion = 2;
    }

    if (currentVersion < 3 && to >= 3) {
      if (readPrivacyInfo == null) {
        throw ArgumentError('Taproot descriptor migration requires a privacy info reader.');
      }
      migratedTaprootWalletIds = await migrateV2toV3(
        currentVaultJsonList,
        sharedPrefs,
        readPrivacyInfo,
        savePrivacyInfo,
      );
      currentVersion = 3;
    }

    if (currentVersion != to) {
      throw StateError('Unsupported vault data schema migration: $from to $to');
    }

    // The runner is the single owner of the persisted schema version. It is
    // written only after every migration step has completed successfully.
    await persistCurrentVaultDataSchemaVersion(sharedPrefs, to);
    return migratedTaprootWalletIds;
  }
}
