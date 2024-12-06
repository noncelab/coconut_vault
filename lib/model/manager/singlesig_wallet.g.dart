// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'singlesig_wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SinglesigWallet _$SinglesigWalletFromJson(Map<String, dynamic> json) =>
    SinglesigWallet(
      (json['id'] as num?)?.toInt(),
      json['name'] as String?,
      (json['icon'] as num?)?.toInt(),
      (json['color'] as num?)?.toInt(),
      json['mnemonic'] as String?,
      json['passphrase'] as String?,
    );

Map<String, dynamic> _$SinglesigWalletToJson(SinglesigWallet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'mnemonic': instance.mnemonic,
      'passphrase': instance.passphrase,
    };
