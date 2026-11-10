import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/child_creation_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/legacy_inheritance_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NetworkType.setNetworkType(NetworkType.testnet);
  });

  test('creates the child wallet of a vault 3.3.0 parent as the legacy wallet without asking', () async {
    final fixture = legacyInheritanceFixtures.firstWhere(
      (fixture) => fixture.parentMnemonics.length == 2 && fixture.locktime == 1780012800,
    );
    final walletProvider = _FakeWalletProvider();
    final viewModel = ChildCreationViewModel(TaprootWalletCreationProvider(), walletProvider);
    viewModel.setCreationTypeToChild();
    viewModel.setSecretAndPassphrase(Uint8List.fromList(utf8.encode(legacyChildMnemonic)), null);
    viewModel.setupChildWalletInfo();

    final isScanned = viewModel.setScannedTaprootVault(
      TaprootWalletSyncData.parse(
        jsonEncode({
          'name': 'vault 3.3.0',
          'colorIndex': 0,
          'iconIndex': 0,
          'descriptor': fixture.storedDescriptor,
          'keyPathSeedInfos': [],
          'scriptPathSeedInfos': [],
        }),
      ),
    );
    await viewModel.saveVault();

    expect(isScanned, isTrue);
    expect(viewModel.isBeneficiaryMatch, isTrue);
    expect(walletProvider.addedForm, InheritanceLeafForm.legacy);
    final created = walletProvider.created!;
    expect(created.descriptor, contains('after_drop(${fixture.locktime})'));
    expect(created.coconutVault.getAddress(0), fixture.receive0);
    expect(created.coconutVault.getAddress(0, isChange: true), fixture.change0);
    expect(created.beneficiaries.single.isSeedStored, isTrue);
  });
}

class _FakeWalletProvider extends Fake implements WalletProvider {
  InheritanceLeafForm? addedForm;
  TaprootVaultListItem? created;

  @override
  Future<TaprootVaultListItem> addTaprootVault(TaprootWalletCreateDto wallet) async {
    addedForm = wallet.inheritanceLeaves!.single.form;
    created = WalletIsolates.createTaprootVault((wallet..id = 1).toJson()).vault;
    NetworkType.setNetworkType(NetworkType.testnet);
    return created!;
  }
}
