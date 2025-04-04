// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_sig_vault_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleSigVaultListItem _$SinglesigVaultListItemFromJson(
        Map<String, dynamic> json) =>
    SingleSigVaultListItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      colorIndex: (json['colorIndex'] as num).toInt(),
      iconIndex: (json['iconIndex'] as num).toInt(),
      secret: json['secret'] as String,
      passphrase: json['passphrase'] as String,
      signerBsms: json['signerBsms'] as String?,
      linkedMultisigInfo:
          (json['linkedMultisigInfo'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
    )..vaultType = $enumDecode(_$VaultTypeEnumMap, json['vaultType']);

Map<String, dynamic> _$SinglesigVaultListItemToJson(
        SingleSigVaultListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorIndex': instance.colorIndex,
      'iconIndex': instance.iconIndex,
      'vaultType': _$VaultTypeEnumMap[instance.vaultType]!,
      'secret': instance.secret,
      'passphrase': instance.passphrase,
      'linkedMultisigInfo':
          instance.linkedMultisigInfo?.map((k, e) => MapEntry(k.toString(), e)),
      'signerBsms': instance.signerBsms,
    };

const _$VaultTypeEnumMap = {
  WalletType.singleSignature: 'singleSignature',
  WalletType.multiSignature: 'multiSignature',
};
