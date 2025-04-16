// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multisig_wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultisigWallet _$MultisigWalletFromJson(Map<String, dynamic> json) => MultisigWallet(
      (json['id'] as num?)?.toInt(),
      json['name'] as String?,
      (json['icon'] as num?)?.toInt(),
      (json['color'] as num?)?.toInt(),
      (json['signers'] as List<dynamic>?)
          ?.map((e) => MultisigSigner.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['requiredSignatureCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MultisigWalletToJson(MultisigWallet instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'signers': MultisigWallet._customSignersToJson(instance.signers),
      'requiredSignatureCount': instance.requiredSignatureCount,
    };
