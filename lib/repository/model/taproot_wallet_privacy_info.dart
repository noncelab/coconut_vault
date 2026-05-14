import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taproot_wallet_privacy_info.g.dart';

/// secure storage에 저장
@JsonSerializable()
class TaprootWalletPrivacyInfo extends WalletPrivacyInfo {
  final String descriptor;
  final List<TaprootSeedInfo> keyPathSeedInfos;
  final List<ScriptPathSeedInfo> scriptPathSeedInfos;

  TaprootWalletPrivacyInfo({
    required this.descriptor,
    required this.keyPathSeedInfos,
    required this.scriptPathSeedInfos,
  });

  factory TaprootWalletPrivacyInfo.fromJson(Map<String, dynamic> json) => _$TaprootWalletPrivacyInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TaprootWalletPrivacyInfoToJson(this);
}
