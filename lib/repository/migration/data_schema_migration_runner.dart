import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/migration/v1_to_v2.dart';

class DataSchemaMigrationRunner {
  static Future<void> runDataSchemaMigrations(
    int from,
    int to,
    List<VaultListItemBase> vaultList,
    SharedPrefsRepository sharedPrefs,
    Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
  ) async {
    var cur = from;
    if (cur < 2 && to >= 2) {
      await migrateV1toV2(vaultList, sharedPrefs, savePrivacyInfo);
      cur = 2;
    }

    await sharedPrefs.setInt(SharedPrefsKeys.kDataSchemeVersion, to);
  }
}
