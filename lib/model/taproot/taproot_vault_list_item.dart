import 'dart:collection';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taproot_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true, createFactory: false)
class TaprootVaultListItem extends VaultListItemBase {
  static const fieldDescriptor = 'descriptor';
  static const fieldKeyPathSeedInfos = 'keyPathSeedInfos';
  static const fieldBeneficiarySeedInfos = 'beneficiarySeedInfos';

  @JsonKey(name: fieldDescriptor)
  final String descriptor;
  @JsonKey(name: fieldKeyPathSeedInfos)
  final List<TaprootSeedInfo> _keyPathSeedInfos;
  List<TaprootSeedInfo> get keyPathSeedInfos => _keyPathSeedInfos;
  @JsonKey(name: fieldBeneficiarySeedInfos)
  final List<TaprootSeedInfo> _beneficiarySeedInfos;
  List<TaprootSeedInfo> get beneficiarySeedInfos => _beneficiarySeedInfos;

  late final bool _isParent;

  TaprootVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required super.createdAt,
    required this.descriptor,
    required List<TaprootSeedInfo> keyPathSeedInfos,
    required List<TaprootSeedInfo> beneficiarySeedInfos,
  }) : _keyPathSeedInfos = List.unmodifiable(keyPathSeedInfos),
       _beneficiarySeedInfos = List.unmodifiable(beneficiarySeedInfos),
       super(vaultType: WalletType.taproot) {
    coconutVault = TaprootVault.fromDescriotor(descriptor);

    _isParent = keyPathSeedInfos.isNotEmpty;
  }

  bool get isParent => _isParent;

  @override
  Future<bool> canSign(String psbt) async => false;

  @override
  String getWalletSyncString() => '';

  @override
  Map<String, dynamic> toJson() => _$TaprootVaultListItemToJson(this);

  @override
  Map<String, dynamic> toPublicJson() {
    final json = toJson();
    json.remove(fieldDescriptor);
    json.remove(fieldKeyPathSeedInfos);
    json.remove(fieldBeneficiarySeedInfos);
    return json;
  }

  factory TaprootVaultListItem.fromJson(Map<String, dynamic> json) {
    return TaprootVaultListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      colorIndex: json['colorIndex'] as int,
      iconIndex: json['iconIndex'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      descriptor: json[fieldDescriptor] as String,
      keyPathSeedInfos:
          (json[fieldKeyPathSeedInfos] as List<dynamic>)
              .map((e) => TaprootSeedInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
      beneficiarySeedInfos:
          (json[fieldBeneficiarySeedInfos] as List<dynamic>)
              .map((e) => TaprootSeedInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
