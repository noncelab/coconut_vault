import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/vault_type.dart';
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

  @override
  String toString() =>
      'Vault($id) / type=$vaultType / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';
}
