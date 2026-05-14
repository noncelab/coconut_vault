import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/taproot/stored_taproot_seed_info.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'script_path_seed_info.g.dart';

enum ScriptPathRole { beneficiary }

@JsonSerializable(explicitToJson: true)
class ScriptPathSeedInfo {
  final String key;
  final ScriptPathRole role;
  final List<StoredTaprootSeedInfo> seedInfos;

  ScriptPathSeedInfo({required this.key, required this.role, required this.seedInfos});

  static String generateKey(Policy policy) => hashString(policy.toMiniscript());

  factory ScriptPathSeedInfo.fromJson(Map<String, dynamic> json) => _$ScriptPathSeedInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptPathSeedInfoToJson(this);
}

class ScriptPathSeedInfoForSave {
  final String key;
  final ScriptPathRole role;
  final List<TaprootSeedInfoForSave> seedInfos;

  ScriptPathSeedInfoForSave({required this.key, required this.role, required this.seedInfos});
}
