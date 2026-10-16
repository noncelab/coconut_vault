import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';

/// Share the existing reinstall cleanup between splash and authentication so a
/// late splash write cannot delete newly imported credentials or throttle state.
class FirstLaunchSecureStorageCleanup {
  static Future<void>? _pending;

  static Future<void> run() {
    if (_pending != null) return _pending!;
    if (SharedPrefsRepository().getBool(SharedPrefsKeys.hasShownStartGuide) == true) return Future.value();
    return _pending = SecureStorageRepository().deleteAll();
  }
}
