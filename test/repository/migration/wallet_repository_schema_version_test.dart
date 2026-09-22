import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsRepository().init();
  });

  test('initializes the schema version through the migration runner for an empty vault', () async {
    final sharedPrefs = SharedPrefsRepository();
    final repository = WalletRepository();

    await repository.loadVaultListJsonArrayString();

    expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), WalletRepository.currentVaultDataSchemaVersion);
  });
}
