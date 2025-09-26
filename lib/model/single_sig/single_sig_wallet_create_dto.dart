import 'dart:typed_data';

import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/utils/json_converter/uint8list_base64_converter.dart';
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
  @Uint8ListBase64Converter()
  Uint8List? mnemonic;

  @JsonKey(name: "passphrase")
  @Uint8ListBase64Converter()
  Uint8List? passphrase;

  SingleSigWalletCreateDto(this.id, this.name, this.icon, this.color, this.mnemonic, this.passphrase);

  Map<String, dynamic> toJson() => _$SingleSigWalletCreateDtoToJson(this);

  factory SingleSigWalletCreateDto.fromJson(Map<String, dynamic> json) {
    return _$SingleSigWalletCreateDtoFromJson(json);
  }

  void wipe() {
    mnemonic?.wipe();
    passphrase?.wipe();
  }
}
