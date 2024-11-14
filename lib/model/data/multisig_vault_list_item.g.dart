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
      signers: (json['signers'] as List<dynamic>)
          .map((e) => MultisigSigner.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiredSignatureCount: (json['requiredSignatureCount'] as num).toInt(),
    )
      ..vaultJsonString = json['vaultJsonString'] as String?
      ..vaultType = $enumDecode(_$VaultTypeEnumMap, json['vaultType'])
      ..coordinatorBsms = json['coordinatorBsms'] as String?;

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
      'coordinatorBsms': instance.coordinatorBsms,
      'requiredSignatureCount': instance.requiredSignatureCount,
    };

const _$VaultTypeEnumMap = {
  VaultType.singleSignature: 'singleSignature',
  VaultType.multiSignature: 'multiSignature',
};