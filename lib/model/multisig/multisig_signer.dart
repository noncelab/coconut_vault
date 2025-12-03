import 'dart:core';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:json_annotation/json_annotation.dart';

export 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';

part 'multisig_signer.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class MultisigSigner {
  static const String fieldSignerBsms = 'signerBsms';
  static const String fieldKeyStore = 'keyStore';

  @JsonKey()
  int id;
  @JsonKey()
  int? innerVaultId; // 내부 지갑이 Key로 사용된 경우 앱 내 id
  @JsonKey()
  String? name; // 내부 지갑 이름
  @JsonKey()
  int? iconIndex; // 내부 지갑이 Key로 사용된 경우 앱 내 iconIndex
  @JsonKey()
  int? colorIndex; // 내부 지갑이 Key로 사용된 경우 앱 내 colorIndex
  @JsonKey(name: fieldSignerBsms)
  String? signerBsms; // 외부에서 import
  @JsonKey()
  String? memo; // 외부 지갑에 설정되는 메모
  @JsonKey()
  HardwareWalletType? signerSource; // 외부지갑 기기 종류

  @JsonKey(name: fieldKeyStore, toJson: _customKeyStoreToJson)
  final KeyStore keyStore;

  static String _customKeyStoreToJson(KeyStore keyStore) => keyStore.toJson();

  MultisigSigner({
    required this.id,
    this.innerVaultId,
    this.name,
    this.iconIndex,
    this.colorIndex,
    this.signerBsms,
    this.memo,
    this.signerSource,
    required this.keyStore,
  }) {
    name = name?.replaceAll('\n', ' ');
  }

  Map<String, dynamic> toJson() => _$MultisigSignerToJson(this);

  Map<String, dynamic> toPublicJson() {
    final json = toJson();
    json.remove(fieldSignerBsms);
    json.remove(fieldKeyStore);
    return json;
  }

  factory MultisigSigner.fromJson(Map<String, dynamic> json) => _$MultisigSignerFromJson(json);

  String getSignerDerivationPath() {
    if (signerBsms == null) {
      return '';
    }
    try {
      final bsms = Bsms.parseSigner(signerBsms!);
      return bsms.signer?.path ?? '';
    } catch (_) {
      return '';
    }
  }
}
