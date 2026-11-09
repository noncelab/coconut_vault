import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/core/wallet/taproot_validator.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/taproot_inheritance_form_mismatch_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/legacy_inheritance_fixtures.dart';

enum _Form { legacy, current }

enum _Path { script, key }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NetworkType.setNetworkType(NetworkType.regtest);
  });

  group('TaprootValidator.findInheritanceFormMismatch', () {
    for (final parentCount in [1, 2]) {
      for (final path in _Path.values) {
        test('legacy PSBT for a current wallet, parents=$parentCount path=${path.name}', () {
          final psbt = Psbt.parse(_createPsbt(_createVault(_Form.legacy, parentCount: parentCount), path));

          expect(
            TaprootValidator.findInheritanceFormMismatch(psbt, _createVault(_Form.current, parentCount: parentCount)),
            TaprootInheritanceFormMismatch.needsLegacyWallet,
          );
        });

        test('current PSBT for a legacy wallet, parents=$parentCount path=${path.name}', () {
          final psbt = Psbt.parse(_createPsbt(_createVault(_Form.current, parentCount: parentCount), path));

          expect(
            TaprootValidator.findInheritanceFormMismatch(psbt, _createVault(_Form.legacy, parentCount: parentCount)),
            TaprootInheritanceFormMismatch.needsWalletUpdate,
          );
        });
      }
    }

    test('returns null for a PSBT of the same form', () {
      final vault = _createVault(_Form.legacy);
      final psbt = Psbt.parse(_createPsbt(vault, _Path.script));

      expect(psbt.matchesVault(vault), isTrue);
      expect(TaprootValidator.findInheritanceFormMismatch(psbt, vault), isNull);
    });

    test('returns null for a PSBT of other keys', () {
      final psbt = Psbt.parse(_createPsbt(_createVault(_Form.legacy, locktime: 1780012801), _Path.script));

      expect(TaprootValidator.findInheritanceFormMismatch(psbt, _createVault(_Form.current)), isNull);
    });

    test('returns null for a legacy wallet with locktime 0', () {
      final psbt = Psbt.parse(_createPsbt(_createVault(_Form.legacy), _Path.script));

      expect(TaprootValidator.findInheritanceFormMismatch(psbt, _createVault(_Form.legacy, locktime: 0)), isNull);
    });
  });

  group('PSBT from Coconut Wallet 1.0.0', () {
    for (final parentCount in [1, 2]) {
      final fixture = legacyInheritanceFixtures.firstWhere(
        (fixture) => fixture.parentMnemonics.length == parentCount && fixture.locktime == 1780012800,
      );

      for (final path in _Path.values) {
        test('selects the legacy wallet, parents=$parentCount path=${path.name}', () async {
          final psbt = _withWalletIdentifier(
            _createPsbt(_createVault(_Form.legacy, parentCount: parentCount), path),
            fixture.storedDescriptor,
          );
          final legacyVault = _createVault(_Form.legacy, parentCount: parentCount);
          final vaultItem = _createVaultItem(1, legacyVault);
          final signProvider = SignProvider();
          final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);

          expect(Psbt.parse(psbt).matchesVault(legacyVault), isFalse);
          expect(TaprootValidator.matchesTaprootVault(Psbt.parse(psbt), legacyVault), isTrue);
          await viewModel.setMatchingVault(psbt);
          expect(signProvider.vaultListItem, same(vaultItem));
          await viewModel.preparePsbtForVault(1, psbt, hasDerivationPath: true);
        });

        test('asks to recreate the legacy wallet, parents=$parentCount path=${path.name}', () async {
          final psbt = _withWalletIdentifier(
            _createPsbt(_createVault(_Form.legacy, parentCount: parentCount), path),
            fixture.storedDescriptor,
          );
          final viewModel = PsbtScannerViewModel(
            _FakeWalletProvider([_createVaultItem(1, _createVault(_Form.current, parentCount: parentCount))]),
            SignProvider(),
          );

          await expectLater(
            viewModel.setMatchingVault(psbt),
            throwsA(
              isA<TaprootInheritanceFormMismatchException>().having(
                (e) => e.mismatch,
                'mismatch',
                TaprootInheritanceFormMismatch.needsLegacyWallet,
              ),
            ),
          );
        });
      }
    }

    test('does not select a legacy wallet with another locktime', () async {
      final fixture = legacyInheritanceFixtures.firstWhere(
        (fixture) => fixture.parentMnemonics.length == 1 && fixture.locktime == 1780012800,
      );
      final psbt = _withWalletIdentifier(_createPsbt(_createVault(_Form.legacy), _Path.key), fixture.storedDescriptor);
      final viewModel = PsbtScannerViewModel(
        _FakeWalletProvider([_createVaultItem(1, _createVault(_Form.legacy, locktime: 1780012801))]),
        SignProvider(),
      );

      await expectLater(viewModel.setMatchingVault(psbt), throwsA(isA<VaultNotFoundException>()));
    });
  });

  group('PsbtScannerViewModel with inheritance form mismatch', () {
    test('setMatchingVault asks to recreate the legacy wallet', () async {
      final psbt = _createPsbt(_createVault(_Form.legacy), _Path.script);
      final viewModel = PsbtScannerViewModel(
        _FakeWalletProvider([_createVaultItem(1, _createVault(_Form.current))]),
        SignProvider(),
      );

      await expectLater(
        viewModel.setMatchingVault(psbt),
        throwsA(
          isA<TaprootInheritanceFormMismatchException>().having(
            (e) => e.mismatch,
            'mismatch',
            TaprootInheritanceFormMismatch.needsLegacyWallet,
          ),
        ),
      );
    });

    test('setMatchingVault asks to update the wallet app', () async {
      final psbt = _createPsbt(_createVault(_Form.current), _Path.key);
      final viewModel = PsbtScannerViewModel(
        _FakeWalletProvider([_createVaultItem(1, _createVault(_Form.legacy))]),
        SignProvider(),
      );

      await expectLater(
        viewModel.setMatchingVault(psbt),
        throwsA(
          isA<TaprootInheritanceFormMismatchException>().having(
            (e) => e.mismatch,
            'mismatch',
            TaprootInheritanceFormMismatch.needsWalletUpdate,
          ),
        ),
      );
    });

    test('setMatchingVault keeps the not found error for other wallets', () async {
      final psbt = _createPsbt(_createVault(_Form.legacy, locktime: 1780012801), _Path.script);
      final viewModel = PsbtScannerViewModel(
        _FakeWalletProvider([
          _createVaultItem(1, _createVault(_Form.current)),
          _createVaultItem(2, _createVault(_Form.legacy, locktime: 0)),
        ]),
        SignProvider(),
      );

      await expectLater(viewModel.setMatchingVault(psbt), throwsA(isA<VaultNotFoundException>()));
    });

    test('setMatchingVault selects the wallet of the same form', () async {
      final vaultItem = _createVaultItem(1, _createVault(_Form.legacy));
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(
        _FakeWalletProvider([_createVaultItem(2, _createVault(_Form.current)), vaultItem]),
        signProvider,
      );

      await viewModel.setMatchingVault(_createPsbt(_createVault(_Form.legacy), _Path.script));

      expect(signProvider.vaultListItem, same(vaultItem));
    });

    test('preparePsbtForVault asks to recreate the legacy wallet', () async {
      final psbt = _createPsbt(_createVault(_Form.legacy), _Path.key);
      final viewModel = PsbtScannerViewModel(
        _FakeWalletProvider([_createVaultItem(1, _createVault(_Form.current))]),
        SignProvider(),
      );

      await expectLater(
        viewModel.preparePsbtForVault(1, psbt, hasDerivationPath: true),
        throwsA(isA<TaprootInheritanceFormMismatchException>()),
      );
    });
  });
}

