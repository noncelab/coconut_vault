import 'dart:core';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_signer.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class MultisigSigner {
  @JsonKey()
  int id;
  @JsonKey()
  int? innerVaultId; // 내부 지갑이 Key로 사용된 경우 앱 내 id
  @JsonKey()
  String? name; // 내부 지갑 이름
  @JsonKey()
  int? iconIndex; // 내부 지갑이 Key로 사용된 경우 앱 내 id
  @JsonKey()
  int? colorIndex; // 내부 지갑이 Key로 사용된 경우 앱 내 id
  @JsonKey()
  String? signerBsms; // 외부에서 import
  @JsonKey()
  SignerSource? signerSource; // 외부지갑 기기 종류
  @JsonKey()
  String? signerName; // 외부 지갑 이름

  @JsonKey(toJson: _customKeyStoreToJson)
  final KeyStore keyStore;

  static String _customKeyStoreToJson(KeyStore keyStore) => keyStore.toJson();

  MultisigSigner({
    required this.id,
    this.innerVaultId,
    this.name,
    this.iconIndex,
    this.colorIndex,
    this.signerBsms,
    this.signerSource,
    this.signerName,
    required this.keyStore,
  }) {
    name = name?.replaceAll('\n', ' ');
  }

  Map<String, dynamic> toJson() => _$MultisigSignerToJson(this);

  factory MultisigSigner.fromJson(Map<String, dynamic> json) => _$MultisigSignerFromJson(json);

  String getSignerName() {
    if (signerName != null) {
      return signerName!;
    }
    return signerSource?.name ?? '';
  }
}

enum SignerSource { coconutvault, keystone3pro, seedsigner, jade, coldcard, krux }
