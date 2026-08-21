import 'dart:async';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/migration/v1_to_v2.dart';

class DataSchemaMigrationRunner {
  static Future<void> persistCurrentVaultDataSchemaVersion(SharedPrefsRepository sharedPrefs, int version) async {
    await sharedPrefs.setInt(SharedPrefsKeys.kDataSchemeVersion, version);
  }

  static Future<void> runDataSchemaMigrations(
    int from,
    int to,
    List<dynamic> vaultJsonList,
    SharedPrefsRepository sharedPrefs,
    Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
    Completer<void>? cancelToken,
  ) async {
    var currentVersion = from;
    if (currentVersion < 2 && to >= 2) {
      await migrateV1toV2(vaultJsonList, cancelToken, sharedPrefs, savePrivacyInfo);
      currentVersion = 2;
    }

    if (currentVersion != to) {
      throw StateError('Unsupported vault data schema migration: $from to $to');
    }

    // The runner is the single owner of the persisted schema version. It is
    // written only after every migration step has completed successfully.
    await persistCurrentVaultDataSchemaVersion(sharedPrefs, to);
  }
}
