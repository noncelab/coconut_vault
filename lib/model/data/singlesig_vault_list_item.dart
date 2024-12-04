import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'singlesig_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class SinglesigVaultListItem extends VaultListItemBase {
  static const String secretField = 'secret';
  static const String passphraseField = 'passphrase';

  SinglesigVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required String secret,
    required String passphrase,
    this.linkedMultisigInfo,
    super.vaultJsonString,
  }) : super(vaultType: VaultType.singleSignature) {
    Seed seed = Seed.fromMnemonic(secret, passphrase: passphrase);
    coconutVault = SingleSignatureVault.fromSeed(seed, AddressType.p2wpkh);
    //TODO: (coconutVault as SingleSignatureVault).keyStore.seed = null;
  }

  /// @Deprecated
  @JsonKey(name: secretField)
  String? secret;

  /// @Deprecated
  @JsonKey(name: passphraseField)
  String? passphrase;

  @JsonKey(name: "linkedMultisigInfo")
  Map<int, int>? linkedMultisigInfo;

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
  Map<String, dynamic> toJson() => _$SinglesigVaultListItemToJson(this);

  factory SinglesigVaultListItem.fromJson(Map<String, dynamic> json) {
    json['vaultType'] = _$VaultTypeEnumMap[VaultType.singleSignature];
    return _$SinglesigVaultListItemFromJson(json);
  }

  @override
  String toString() =>
      'Vault($id) / type=$vaultType / linkedMultisigInfo=$linkedMultisigInfo / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';
}
