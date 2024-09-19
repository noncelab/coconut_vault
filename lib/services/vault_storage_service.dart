import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/services/realm_service.dart';
import 'package:coconut_vault/services/secure_storage_service.dart';

class VaultStorageService {
  VaultStorageService._internal();

  static final VaultStorageService _instance = VaultStorageService._internal();

  static final SecureStorageService _secureStorage = SecureStorageService();
  static final RealmService _realmService = RealmService();

  factory VaultStorageService() {
    return _instance;
  }

  // TODO: 추가, 수정 로직도 여기로 옮겨야 함

  Future<void> reset(AppModel appModel) async {
    await _secureStorage.deleteAll();
    _realmService.deleteAll();
    appModel.resetPassword();
  }
}
