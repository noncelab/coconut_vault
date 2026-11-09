import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/wallet_data_exception.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/utils/migration/taproot_legacy_inheritance_migration.dart';
import 'package:collection/collection.dart';

Future<void> migrateV3toV4(
  List<dynamic> jsonList,
  Future<WalletPrivacyInfo> Function(int id, WalletType walletType) readPrivacyInfo,
  Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
) async {
  await migrateTaprootLegacyInheritanceLeaves(jsonList, readPrivacyInfo, savePrivacyInfo);
}

/// older 표기가 있던 지갑 id 목록 반환
Future<List<int>> migrateTaprootLegacyInheritanceLeaves(
  List<dynamic> jsonList,
  Future<WalletPrivacyInfo> Function(int id, WalletType walletType) readPrivacyInfo,
  Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
) async {
  final walletIdsWithOlder = <int>[];

  for (final raw in jsonList) {
    if (raw is! Map<String, dynamic>) continue;
    if (raw[VaultListItemBase.vaultTypeField] != WalletType.taproot.name) continue;

    final id = raw['id'];
    if (id is! int) continue;

    final WalletPrivacyInfo privacyInfo;
    try {
      privacyInfo = await readPrivacyInfo(id, WalletType.taproot);
    } on PrivacyInfoNotFoundException {
      continue;
    }
    if (privacyInfo is! TaprootWalletPrivacyInfo) continue;

    final descriptorMigration = TaprootLegacyInheritanceMigration.migrateDescriptor(privacyInfo.descriptor);
    final vault = TaprootVault.fromDescriptor(descriptorMigration.descriptor);
    final storedSeedInfos = privacyInfo.scriptPathSeedInfos;
    final scriptPathSeedInfos = storedSeedInfos
        .map((seedInfo) => _rekeyScriptPathSeedInfo(seedInfo, vault))
        .toList(growable: false);
    final hasKeyChanges =
        !const ListEquality<String>().equals(
          scriptPathSeedInfos.map((seedInfo) => seedInfo.key).toList(),
          storedSeedInfos.map((seedInfo) => seedInfo.key).toList(),
        );
    if (!descriptorMigration.hasChanges && !hasKeyChanges) continue;

    await savePrivacyInfo(
      id,
      WalletType.taproot,
      TaprootWalletPrivacyInfo(
        descriptor: descriptorMigration.descriptor,
        keyPathSeedInfos: privacyInfo.keyPathSeedInfos,
        scriptPathSeedInfos: scriptPathSeedInfos,
      ),
    );
    if (descriptorMigration.hasOlder) walletIdsWithOlder.add(id);
  }

  return walletIdsWithOlder;
}

ScriptPathSeedInfo _rekeyScriptPathSeedInfo(ScriptPathSeedInfo seedInfo, TaprootVault vault) {
  if (seedInfo.seedInfos.isEmpty) return seedInfo;

  final policy = vault.policyList.whereType<InheritancePolicy>().firstWhereOrNull(
    (policy) => policy.beneficiaryKeyStore.extendedPublicKey.serialize() == seedInfo.seedInfos.first.extendedPublicKey,
  );
  if (policy == null) return seedInfo;

  return ScriptPathSeedInfo(
    key: ScriptPathSeedInfo.generateKey(policy),
    role: seedInfo.role,
    seedInfos: seedInfo.seedInfos,
  );
}
