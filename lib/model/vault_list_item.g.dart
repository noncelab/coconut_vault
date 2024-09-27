// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VaultListItem _$VaultListItemFromJson(Map<String, dynamic> json) =>
    VaultListItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      colorIndex: (json['colorIndex'] as num).toInt(),
      iconIndex: (json['iconIndex'] as num).toInt(),
      secret: json['secret'] as String,
      passphrase: json['passphrase'] as String,
      vaultJsonString: json['vaultJsonString'] as String?,
    );

Map<String, dynamic> _$VaultListItemToJson(VaultListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorIndex': instance.colorIndex,
      'iconIndex': instance.iconIndex,
      'secret': instance.secret,
      'passphrase': instance.passphrase,
      'vaultJsonString': instance.vaultJsonString,
    };