KeyStore _keyStore(String mnemonic) =>
    KeyStore.fromSeed(Seed.fromMnemonic(Uint8List.fromList(utf8.encode(mnemonic))), AddressType.p2tr);

TaprootVault _createVault(_Form form, {int parentCount = 1, int locktime = 1780012800}) {
  final parents = [legacyParentMnemonic1, legacyParentMnemonic2].take(parentCount).map(_keyStore).toList();
  final beneficiary = TaprootVault.fromKeyStoreList([_keyStore(legacyChildMnemonic)], []).descriptor;
  final policy = switch (form) {
    _Form.legacy => LegacyInheritancePolicy.fromDescriptorAndLocktime(beneficiary, locktime),
    _Form.current => InheritancePolicy.fromDescriptorAndLocktime(beneficiary, locktime),
  };
  return TaprootVault.fromKeyStoreList(parents, [policy]);
}

String _createPsbt(TaprootVault vault, _Path path) {
  final policy = vault.policyList.single as InheritancePolicy;
  final utxo = Utxo(Codec.encodeHex(Hash.sha256('inheritance-form')), 0, 100000, '${vault.derivationPath}/0/0');
  final tx = Transaction.forSinglePayment(
    [utxo],
    vault.getAddress(1),
    '${vault.derivationPath}/1/0',
    10000,
    2,
    vault,
    lockTime: path == _Path.script ? policy.locktime : 0,
    policy: path == _Path.script ? policy : null,
  );
  return Psbt.fromTransaction(tx, vault).serialize();
}

String _withWalletIdentifier(String psbtBase64, String walletDescriptor) {
  final psbt = Psbt.parse(psbtBase64);
  (psbt.psbtMap['global'] as Map)['fc07636f636f6e757401'] = Codec.encodeHex(Hash.sha256(walletDescriptor));
  return psbt.serialize();
}

TaprootVaultListItem _createVaultItem(int id, TaprootVault vault) {
  return TaprootVaultListItem(
    id: id,
    name: 'inheritance $id',
    colorIndex: 0,
    iconIndex: 0,
    descriptor: vault.descriptor,
    keyPathSeedInfos: const [],
    scriptPathSeedInfos: const [],
    createdAt: DateTime(2026),
  );
}

class _FakeWalletProvider extends Fake implements WalletProvider {
  _FakeWalletProvider(this._vaultList);

  final List<VaultListItemBase> _vaultList;

  @override
  bool get isVaultsLoaded => true;

  @override
  List<VaultListItemBase> get vaultList => _vaultList;

  @override
  VaultListItemBase getVaultById(int id) => _vaultList.firstWhere((vault) => vault.id == id);
}
