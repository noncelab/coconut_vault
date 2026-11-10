import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/exception/wallet_data_exception.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/model/taproot/stored_taproot_seed_info.dart';
import 'package:coconut_vault/repository/migration/data_schema_migration_runner.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/legacy_inheritance_fixtures.dart';

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
    expect(savedTaprootInfo.descriptor, contains('after_drop(1780012800)'));
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

  group('vault 3.3.0 inheritance wallets', () {
    setUpAll(() {
      NetworkType.setNetworkType(NetworkType.testnet);
    });

    TaprootWalletPrivacyInfo storedPrivacyInfo(LegacyInheritanceFixture fixture) {
      return TaprootWalletPrivacyInfo(
        descriptor: fixture.storedDescriptor,
        keyPathSeedInfos: [],
        scriptPathSeedInfos: [
          ScriptPathSeedInfo(
            key: hashString(fixture.storedMiniscript),
            role: ScriptPathRole.beneficiary,
            seedInfos: [
              StoredTaprootSeedInfo(
                extendedPublicKey:
                    TaprootVault.fromDescriptor(
                      legacyChildDescriptor,
                    ).keyStoreList.single.extendedPublicKey.serialize(),
                isPassphraseSet: false,
              ),
            ],
          ),
        ],
      );
    }

    for (final fixture in legacyInheritanceFixtures) {
      test('keeps addresses and re-keys the beneficiary seed, '
          'parents=${fixture.parentMnemonics.length} locktime=${fixture.locktime}', () async {
        final sharedPrefs = SharedPrefsRepository();
        final privacyInfo = storedPrivacyInfo(fixture);
        WalletPrivacyInfo? savedInfo;

        final migratedIds = await DataSchemaMigrationRunner.runDataSchemaMigrations(
          3,
          4,
          [
            {'id': 3, 'vaultType': WalletType.taproot.name},
          ],
          sharedPrefs,
          (id, walletType, data) async => savedInfo = data,
          (id, walletType) async => privacyInfo,
        );

        expect(migratedIds, isEmpty);
        final savedTaprootInfo = savedInfo as TaprootWalletPrivacyInfo;
        expect(savedTaprootInfo.descriptor, contains('after_drop(${fixture.locktime})'));
        final vault = TaprootVault.fromDescriptor(savedTaprootInfo.descriptor);
        expect(vault.getAddress(0), fixture.receive0);
        expect(vault.getAddress(0, isChange: true), fixture.change0);
        expect(
          savedTaprootInfo.scriptPathSeedInfos.single.key,
          ScriptPathSeedInfo.generateKey(vault.policyList.single),
        );
        expect(savedTaprootInfo.scriptPathSeedInfos.single.key, isNot(privacyInfo.scriptPathSeedInfos.single.key));
        expect(sharedPrefs.getWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate(), isEmpty);
        expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), 4);
      });
    }

    test('does not save a wallet that is already migrated', () async {
      final sharedPrefs = SharedPrefsRepository();
      final fixture = legacyInheritanceFixtures.first;
      TaprootWalletPrivacyInfo? privacyInfo = storedPrivacyInfo(fixture);
      final jsonList = [
        {'id': 3, 'vaultType': WalletType.taproot.name},
      ];
      await DataSchemaMigrationRunner.runDataSchemaMigrations(
        3,
        4,
        jsonList,
        sharedPrefs,
        (id, walletType, data) async => privacyInfo = data as TaprootWalletPrivacyInfo,
        (id, walletType) async => privacyInfo!,
      );
      var saveCount = 0;

      await DataSchemaMigrationRunner.runDataSchemaMigrations(
        3,
        4,
        jsonList,
        sharedPrefs,
        (id, walletType, data) async => saveCount++,
        (id, walletType) async => privacyInfo!,
      );

      expect(saveCount, 0);
    });

    test('skips an orphan wallet without privacy info', () async {
      final sharedPrefs = SharedPrefsRepository();
      final fixture = legacyInheritanceFixtures.first;
      final storage = <int, WalletPrivacyInfo>{2: storedPrivacyInfo(fixture)};

      await DataSchemaMigrationRunner.runDataSchemaMigrations(
        2,
        4,
        [
          {'id': 1, 'vaultType': WalletType.taproot.name},
          {'id': 2, 'vaultType': WalletType.taproot.name},
        ],
        sharedPrefs,
        (id, walletType, data) async => storage[id] = data,
        (id, walletType) async {
          final privacyInfo = storage[id];
          if (privacyInfo == null) throw PrivacyInfoNotFoundException(walletId: id, walletType: walletType);
          return privacyInfo;
        },
      );

      expect(storage.keys, [2]);
      final vault = TaprootVault.fromDescriptor((storage[2] as TaprootWalletPrivacyInfo).descriptor);
      expect(vault.getAddress(0), fixture.receive0);
      expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), 4);
    });
  });

  test('does not persist a target version when the migration path is unsupported', () async {
    final sharedPrefs = SharedPrefsRepository();

    expect(
      () => DataSchemaMigrationRunner.runDataSchemaMigrations(
        4,
        5,
        const [],
        sharedPrefs,
        (id, walletType, data) async {},
      ),
      throwsA(isA<StateError>()),
    );

    expect(sharedPrefs.getInt(SharedPrefsKeys.kDataSchemeVersion), isNull);
  });
}
