import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taproot_wallet_create_dto.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(explicitToJson: true)
class TaprootWalletCreateDto {
  @JsonKey(name: "id")
  int? id;
  @JsonKey(name: "name")
  String? name;
  @JsonKey(name: "icon")
  int? icon;
  @JsonKey(name: "color")
  int? color;
  @JsonKey(name: "keyPathPairs")
  List<SeedSource>? keyPathSeeds;
  @JsonKey(name: "keyPathSignerBsmses")
  List<String>? keyPathSignerBsmses;
  // scriptPaths
  @JsonKey(name: "inheritanceLeaves")
  List<InheritanceLeaf>? inheritanceLeaves;

  TaprootWalletCreateDto(
    this.id,
    this.name,
    this.icon,
    this.color,
    this.keyPathSeeds,
    this.keyPathSignerBsmses,
    this.inheritanceLeaves,
  ) : assert(
        keyPathSeeds != null || keyPathSignerBsmses != null,
        'Either keyPathPairs or keyPathSignerBsmses must be provided',
      );

  Map<String, dynamic> toJson() => _$TaprootWalletCreateDtoToJson(this);

  factory TaprootWalletCreateDto.fromJson(Map<String, dynamic> json) {
    return _$TaprootWalletCreateDtoFromJson(json);
  }

  void wipe() {
    keyPathSeeds?.forEach((pair) => pair.wipe());
    inheritanceLeaves?.forEach((leaf) => leaf.wipe());
  }
}
