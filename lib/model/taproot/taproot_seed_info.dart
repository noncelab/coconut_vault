import 'package:json_annotation/json_annotation.dart';

part 'taproot_seed_info.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable()
class TaprootSeedInfo {
  @JsonKey(name: 'extendedPublicKey')
  final String extendedPublicKey;

  @JsonKey(name: 'isPassphraseSet')
  final bool isPassphraseSet;

  TaprootSeedInfo({required this.extendedPublicKey, required this.isPassphraseSet});

  factory TaprootSeedInfo.fromJson(Map<String, dynamic> json) => _$TaprootSeedInfoFromJson(json);

  Map<String, dynamic> toJson() => _$TaprootSeedInfoToJson(this);
}
