import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_wallet.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

/// 생성
@JsonSerializable()
class MultisigWallet {
  @JsonKey(name: "id")
  int? id;
  @JsonKey(name: "name")
  String? name;
  @JsonKey(name: "icon")
  int? icon;
  @JsonKey(name: "color")
  int? color;
  @JsonKey(name: "signers", toJson: _customSignersToJson)
  List<MultisigSigner>? signers;
  @JsonKey(name: "requiredSignatureCount")
  int? requiredSignatureCount;

  MultisigWallet(this.id, this.name, this.icon, this.color, this.signers, this.requiredSignatureCount);

  Map<String, dynamic> toJson() => _$MultisigWalletToJson(this);

  factory MultisigWallet.fromJson(Map<String, dynamic> json) {
    return _$MultisigWalletFromJson(json);
  }

  static List<Map<String, dynamic>>? _customSignersToJson(List<MultisigSigner>? signers) {
    if (signers == null) return null;
    return signers.map((signer) => signer.toJson()).toList();
  }
}
