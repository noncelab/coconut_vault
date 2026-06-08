import 'package:json_annotation/json_annotation.dart';

part 'stored_taproot_seed_info.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

/// 해당 인스턴스 존재하면 Seed가 저장되어 있다는 의미
@JsonSerializable()
class StoredTaprootSeedInfo {
  @JsonKey(name: 'extendedPublicKey')
  final String extendedPublicKey;

  @JsonKey(name: 'isPassphraseSet')
  final bool isPassphraseSet;

  StoredTaprootSeedInfo({required this.extendedPublicKey, required this.isPassphraseSet});

  factory StoredTaprootSeedInfo.fromJson(Map<String, dynamic> json) => _$StoredTaprootSeedInfoFromJson(json);

  Map<String, dynamic> toJson() => _$StoredTaprootSeedInfoToJson(this);
}
