import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/utils/migration/taproot_legacy_inheritance_migration.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/legacy_inheritance_fixtures.dart';

void main() {
  setUp(() {
    NetworkType.setNetworkType(NetworkType.testnet);
  });

  SeedSource seedSource(String mnemonic) =>
      SeedSource(mnemonic: Uint8List.fromList(utf8.encode(mnemonic)), passphrase: Uint8List(0));

  Seed seed(String mnemonic) => Seed.fromMnemonic(Uint8List.fromList(utf8.encode(mnemonic)));

  TaprootVaultListItem createVault({required List<String> parentMnemonics, required InheritanceLeaf leaf}) {
    final dto = TaprootWalletCreateDto(null, 'inheritance', 0, 0, parentMnemonics.map(seedSource).toList(), null, [
      leaf,
    ])..id = 0;
    final vault = WalletIsolates.createTaprootVault(dto.toJson()).vault;
    NetworkType.setNetworkType(NetworkType.testnet);
    return vault;
  }

  LegacyInheritanceFixture fixtureOf(int parentCount, int locktime) => legacyInheritanceFixtures.firstWhere(
    (fixture) => fixture.parentMnemonics.length == parentCount && fixture.locktime == locktime,
  );

  group('InheritanceLeaf JSON', () {
    test('reads a leaf without form as current', () {
      final leaf = InheritanceLeaf.fromJson({'descriptor': legacyChildDescriptor, 'lockTime': 1780012800});

      expect(leaf.form, InheritanceLeafForm.current);
    });

    test('keeps the legacy form through JSON', () {
      final leaf = InheritanceLeaf(
        descriptor: legacyChildDescriptor,
        lockTime: 1780012800,
        form: InheritanceLeafForm.legacy,
      );

      expect(InheritanceLeaf.fromJson(leaf.toJson()).form, InheritanceLeafForm.legacy);
    });
  });

  group('recreating a vault 3.3.0 inheritance wallet', () {
    for (final fixture in legacyInheritanceFixtures) {
      final tag = 'parents=${fixture.parentMnemonics.length} locktime=${fixture.locktime}';

      test('$tag / beneficiary seed', () {
        final vault = createVault(
          parentMnemonics: fixture.parentMnemonics,
          leaf: InheritanceLeaf(
            secret: seedSource(legacyChildMnemonic),
            lockTime: fixture.locktime,
            form: InheritanceLeafForm.legacy,
          ),
        );

        expect(
          vault.descriptor,
          TaprootLegacyInheritanceMigration.migrateDescriptor(fixture.storedDescriptor).descriptor,
        );
        expect(vault.coconutVault.getAddress(0), fixture.receive0);
        expect(vault.coconutVault.getAddress(1), fixture.receive1);
        expect(vault.coconutVault.getAddress(0, isChange: true), fixture.change0);
        expect(vault.beneficiaries.single.isSeedStored, isTrue);
      });

      test('$tag / beneficiary descriptor', () {
        final vault = createVault(
          parentMnemonics: fixture.parentMnemonics,
          leaf: InheritanceLeaf(
            descriptor: legacyChildDescriptor,
            lockTime: fixture.locktime,
            form: InheritanceLeafForm.legacy,
          ),
        );

        expect(vault.coconutVault.getAddress(0), fixture.receive0);
      });
    }

    test('rejects locktime 0 only in the current form', () {
      expect(
        () => createVault(
          parentMnemonics: [legacyParentMnemonic1],
          leaf: InheritanceLeaf(descriptor: legacyChildDescriptor, lockTime: 0),
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('current inheritance wallets', () {
    const currentAddresses = {
      150: (
        receive0: 'tb1pd7p0u46m42asrzy0gcxn6t0waenh30kpvj9skcru8lavmf5xwklqswl84v',
        change0: 'tb1pf9p4xw2x0u2s72fs2s9xt4ptyxnz0zcdmaqaje0unmglnmqns3dqyvf66x',
      ),
      1780012800: (
        receive0: 'tb1pcnwfgvdym3sewa7cdccscmensvy45lfes4hla3j887ul0lxlzmzqk9n266',
        change0: 'tb1p5zafpvy52jrh4ckzkgkkt83f0egnupd6hz4ad09l2cuphyz395jqf4y5h0',
      ),
    };

    for (final MapEntry(key: locktime, value: expected) in currentAddresses.entries) {
      test('keeps the addresses of the current form, locktime=$locktime', () {
        final vault = createVault(
          parentMnemonics: [legacyParentMnemonic1],
          leaf: InheritanceLeaf(secret: seedSource(legacyChildMnemonic), lockTime: locktime),
        );

        expect(vault.descriptor, contains('and_v(v:after($locktime),pk('));
        expect(vault.coconutVault.getAddress(0), expected.receive0);
        expect(vault.coconutVault.getAddress(0, isChange: true), expected.change0);
        expect(vault.coconutVault.getAddress(0), isNot(fixtureOf(1, locktime).receive0));
      });
    }
  });

  group('wallet sync of a legacy inheritance wallet', () {
    test('exports after_drop and reads it back as the same wallet', () {
      final fixture = fixtureOf(1, 1780012800);
      final vault = createVault(
        parentMnemonics: fixture.parentMnemonics,
        leaf: InheritanceLeaf(
          secret: seedSource(legacyChildMnemonic),
          lockTime: fixture.locktime,
          form: InheritanceLeafForm.legacy,
        ),
      );

      final syncString = vault.getWalletSyncString();
      final syncJson = jsonDecode(syncString) as Map<String, dynamic>;
      final syncData = TaprootWalletSyncData.parse(syncString);

      expect(syncJson['descriptor'], contains('after_drop(${fixture.locktime})'));
      expect((syncJson['scriptPathSeedInfos'] as List).single['miniscript'], startsWith('and_v(after_drop('));
      expect(syncData.descriptor, vault.descriptor);
      expect(syncData.wasMigratedFromOlderToAfter, isFalse);
    });

    test('reads a vault 3.3.0 sync QR as the legacy wallet', () {
      final fixture = fixtureOf(1, 1780012800);
      final syncData = TaprootWalletSyncData.parse(
        jsonEncode({
          'name': 'vault 3.3.0',
          'colorIndex': 0,
          'iconIndex': 0,
          'descriptor': fixture.storedDescriptor,
          'keyPathSeedInfos': [],
          'scriptPathSeedInfos': [
            {'miniscript': fixture.storedMiniscript, 'extendedPublicKeys': []},
          ],
        }),
      );

      expect(syncData.descriptor, contains('after_drop(${fixture.locktime})'));
      expect(syncData.scriptPathSeedInfos.single.miniscript, startsWith('and_v(after_drop('));
      expect(TaprootVault.fromDescriptor(syncData.descriptor).getAddress(0), fixture.receive0);
      expect(syncData.wasMigratedFromOlderToAfter, isFalse);
    });
  });

  group('signing with a legacy inheritance wallet', () {
    for (final parentCount in [1, 2]) {
      test('script path, parents=$parentCount', () async {
        final fixture = fixtureOf(parentCount, 1780012800);
        final vault = createVault(
          parentMnemonics: fixture.parentMnemonics,
          leaf: InheritanceLeaf(
            descriptor: legacyChildDescriptor,
            lockTime: fixture.locktime,
            form: InheritanceLeafForm.legacy,
          ),
        );
        NetworkType.setNetworkType(NetworkType.regtest);
        final taprootVault = vault.coconutVault as TaprootVault;
        final policy = taprootVault.policyList.single as LegacyInheritancePolicy;
        final psbt = _createPsbt(taprootVault, policy: policy, lockTime: policy.locktime);

        expect(await SignIsolates.canSignToPsbtWithTaprootVault([taprootVault, psbt]), isTrue);
        final signed = await SignIsolates.signWithBeneficiary([seed(legacyChildMnemonic), psbt, vault.coordinatorBsms]);
        final signedInput = Psbt.parse(signed).inputs.single;

        expect(signedInput.tapScriptSig, isNotNull);
        expect(Psbt.parse(signed).getSignedTransaction(AddressType.p2tr).serialize(), isNotEmpty);
      });
    }

    test('key path, parents=1', () async {
      final fixture = fixtureOf(1, 1780012800);
      final vault = createVault(
        parentMnemonics: fixture.parentMnemonics,
        leaf: InheritanceLeaf(
          descriptor: legacyChildDescriptor,
          lockTime: fixture.locktime,
          form: InheritanceLeafForm.legacy,
        ),
      );
      NetworkType.setNetworkType(NetworkType.regtest);
      final psbt = _createPsbt(vault.coconutVault as TaprootVault);

      final signed = await SignIsolates.signWithSingleKeyPath([
        seed(fixture.parentMnemonics.single),
        psbt,
        vault.coordinatorBsms,
      ]);

      expect(Psbt.parse(signed).inputs.single.tapKeySig, isNotNull);
      expect(Psbt.parse(signed).getSignedTransaction(AddressType.p2tr).serialize(), isNotEmpty);
    });
  });
}

String _createPsbt(TaprootVault vault, {Policy? policy, int lockTime = 0}) {
  final utxo = Utxo(Codec.encodeHex(Hash.sha256('legacy-inheritance')), 0, 100000, '${vault.derivationPath}/0/0');
  final tx = Transaction.forSinglePayment(
    [utxo],
    vault.getAddress(1),
    '${vault.derivationPath}/1/0',
    10000,
    2,
    vault,
    lockTime: lockTime,
    policy: policy,
  );
  return Psbt.fromTransaction(tx, vault).serialize();
}
