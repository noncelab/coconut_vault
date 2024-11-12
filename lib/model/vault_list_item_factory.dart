import 'package:coconut_vault/model/vault_list_item_base.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';

abstract class VaultListItemFactory {
  Future<VaultListItemBase> create(
      {required String name,
      required int colorIndex,
      required int iconIndex,
      required Map<String, dynamic> secrets});

  VaultListItemBase createFromJson(Map<String, dynamic> json);

  // 다음 일련번호를 저장하고 불러오는 메서드
  static int loadNextId() {
    return SharedPrefsService().getInt('nextId') ?? 1;
  }

  static Future<void> saveNextId(int nextId) async {
    await SharedPrefsService().setInt('nextId', nextId);
  }
}
