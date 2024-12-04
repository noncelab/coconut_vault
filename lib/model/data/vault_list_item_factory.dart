import 'package:coconut_vault/model/data/vault_list_item_base.dart';

abstract class VaultListItemFactory {
  VaultListItemBase createFromJson(Map<String, dynamic> json);
}
