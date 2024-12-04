// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Secret _$SecretFromJson(Map<String, dynamic> json) => Secret(
      json['mnemonic'] as String,
      json['passphrase'] as String,
    );

Map<String, dynamic> _$SecretToJson(Secret instance) => <String, dynamic>{
      'mnemonic': instance.mnemonic,
      'passphrase': instance.passphrase,
    };
