import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'single_sig_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class SingleSigVaultListItem extends VaultListItemBase {
  static const fieldDescriptor = 'descriptor';
  static const fieldSignerBsmsByAddressType = 'signerBsmsByAddressType';

  SingleSigVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required this.descriptor,
    required this.signerBsmsByAddressType,
    this.linkedMultisigInfo,
    required super.createdAt,
    this.signerBsms, // data scheme v1, signerBsmsByAddressType으로 대체됨
  }) : super(vaultType: WalletType.singleSignature) {
    final descriptor = Descriptor.parse(this.descriptor);
    final keyStore = KeyStore.fromExtendedPublicKey(descriptor.getPublicKey(0), descriptor.getFingerprint(0));
    coconutVault = SingleSignatureVault.fromKeyStore(keyStore);
  }

  @JsonKey(name: fieldDescriptor, includeToJson: false)
  String descriptor;

  /// wallet_repository data scheme v1 -> v2 마이그레이션 때문에 필드는 남겨둠
  @Deprecated("Use signerBsmsByAddressType instead.")
  @JsonKey(includeToJson: false)
  String? signerBsms;

  // INFO: 이 프로퍼티 직접 사용 안함. getSignerBsmsByAddressType 함수 사용
  @JsonKey(name: fieldSignerBsmsByAddressType, toJson: _signerBsmsToJson, fromJson: _signerBsmsFromJson)
  Map<AddressType, String> signerBsmsByAddressType;

  String getSignerBsmsByAddressType(AddressType addressType, {bool withLabel = true}) {
    final signerBsms = signerBsmsByAddressType[addressType]!;
    assert(signerBsms.endsWith('\n'), 'signerBsms should end with newline');
    if (withLabel) {
      return "$signerBsms$name";
    }
    return signerBsms;
  }

  @JsonKey(name: "linkedMultisigInfo")
  Map<int, int>? linkedMultisigInfo;

  @override
  Future<bool> canSign(String psbt) async {
    return await compute(SignIsolates.canSignToPsbt, [coconutVault, psbt]);
  }

  @override
  String getWalletSyncString() {
    Map<String, dynamic> json = {
      'name': name,
      'colorIndex': colorIndex,
      'iconIndex': iconIndex,
      'descriptor': coconutVault.descriptor,
    };

    return jsonEncode(json);
  }

  @override
  Map<String, dynamic> toJson() => _$SingleSigVaultListItemToJson(this);

  @override
  Map<String, dynamic> toPublicJson() {
    final json = toJson();
    json.remove(fieldDescriptor);
    json.remove(fieldSignerBsmsByAddressType);
    return json;
  }

  factory SingleSigVaultListItem.fromJson(Map<String, dynamic> json) {
    json['vaultType'] = _$WalletTypeEnumMap[WalletType.singleSignature];
    return _$SingleSigVaultListItemFromJson(json);
  }

  @override
  String toString() =>
      'Vault($id) / type=$vaultType / linkedMultisigInfo=$linkedMultisigInfo / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';

  static Map<AddressType, String> _signerBsmsFromJson(Map<String, dynamic>? json) {
    if (json == null) return {};
    return json.map((key, value) => MapEntry(AddressType.values.firstWhere((e) => e.name == key), value as String));
  }

  static Map<String, String> _signerBsmsToJson(Map<AddressType, String> map) {
    return map.map((key, value) => MapEntry(key.name, value));
  }
}
