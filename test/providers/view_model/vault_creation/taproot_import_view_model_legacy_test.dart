import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/taproot_import_view_model.dart';
import 'package:coconut_vault/utils/migration/taproot_legacy_inheritance_migration.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/legacy_inheritance_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixture = legacyInheritanceFixtures.firstWhere(
    (fixture) => fixture.parentMnemonics.length == 1 && fixture.locktime == 1780012800,
  );

  setUp(() {
    NetworkType.setNetworkType(NetworkType.testnet);
  });

  TaprootWalletSyncData vault330SyncData() {
    return TaprootWalletSyncData.parse(
      jsonEncode({
        'name': 'vault 3.3.0',
        'colorIndex': 0,
        'iconIndex': 0,
        'descriptor': fixture.storedDescriptor,
        'keyPathSeedInfos': [],
        'scriptPathSeedInfos': [],
      }),
    );
  }

  for (final (role, mnemonic) in [
    (TaprootImportRole.beneficiary, legacyChildMnemonic),
    (TaprootImportRole.signer, legacyParentMnemonic1),
  ]) {
    test('imports a vault 3.3.0 sync QR as the legacy wallet without asking, role=${role.name}', () async {
      TaprootWalletCreateDto? addedDto;
      TaprootVaultListItem? createdVault;
      var backupNoticeCount = 0;
      final viewModel = TaprootImportViewModel(
        findWalletByDescriptor: (_) => null,
        addTaprootVault: (dto) async {
          addedDto = dto;
          createdVault = WalletIsolates.createTaprootVault((dto..id = 1).toJson()).vault;
          NetworkType.setNetworkType(NetworkType.testnet);
          return createdVault!;
        },
        addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate: (_) async => backupNoticeCount++,
      );

      viewModel.setWalletSyncData(vault330SyncData());
      viewModel.setRole(role);
      final isMatched = await viewModel.setImportedSeed(secret: Uint8List.fromList(utf8.encode(mnemonic)));
      final saved = await viewModel.saveImportedWallet();

      expect(isMatched, isTrue);
      expect(addedDto!.inheritanceLeaves!.single.form, InheritanceLeafForm.legacy);
      expect(saved.vaultId, 1);
      expect(backupNoticeCount, 0);
      expect(createdVault!.descriptor, contains('after_drop(${fixture.locktime})'));
      expect(createdVault!.coconutVault.getAddress(0), fixture.receive0);
      expect(createdVault!.coconutVault.getAddress(0, isChange: true), fixture.change0);
    });
  }

  TaprootWalletSyncData syncDataOf(String descriptor) {
    return TaprootWalletSyncData.parse(
      jsonEncode({'name': 'inheritance', 'colorIndex': 0, 'iconIndex': 0, 'descriptor': descriptor}),
    );
  }

  String currentDescriptor() {
    KeyStore keyStore(String mnemonic) =>
        KeyStore.fromSeed(Seed.fromMnemonic(Uint8List.fromList(utf8.encode(mnemonic))), AddressType.p2tr);
    final child = TaprootVault.fromKeyStoreList([keyStore(legacyChildMnemonic)], []).descriptor;
    return TaprootVault.fromKeyStoreList(
      [keyStore(legacyParentMnemonic1)],
      [InheritancePolicy.fromDescriptorAndLocktime(child, fixture.locktime)],
    ).descriptor;
  }

  final sources = [
    (
      name: 'after_drop QR from vault 3.4.0',
      descriptor: () => TaprootLegacyInheritanceMigration.migrateDescriptor(fixture.storedDescriptor).descriptor,
      form: InheritanceLeafForm.legacy,
      receive0: fixture.receive0,
    ),
    (
      name: 'current QR from vault 3.4.0',
      descriptor: currentDescriptor,
      form: InheritanceLeafForm.current,
      receive0: 'tb1pcnwfgvdym3sewa7cdccscmensvy45lfes4hla3j887ul0lxlzmzqk9n266',
    ),
  ];

  for (final source in sources) {
    for (final (role, mnemonic) in [
      (TaprootImportRole.beneficiary, legacyChildMnemonic),
      (TaprootImportRole.signer, legacyParentMnemonic1),
    ]) {
      test('imports the ${source.name} as it is, role=${role.name}', () async {
        TaprootWalletCreateDto? addedDto;
        TaprootVaultListItem? createdVault;
        final descriptor = source.descriptor();
        final viewModel = TaprootImportViewModel(
          findWalletByDescriptor: (_) => null,
          addTaprootVault: (dto) async {
            addedDto = dto;
            createdVault = WalletIsolates.createTaprootVault((dto..id = 1).toJson()).vault;
            NetworkType.setNetworkType(NetworkType.testnet);
            return createdVault!;
          },
          addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate: (_) async {},
        );

        viewModel.setWalletSyncData(syncDataOf(descriptor));
        viewModel.setRole(role);
        final isMatched = await viewModel.setImportedSeed(secret: Uint8List.fromList(utf8.encode(mnemonic)));
        await viewModel.saveImportedWallet();

        expect(isMatched, isTrue);
        expect(addedDto!.inheritanceLeaves!.single.form, source.form);
        expect(createdVault!.descriptor, descriptor);
        expect(createdVault!.coconutVault.getAddress(0), source.receive0);
        expect(viewModel.scannedFirstAddress!.address, source.receive0);
      });
    }
  }

  for (final (role, mnemonic) in [
    (TaprootImportRole.beneficiary, legacyChildMnemonic),
    (TaprootImportRole.signer, legacyParentMnemonic1),
  ]) {
    test('imports an older backup QR from vault 3.0.x as the legacy wallet, role=${role.name}', () async {
      final olderBody = fixture.storedDescriptor.split('#').first.replaceFirst('),after(', '),older(');
      final olderDescriptor = '$olderBody#${Checksum.getChecksum(olderBody)}';
      TaprootVaultListItem? createdVault;
      final backupNoticeIds = <int>[];
      final viewModel = TaprootImportViewModel(
        findWalletByDescriptor: (_) => null,
        addTaprootVault: (dto) async {
          createdVault = WalletIsolates.createTaprootVault((dto..id = 1).toJson()).vault;
          NetworkType.setNetworkType(NetworkType.testnet);
          return createdVault!;
        },
        addWalletIdWithUnacknowledgedOlderToAfterBackupUpdate: (walletId) async => backupNoticeIds.add(walletId),
      );

      viewModel.setWalletSyncData(syncDataOf(olderDescriptor));
      viewModel.setRole(role);
      final isMatched = await viewModel.setImportedSeed(secret: Uint8List.fromList(utf8.encode(mnemonic)));
      await viewModel.saveImportedWallet();

      expect(isMatched, isTrue);
      expect(viewModel.scannedFirstAddress!.address, fixture.receive0);
      expect(createdVault!.descriptor, contains('after_drop(${fixture.locktime})'));
      expect(createdVault!.descriptor, isNot(contains('older(')));
      expect(createdVault!.coconutVault.getAddress(0), fixture.receive0);
      expect(createdVault!.coconutVault.getAddress(0, isChange: true), fixture.change0);
      expect(backupNoticeIds, [1]);
    });
  }
}
