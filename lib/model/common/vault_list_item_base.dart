import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(ignoreUnannotated: true)
abstract class VaultListItemBase {
  static const String vaultTypeField = 'vaultType';

  @JsonKey(name: "id")
  final int id;
  @JsonKey(name: "name")
  String name;
  @JsonKey(name: "colorIndex")
  int colorIndex;
  @JsonKey(name: "iconIndex")
  int iconIndex;
  @JsonKey(name: vaultTypeField)
  WalletType vaultType;
  @JsonKey(name: "createdAt")
  DateTime createdAt;

  late WalletBase coconutVault;

  VaultListItemBase({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.iconIndex,
    required this.vaultType,
    required this.createdAt,
  });

  Future<bool> canSign(String psbt);

  String getWalletSyncString();

  Map<String, dynamic> toJson();
  // factory fromJson은 abstract class에 선언 불가하여 생략했습니다. 하지만 새로운 타입의 지갑 list item class 추가 시 꼭 구현 필요.

  @override
  String toString() => 'Vault($id) / type=$vaultType / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';
}
