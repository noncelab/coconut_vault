import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/migration/taproot_older_to_after_migration.dart';

/// Repairs Taproot inheritance descriptors generated with `older` instead of
/// `after`, and recalculates their descriptor checksums.
Future<List<int>> migrateV2toV3(
  List<dynamic> jsonList,
  SharedPrefsRepository sharedPrefs,
  Future<WalletPrivacyInfo> Function(int id, WalletType walletType) readPrivacyInfo,
  Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
) async {
  final migratedWalletIds = <int>[];

  for (final raw in jsonList) {
    if (raw is! Map<String, dynamic>) continue;
    if (raw[VaultListItemBase.vaultTypeField] != WalletType.taproot.name) continue;

    final id = raw['id'];
    if (id is! int) continue;

    final privacyInfo = await readPrivacyInfo(id, WalletType.taproot);
    if (privacyInfo is! TaprootWalletPrivacyInfo) continue;

    final descriptorMigration = TaprootOlderToAfterMigration.migrateDescriptor(privacyInfo.descriptor);
    if (!descriptorMigration.hasChanges) continue;
    final repairedDescriptor = descriptorMigration.descriptor;

    final repairedVault = TaprootVault.fromDescriptor(repairedDescriptor);
    final repairedScriptPathSeedInfos = privacyInfo.scriptPathSeedInfos
        .map((seedInfo) {
          if (seedInfo.seedInfos.isEmpty) return seedInfo;
          final matchingPolicy = repairedVault.policyList.whereType<InheritancePolicy>().firstWhere(
            (policy) =>
                policy.beneficiaryKeyStore.extendedPublicKey.serialize() == seedInfo.seedInfos.first.extendedPublicKey,
            orElse: () => throw StateError('No inheritance policy found for script path seed info.'),
          );
          return ScriptPathSeedInfo(
            key: ScriptPathSeedInfo.generateKey(matchingPolicy),
            role: seedInfo.role,
            seedInfos: seedInfo.seedInfos,
          );
        })
        .toList(growable: false);

    await savePrivacyInfo(
      id,
      WalletType.taproot,
      TaprootWalletPrivacyInfo(
        descriptor: repairedDescriptor,
        keyPathSeedInfos: privacyInfo.keyPathSeedInfos,
        scriptPathSeedInfos: repairedScriptPathSeedInfos,
      ),
    );
    migratedWalletIds.add(id);
  }

  await sharedPrefs.addWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate(migratedWalletIds);
  return migratedWalletIds;
}
