import 'dart:async';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/migration/v1_to_v2.dart';

class DataSchemaMigrationRunner {
  static Future<void> runDataSchemaMigrations(
    int from,
    int to,
    List<dynamic> vaultJsonList,
    SharedPrefsRepository sharedPrefs,
    Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
    Completer<void>? cancelToken,
  ) async {
    var cur = from;
    if (cur < 2 && to >= 2) {
      await migrateV1toV2(vaultJsonList, cancelToken, sharedPrefs, savePrivacyInfo);
      cur = 2;
    }

    await sharedPrefs.setInt(SharedPrefsKeys.kDataSchemeVersion, to);
  }
}
