import 'dart:typed_data';

import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/utils/json_converter/uint8list_base64_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mnemonic_passphrase_pair.g.dart';

@JsonSerializable(explicitToJson: true)
class SeedSource {
  @JsonKey(name: "mnemonic", fromJson: _mnemonicFromJson, toJson: _mnemonicToJson)
  Uint8List mnemonic;

  @JsonKey(name: "passphrase", fromJson: _passphraseFromJson, toJson: _passphraseToJson)
  Uint8List passphrase;

  static Uint8List _mnemonicFromJson(String? json) => const Uint8ListBase64Converter().fromJson(json)!;

  static String _mnemonicToJson(Uint8List object) => const Uint8ListBase64Converter().toJson(object)!;

  static Uint8List _passphraseFromJson(String? json) => const Uint8ListBase64Converter().fromJson(json)!;

  static String _passphraseToJson(Uint8List object) => const Uint8ListBase64Converter().toJson(object)!;

  SeedSource({required this.mnemonic, required this.passphrase});

  factory SeedSource.fromJson(Map<String, dynamic> json) => _$SeedSourceFromJson(json);

  Map<String, dynamic> toJson() => _$SeedSourceToJson(this);

  void wipe() {
    mnemonic.wipe();
    passphrase.wipe();
  }
}
