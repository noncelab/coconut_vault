import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(ignoreUnannotated: true)
abstract class VaultListItemBase {
  @JsonKey(name: "id")
  final int id;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "colorIndex")
  final int colorIndex;
  @JsonKey(name: "iconIndex")
  final int iconIndex;
  @JsonKey(name: "vaultJsonString")
  String? vaultJsonString;
  @JsonKey(name: "vaultType")
  VaultType vaultType;

  late WalletBase coconutVault;

  VaultListItemBase(
      {required this.id,
      required this.name,
      required this.colorIndex,
      required this.iconIndex,
      this.vaultJsonString,
      required this.vaultType});

  String getWalletSyncString();

  Map<String, dynamic> toJson();
  // factory fromJson은 abstract class에 선언 불가하여 생략했습니다. 하지만 새로운 타입의 지갑 list item class 추가 시 꼭 구현 필요.

  @override
  String toString() =>
      'Vault($id) / type=$vaultType / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';
}
