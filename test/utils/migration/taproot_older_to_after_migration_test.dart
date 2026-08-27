import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/migration/taproot_older_to_after_migration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    NetworkType.setNetworkType(NetworkType.testnet);
  });

  const legacyMiniscript =
      "and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))";
  const migratedMiniscript =
      "and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),after(1780012800))";
  const legacyDescriptor =
      "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{$legacyMiniscript})#s63akr4t";
  const migratedDescriptor =
      "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{$migratedMiniscript})#ady0n4rm";

  test('migrates legacy inheritance miniscript to after', () {
    expect(TaprootOlderToAfterMigration.migrateMiniscript(legacyMiniscript), migratedMiniscript);
  });

  test('does not change an already migrated miniscript', () {
    expect(TaprootOlderToAfterMigration.migrateMiniscript(migratedMiniscript), migratedMiniscript);
  });

  test('migrates descriptor and recalculates checksum', () {
    final result = TaprootOlderToAfterMigration.migrateDescriptor(legacyDescriptor);

    expect(result.descriptor, migratedDescriptor);
    expect(result.hasChanges, isTrue);
    expect(Checksum.isValidChecksum(result.descriptor), isTrue);
  });

  test('does not report changes for a current descriptor', () {
    final result = TaprootOlderToAfterMigration.migrateDescriptor(migratedDescriptor);

    expect(result.descriptor, migratedDescriptor);
    expect(result.hasChanges, isFalse);
  });
}
