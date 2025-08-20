import 'package:json_annotation/json_annotation.dart';

part 'single_sig_wallet_create_dto.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

/// 생성
@JsonSerializable()
class SingleSigWalletCreateDto {
  @JsonKey(name: "id")
  int? id;
  @JsonKey(name: "name")
  String? name;
  @JsonKey(name: "icon")
  int? icon;
  @JsonKey(name: "color")
  int? color;
  @JsonKey(name: "mnemonic")
  String? mnemonic;
  @JsonKey(name: "passphrase")
  String? passphrase;

  SingleSigWalletCreateDto(
      this.id, this.name, this.icon, this.color, this.mnemonic, this.passphrase);

  Map<String, dynamic> toJson() => _$SingleSigWalletCreateDtoToJson(this);

  factory SingleSigWalletCreateDto.fromJson(Map<String, dynamic> json) {
    return _$SingleSigWalletCreateDtoFromJson(json);
  }
}
