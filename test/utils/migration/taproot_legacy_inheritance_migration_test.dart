import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/migration/taproot_legacy_inheritance_migration.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/legacy_inheritance_fixtures.dart';

void main() {
  setUpAll(() {
    NetworkType.setNetworkType(NetworkType.testnet);
  });

  const beneficiary =
      "[A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*";
  const internalKey =
      "[6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*";
  const olderMiniscript = "and_v(v:pk($beneficiary),older(1780012800))";
  const afterMiniscript = "and_v(v:pk($beneficiary),after(1780012800))";
  const afterDropMiniscript = "and_v(after_drop(1780012800),pk($beneficiary))";
  const verifyMiniscript = "and_v(v:after(1780012800),pk($beneficiary))";
  const olderDescriptor = "tr($internalKey,{$olderMiniscript})#s63akr4t";
  const afterDescriptor = "tr($internalKey,{$afterMiniscript})#ady0n4rm";

  String withChecksum(String body) => '$body#${Checksum.getChecksum(body)}';

  group('migrateMiniscript', () {
    test('converts older and after spellings to after_drop', () {
      expect(TaprootLegacyInheritanceMigration.migrateMiniscript(olderMiniscript), afterDropMiniscript);
      expect(TaprootLegacyInheritanceMigration.migrateMiniscript(afterMiniscript), afterDropMiniscript);
    });

    test('keeps after_drop and verify spellings', () {
      expect(TaprootLegacyInheritanceMigration.migrateMiniscript(afterDropMiniscript), afterDropMiniscript);
      expect(TaprootLegacyInheritanceMigration.migrateMiniscript(verifyMiniscript), verifyMiniscript);
    });
  });

  group('migrateDescriptor', () {
    test('converts a vault 3.0.x descriptor and reports older', () {
      final result = TaprootLegacyInheritanceMigration.migrateDescriptor(olderDescriptor);

      expect(result.descriptor, withChecksum("tr($internalKey,$afterDropMiniscript)"));
      expect(result.hasChanges, isTrue);
      expect(result.hasOlder, isTrue);
      expect(Checksum.isValidChecksum(result.descriptor), isTrue);
    });

    test('converts a vault 3.3.0 descriptor without reporting older', () {
      final result = TaprootLegacyInheritanceMigration.migrateDescriptor(afterDescriptor);

      expect(result.descriptor, withChecksum("tr($internalKey,$afterDropMiniscript)"));
      expect(result.hasChanges, isTrue);
      expect(result.hasOlder, isFalse);
    });

    test('does not change a migrated descriptor', () {
      final migrated = TaprootLegacyInheritanceMigration.migrateDescriptor(afterDescriptor).descriptor;
      final result = TaprootLegacyInheritanceMigration.migrateDescriptor(migrated);

      expect(result.descriptor, migrated);
      expect(result.hasChanges, isFalse);
      expect(result.hasOlder, isFalse);
    });

    test('does not change a verify descriptor', () {
      final verifyDescriptor = withChecksum("tr($internalKey,$verifyMiniscript)");
      final result = TaprootLegacyInheritanceMigration.migrateDescriptor(verifyDescriptor);

      expect(result.descriptor, verifyDescriptor);
      expect(result.hasChanges, isFalse);
      expect(TaprootVault.fromDescriptor(result.descriptor).policyList.single, isNot(isA<LegacyInheritancePolicy>()));
    });
  });

  group('addresses of vault 3.3.0 inheritance wallets', () {
    for (final fixture in legacyInheritanceFixtures) {
      test('parents=${fixture.parentMnemonics.length} locktime=${fixture.locktime}', () {
        final descriptor = TaprootLegacyInheritanceMigration.migrateDescriptor(fixture.storedDescriptor).descriptor;
        final vault = TaprootVault.fromDescriptor(descriptor);

        expect(descriptor, contains('after_drop(${fixture.locktime})'));
        expect(vault.policyList.single, isA<LegacyInheritancePolicy>());
        expect(vault.getAddress(0), fixture.receive0);
        expect(vault.getAddress(1), fixture.receive1);
        expect(vault.getAddress(0, isChange: true), fixture.change0);
      });

      test('parents=${fixture.parentMnemonics.length} locktime=${fixture.locktime} older spelling', () {
        final olderBody = fixture.storedDescriptor.split('#').first.replaceFirst('),after(', '),older(');
        final descriptor = TaprootLegacyInheritanceMigration.migrateDescriptor(withChecksum(olderBody)).descriptor;

        expect(TaprootVault.fromDescriptor(descriptor).getAddress(0), fixture.receive0);
      });
    }

    test('the stored descriptor read without migration derives another address', () {
      final fixture = legacyInheritanceFixtures.last;

      expect(TaprootVault.fromDescriptor(fixture.storedDescriptor).getAddress(0), isNot(fixture.receive0));
    });
  });
}
