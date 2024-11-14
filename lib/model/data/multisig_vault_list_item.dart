import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class MultisigVaultListItem extends VaultListItemBase {
  MultisigVaultListItem(
      {required super.id,
      required super.name,
      required super.colorIndex,
      required super.iconIndex,
      required this.signers,
      required this.requiredSignatureCount})
      : super(vaultType: VaultType.multiSignature) {
    coconutVault = MultisignatureVault.fromKeyStoreList(
        signers.map((signer) => signer.keyStore).toList(),
        requiredSignatureCount,
        AddressType.p2wsh);

    // TODO: 시간 너무 오래 걸리면 생략
    coordinatorBsms =
        (coconutVault as MultisignatureVault).getBsmsCoordinator();

    vaultJsonString = (coconutVault as MultisignatureVault).toJson();
  }

  MultisigVaultListItem.fromCoordinatorBsms(
      {required super.id,
      required super.name,
      required super.colorIndex,
      required super.iconIndex,
      required this.coordinatorBsms,
      required this.signers,
      MultisignatureVault? coconutVault})
      : super(vaultType: VaultType.multiSignature) {
    coconutVault = MultisignatureVault.fromCoordinatorBsms(coordinatorBsms!);
    requiredSignatureCount = coconutVault.requiredSignature;
    vaultJsonString = coconutVault.toJson();
  }

  @JsonKey(name: "signers")
  late final List<MultisigSigner> signers;

  @JsonKey(name: "coordinatorBsms")
  late final String? coordinatorBsms;

  // json_serialization가 기본 생성자를 사용해서 추가함
  @JsonKey(name: "requiredSignatureCount")
  late final int requiredSignatureCount;

  @override
  String getWalletSyncString() {
    throw UnimplementedError("multisig getWalletSyncString");
    // Map<String, dynamic> json = {
    //   'name': name,
    //   'colorIndex': colorIndex,
    //   'iconIndex': iconIndex,
    //   'descriptor': coconutVault.descriptor
    // };

    // return jsonEncode(json);
  }

  Map<String, dynamic> toJson() => _$MultisigVaultListItemToJson(this);

  factory MultisigVaultListItem.fromJson(Map<String, dynamic> json) {
    json['vaultType'] = _$VaultTypeEnumMap[VaultType.multiSignature];
    return _$MultisigVaultListItemFromJson(json);
  }
}