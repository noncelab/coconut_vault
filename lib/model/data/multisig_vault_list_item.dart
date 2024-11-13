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
      super.vaultJsonString,
      required this.coordinatorBsms,
      required this.signers})
      : super(vaultType: VaultType.multiSignature) {
    //Seed seed = Seed.fromMnemonic(secret, passphrase: passphrase);
    //coconutVault = SingleSignatureVault.fromSeed(seed, AddressType.p2wpkh);

    //vaultJsonString = (coconutVault as SingleSignatureVault).toJson();
  }

  @JsonKey(name: "signers")
  final List<MultisigSigner> signers;

  @JsonKey(name: "coordinatorBsms")
  final String coordinatorBsms;

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
