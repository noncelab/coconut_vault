import 'package:json_annotation/json_annotation.dart';

part 'secret.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable()
class Secret {
  @JsonKey()
  late final String mnemonic;

  @JsonKey()
  late final String passphrase;

  Secret(this.mnemonic, this.passphrase);

  Map<String, dynamic> toJson() => _$SecretToJson(this);

  factory Secret.fromJson(Map<String, dynamic> json) {
    return _$SecretFromJson(json);
  }
}
