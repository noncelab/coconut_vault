// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multisig_signer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultisigSigner _$MultisigSignerFromJson(Map<String, dynamic> json) =>
    MultisigSigner(
      id: (json['id'] as num).toInt(),
      innerVaultId: (json['innerVaultId'] as num?)?.toInt(),
      memo: json['memo'] as String?,
      signerBsms: json['signerBsms'] as String?,
    );

Map<String, dynamic> _$MultisigSignerToJson(MultisigSigner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'innerVaultId': instance.innerVaultId,
      'memo': instance.memo,
      'signerBsms': instance.signerBsms,
    };
