import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

part 'multisig_signer.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable()
class MultisigSigner {
  int id;
  int? innerVaultId; // 내부 지갑이 Key로 사용된 경우 앱 내 id
  String? memo; // 외부 지갑에 설정되는 메모
  String? signerBsms; // 외부 지갑인 경우 bsms 정보

  MultisigSigner(
      {required this.id, this.innerVaultId, this.memo, this.signerBsms});

  Map<String, dynamic> toJson() => _$MultisigSignerToJson(this);

  factory MultisigSigner.fromJson(Map<String, dynamic> json) =>
      _$MultisigSignerFromJson(json);
}
