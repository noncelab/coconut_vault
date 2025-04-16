// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multisig_signer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultisigSigner _$MultisigSignerFromJson(Map<String, dynamic> json) => MultisigSigner(
      id: (json['id'] as num).toInt(),
      innerVaultId: (json['innerVaultId'] as num?)?.toInt(),
      name: json['name'] as String?,
      iconIndex: (json['iconIndex'] as num?)?.toInt(),
      colorIndex: (json['colorIndex'] as num?)?.toInt(),
      signerBsms: json['signerBsms'] as String?,
      memo: json['memo'] as String?,
      keyStore: KeyStore.fromJson(json['keyStore'] as String),
    );

Map<String, dynamic> _$MultisigSignerToJson(MultisigSigner instance) => <String, dynamic>{
      'id': instance.id,
      'innerVaultId': instance.innerVaultId,
      'name': instance.name,
      'iconIndex': instance.iconIndex,
      'colorIndex': instance.colorIndex,
      'signerBsms': instance.signerBsms,
      'memo': instance.memo,
      'keyStore': MultisigSigner._customKeyStoreToJson(instance.keyStore),
    };
