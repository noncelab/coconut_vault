import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class MultisigVaultListItem extends VaultListItemBase {
  static const fieldSigners = 'signers';
  static const fieldCoordinatorBsms = 'coordinatorBsms';

  MultisigVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required this.signers,
    required this.requiredSignatureCount,
    String? coordinatorBsms,
    required super.createdAt,
  }) : super(vaultType: WalletType.multiSignature) {
    coconutVault = MultisignatureVault.fromKeyStoreList(
      signers.map((signer) => signer.keyStore).toList(),
      requiredSignatureCount,
      addressType: AddressType.p2wsh,
    );

    name = name.replaceAll('\n', ' ');
    this.coordinatorBsms = coordinatorBsms ?? (coconutVault as MultisignatureVault).getCoordinatorBsms();
  }

  @JsonKey(name: fieldSigners)
  final List<MultisigSigner> signers;

  @JsonKey(name: fieldCoordinatorBsms, includeIfNull: false)
  late final String coordinatorBsms;

  // json_serialization가 기본 생성자를 사용해서 추가함
  // 필요 서명 개수
  @JsonKey(name: "requiredSignatureCount")
  late final int requiredSignatureCount;

  @override
  Future<bool> canSign(String psbt) async {
    return await compute(SignIsolates.canSignToPsbt, [coconutVault, psbt]);
  }

  @override
  String getWalletSyncString() {
    final newSigners =
        signers
            .map(
              (signer) => {
                'innerVaultId': signer.innerVaultId,
                'name': signer.name,
                VaultListItemBase.fieldIconIndex: signer.iconIndex,
                VaultListItemBase.fieldColorIndex: signer.colorIndex,
                'memo': signer.memo,
                // enum은 그대로 jsonEncode 할 수 없으므로 문자열로 변환
                'signerSource': signer.signerSource?.name,
              },
            )
            .toList();

    Map<String, dynamic> json = {
      'name': name,
      VaultListItemBase.fieldColorIndex: colorIndex,
      VaultListItemBase.fieldIconIndex: iconIndex,
      'descriptor': coconutVault.descriptor,
      'requiredSignatureCount': requiredSignatureCount,
      'signers': newSigners,
    };

    return jsonEncode(json);
  }

  @override
  Map<String, dynamic> toJson() => _$MultisigVaultListItemToJson(this);

  @override
  Map<String, dynamic> toPublicJson() {
    final json = toJson();
    json.remove(fieldCoordinatorBsms);
    json[fieldSigners] = signers.map((signer) => signer.toPublicJson()).toList();
    return json;
  }

  factory MultisigVaultListItem.fromJson(Map<String, dynamic> json) {
    json['vaultType'] = _$WalletTypeEnumMap[WalletType.multiSignature];
    return _$MultisigVaultListItemFromJson(json);
  }
}
