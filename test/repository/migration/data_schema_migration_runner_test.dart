import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/model/taproot/stored_taproot_seed_info.dart';
import 'package:coconut_vault/repository/migration/data_schema_migration_runner.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
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
    );

    expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), 2);
  });

  test('repairs legacy Taproot inheritance descriptors and stores migrated wallet ids', () async {
    final sharedPrefs = SharedPrefsRepository();
    const legacyDescriptor =
        "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))})#s63akr4t";
    var privacyInfo = TaprootWalletPrivacyInfo(
      descriptor: legacyDescriptor,
      keyPathSeedInfos: [],
      scriptPathSeedInfos: [
        ScriptPathSeedInfo(
          key: 'legacy-script-path-key',
          role: ScriptPathRole.beneficiary,
          seedInfos: [
            StoredTaprootSeedInfo(
              extendedPublicKey:
                  "tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU",
              isPassphraseSet: false,
            ),
          ],
        ),
      ],
    );
    WalletPrivacyInfo? savedInfo;

    final migratedIds = await DataSchemaMigrationRunner.runDataSchemaMigrations(
      2,
      3,
      [
        {'id': 7, 'vaultType': WalletType.taproot.name},
      ],
      sharedPrefs,
      (id, walletType, data) async => savedInfo = data,
      (id, walletType) async => privacyInfo,
    );

    expect(migratedIds, [7]);
    final savedTaprootInfo = savedInfo as TaprootWalletPrivacyInfo;
    expect(savedTaprootInfo.descriptor, contains('after(1780012800)'));
    expect(Checksum.isValidChecksum(savedTaprootInfo.descriptor), isTrue);
    final repairedPolicy = TaprootVault.fromDescriptor(savedTaprootInfo.descriptor).policyList.single;
    expect(savedTaprootInfo.scriptPathSeedInfos.single.key, ScriptPathSeedInfo.generateKey(repairedPolicy));
    expect(
      savedTaprootInfo.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
      contains('tpubDCteo5kJNojze'),
    );
    expect(sharedPrefs.getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate(), {7});
  });

  test('stores unacknowledged wallet ids as a deduplicated string list', () async {
    final sharedPrefs = SharedPrefsRepository();

    await sharedPrefs.addWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate([1, 2]);
    await sharedPrefs.addWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate([2, 3]);

    expect(sharedPrefs.getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate(), {1, 2, 3});
    expect(sharedPrefs.hasUnacknowledgedOlderToAfterBackupUpdate(2), isTrue);

    await sharedPrefs.removeWalletIdWithUnacknowledgedOlderToAfterBackupUpdate(2);

    expect(sharedPrefs.getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate(), {1, 3});
    expect(sharedPrefs.hasUnacknowledgedOlderToAfterBackupUpdate(2), isFalse);
  });

  test('does not persist a target version when the migration path is unsupported', () async {
    final sharedPrefs = SharedPrefsRepository();

    expect(
      () => DataSchemaMigrationRunner.runDataSchemaMigrations(
        3,
        4,
        const [],
        sharedPrefs,
        (id, walletType, data) async {},
      ),
      throwsA(isA<StateError>()),
    );

    expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), isNull);
  });
}
