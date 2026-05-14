import 'package:coconut_vault/model/taproot/taproot_seed_info.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:json_annotation/json_annotation.dart';

part 'script_path_seed_info.g.dart';

enum ScriptPathRole { beneficiary }

@JsonSerializable(explicitToJson: true)
class ScriptPathSeedInfo {
  final String key;
  final ScriptPathRole role;
  final List<TaprootSeedInfo> seedInfos;

  ScriptPathSeedInfo({required this.key, required this.role, required this.seedInfos});

  factory ScriptPathSeedInfo.fromJson(Map<String, dynamic> json) => _$ScriptPathSeedInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptPathSeedInfoToJson(this);
}

class ScriptPathSeedInfoForSave {
  final String key;
  final ScriptPathRole role;
  final List<TaprootSeedInfoForSave> seedInfos;

  ScriptPathSeedInfoForSave({required this.key, required this.role, required this.seedInfos});
}
