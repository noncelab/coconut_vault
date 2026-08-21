import 'dart:async';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/repository/migration/data_schema_migration_runner.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsRepository().init();
  });

  test('persists the vault data schema version after migration succeeds', () async {
    final sharedPrefs = SharedPrefsRepository();
    await sharedPrefs.setString(SharedPrefsKeys.kVaultMode, VaultMode.secureStorage.name);

    await DataSchemaMigrationRunner.runDataSchemaMigrations(
      1,
      2,
      const [],
      sharedPrefs,
      (id, walletType, data) async {},
      null,
    );

    expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), 2);
  });

  test('does not persist a target version when the migration path is unsupported', () async {
    final sharedPrefs = SharedPrefsRepository();

    expect(
      () => DataSchemaMigrationRunner.runDataSchemaMigrations(
        2,
        3,
        const [],
        sharedPrefs,
        (id, walletType, data) async {},
        Completer<void>(),
      ),
      throwsA(isA<StateError>()),
    );

    expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), isNull);
  });
}
