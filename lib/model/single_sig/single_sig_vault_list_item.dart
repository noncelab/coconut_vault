import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'single_sig_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class SingleSigVaultListItem extends VaultListItemBase {
  SingleSigVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required this.descriptor,
    required this.signerBsms,
    this.linkedMultisigInfo,
    required super.createdAt,
  }) : super(vaultType: WalletType.singleSignature) {
    final descriptor = Descriptor.parse(this.descriptor);
    final keyStore =
        KeyStore.fromExtendedPublicKey(descriptor.getPublicKey(0), descriptor.getFingerprint(0));
    coconutVault = SingleSignatureVault.fromKeyStore(keyStore);
  }

  @JsonKey()
  String descriptor;

  @JsonKey()
  String signerBsms;

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
      'descriptor': coconutVault.descriptor
    };

    return jsonEncode(json);
  }

  @override
  Map<String, dynamic> toJson() => _$SingleSigVaultListItemToJson(this);

  factory SingleSigVaultListItem.fromJson(Map<String, dynamic> json) {
    json['vaultType'] = _$WalletTypeEnumMap[WalletType.singleSignature];
    return _$SingleSigVaultListItemFromJson(json);
  }

  @override
  String toString() =>
      'Vault($id) / type=$vaultType / linkedMultisigInfo=$linkedMultisigInfo / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';
}
