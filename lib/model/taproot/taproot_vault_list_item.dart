import 'package:coconut_vault/model/common/vault_list_item_base.dart';

class TaprootVaultListItem extends VaultListItemBase {
  final bool isParent;

  TaprootVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required super.createdAt,
    required super.vaultType,
    required this.isParent,
  });

  @override
  Future<bool> canSign(String psbt) async => false;

  @override
  String getWalletSyncString() => '';

  @override
  Map<String, dynamic> toJson() => {};

  @override
  Map<String, dynamic> toPublicJson() => {};
}
