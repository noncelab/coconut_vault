// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multisig_import_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultisigImportDetail _$MultisigImportDetailFromJson(
        Map<String, dynamic> json) =>
    MultisigImportDetail(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      colorIndex: (json['colorIndex'] as num).toInt(),
      iconIndex: (json['iconIndex'] as num).toInt(),
      namesMap: Map<String, String>.from(json['namesMap'] as Map),
      coordinatorBsms: json['coordinatorBsms'] as String,
    );

Map<String, dynamic> _$MultisigImportDetailToJson(
        MultisigImportDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorIndex': instance.colorIndex,
      'iconIndex': instance.iconIndex,
      'namesMap': instance.namesMap,
      'coordinatorBsms': instance.coordinatorBsms,
    };
