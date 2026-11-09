import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/repository/migration/v3_to_v4.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';

/// 볼트 3.0.x 상속 지갑의 older 표기 복구와 백업 갱신 안내 대상 등록
Future<List<int>> migrateV2toV3(
  List<dynamic> jsonList,
  SharedPrefsRepository sharedPrefs,
  Future<WalletPrivacyInfo> Function(int id, WalletType walletType) readPrivacyInfo,
  Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
) async {
  final migratedWalletIds = await migrateTaprootLegacyInheritanceLeaves(jsonList, readPrivacyInfo, savePrivacyInfo);
  await sharedPrefs.addWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate(migratedWalletIds);
  return migratedWalletIds;
}
