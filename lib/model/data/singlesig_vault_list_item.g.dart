// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'singlesig_vault_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SinglesigVaultListItem _$SinglesigVaultListItemFromJson(
        Map<String, dynamic> json) =>
    SinglesigVaultListItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      colorIndex: (json['colorIndex'] as num).toInt(),
      iconIndex: (json['iconIndex'] as num).toInt(),
      secret: json['secret'] as String,
      passphrase: json['passphrase'] as String,
      multisigKey: json['multisigKey'] as Map<String, dynamic>?,
      vaultJsonString: json['vaultJsonString'] as String?,
    )..vaultType = $enumDecode(_$VaultTypeEnumMap, json['vaultType']);

Map<String, dynamic> _$SinglesigVaultListItemToJson(
        SinglesigVaultListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorIndex': instance.colorIndex,
      'iconIndex': instance.iconIndex,
      'vaultType': _$VaultTypeEnumMap[instance.vaultType]!,
      'vaultJsonString': instance.vaultJsonString,
      'secret': instance.secret,
      'passphrase': instance.passphrase,
      'multisigKey': instance.multisigKey,
    };

const _$VaultTypeEnumMap = {
  VaultType.singleSignature: 'singleSignature',
  VaultType.multiSignature: 'multiSignature',
};
