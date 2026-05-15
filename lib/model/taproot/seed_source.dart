import 'dart:convert';
import 'dart:typed_data';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/utils/json_converter/uint8list_base64_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'seed_source.g.dart';

@JsonSerializable(explicitToJson: true)
class SeedSource {
  @JsonKey(name: "mnemonic")
  @RequiredUint8ListBase64Converter()
  Uint8List mnemonic;

  @JsonKey(name: "passphrase")
  @RequiredUint8ListBase64Converter()
  Uint8List passphrase;

  SeedSource({required this.mnemonic, required this.passphrase});

  factory SeedSource.fromJson(Map<String, dynamic> json) => _$SeedSourceFromJson(json);

  Map<String, dynamic> toJson() => _$SeedSourceToJson(this);

  void wipe() {
    mnemonic.wipe();
    passphrase.wipe();
  }
}
