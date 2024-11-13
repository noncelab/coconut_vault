// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multisig_vault_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultisigVaultListItem _$MultisigVaultListItemFromJson(
        Map<String, dynamic> json) =>
    MultisigVaultListItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      colorIndex: (json['colorIndex'] as num).toInt(),
      iconIndex: (json['iconIndex'] as num).toInt(),
      vaultJsonString: json['vaultJsonString'] as String?,
      signers: (json['signers'] as List<dynamic>)
          .map((e) => MultisigSigner.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..vaultType = $enumDecode(_$VaultTypeEnumMap, json['vaultType']);

Map<String, dynamic> _$MultisigVaultListItemToJson(
        MultisigVaultListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorIndex': instance.colorIndex,
      'iconIndex': instance.iconIndex,
      'vaultJsonString': instance.vaultJsonString,
      'vaultType': _$VaultTypeEnumMap[instance.vaultType]!,
      'signers': instance.signers,
    };

const _$VaultTypeEnumMap = {
  VaultType.singleSignature: 'singleSignature',
  VaultType.multiSignature: 'multiSignature',
};
