import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';

class TaprootInheritanceIsolates {
  /// inheritance leaf 목록을 policy 목록과 scriptPath seedInfo/save 모델로 변환한다.
  /// secret을 보유한 leaf는 내부에서 wipe되므로 호출 후 해당 leaf의 secret은 사용할 수 없다.
  static ({List<Policy> policies, List<ScriptPathSeedInfo> seedInfos, List<ScriptPathSeedInfoForSave> saves})
  buildScriptPathEntries(List<InheritanceLeaf> inheritanceleaves) {
    final policies = <Policy>[];
    final seedInfos = <ScriptPathSeedInfo>[];
    final saves = <ScriptPathSeedInfoForSave>[];

    for (final leaf in inheritanceleaves) {
      if (leaf.descriptor != null) {
        policies.add(InheritancePolicy.fromDescriptorAndLocktime(leaf.descriptor!, leaf.lockTime));
      } else {
        final processed = processInheritanceLeafWithSeed(leaf);
        policies.add(processed.policy);
        seedInfos.add(processed.seedInfo);
        saves.add(processed.save);
      }
    }

    return (policies: policies, seedInfos: seedInfos, saves: saves);
  }

  /// secret(니모닉)을 보유한 inheritance leaf를 policy/seedInfo/save 모델로 변환한다.
  /// 내부에서 seed와 keyStore를 wipe하므로 호출 후 [leaf].secret 은 사용할 수 없다.
  static ({Policy policy, ScriptPathSeedInfo seedInfo, ScriptPathSeedInfoForSave save}) processInheritanceLeafWithSeed(
    InheritanceLeaf leaf,
  ) {
    final secret = leaf.secret!;
    final (seedInfo, keyStore) = WalletIsolates.createSeedInfo(secret);
    final leafVault = TaprootVault.fromKeyStoreList([keyStore], []);
    final inheritancePolicy = InheritancePolicy.fromDescriptorAndLocktime(leafVault.descriptor, leaf.lockTime);
    Logger.log('--> inheritance policy miniscript: ${inheritancePolicy.toMiniscript()}');
    final scriptKey = hashString(inheritancePolicy.toMiniscript());
    final save = ScriptPathSeedInfoForSave(
      key: scriptKey,
      role: ScriptPathRole.beneficiary,
      seedInfos: [WalletIsolates.createSeedInfoForSave(secret, seedInfo.extendedPublicKey)],
    );

    keyStore.wipeSeed();
    secret.wipe();

    return (
      policy: inheritancePolicy,
      seedInfo: ScriptPathSeedInfo(key: scriptKey, role: ScriptPathRole.beneficiary, seedInfos: [seedInfo]),
      save: save,
    );
  }
}
