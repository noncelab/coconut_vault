import 'package:coconut_vault/model/data/vault_list_item_base.dart';

abstract class VaultListItemFactory {
  Future<VaultListItemBase> create({
    required int nextId,
    required String name,
    required int colorIndex,
    required int iconIndex,
    required Map<String, dynamic> secrets,
  });

  VaultListItemBase createFromJson(Map<String, dynamic> json);
}
