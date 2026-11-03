// QA generated host test (logic_coverage.autofill)
// Targets:
//  - PsbtScannerViewModel.preparePsbtForVault
//      added condition: _extractPsbtSignerFingerprints(parsedPsbt).contains(mfp)
//      intent (50065d91): "preparePsbtForVault의 NeedsMultisigSetupException 감지가
//      _extractPsbtSignerFingerprints 사용 (global xpub 없는 멀티시그 PSBT 대응)"
//  - PsbtScannerViewModel.getScanErrorMessage
//      intent (50065d91): WalletNotIdentifiableFromPsbtException(dead code) 제거. 남은 세 예외는
//      자신의 message, 그 외 오류는 t.errors.invalid_qr.
//
// Real classes: PsbtScannerViewModel, SignProvider, coconut_lib Psbt/Vault, SignIsolates via compute.
// Boundary fake: WalletProvider (vault storage/TEE), only the members the view model uses.
// Fixture helpers copied from test/providers/view_model/airgap/psbt_scanner_view_model_test.dart:243-370.
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/needs_multisig_setup_exception.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    NetworkType.setNetworkType(NetworkType.regtest);
  });

  group('PsbtScannerViewModel.preparePsbtForVault', () {
    test('global xpub이 없는 멀티시그 PSBT(BlueWallet)에 서명자로 포함된 싱글시그 지갑이면 NeedsMultisigSetupException', () async {
      final multisigVault = _createP2wshVault();
      final psbt = Psbt.parse(_createP2wshPsbt(multisigVault).serialize());
      _removeGlobalXpubs(psbt);
      final psbtBase64 = psbt.serialize();
      expect(Psbt.parse(psbtBase64).extendedPublicKeyList, isEmpty, reason: 'fixture must have no global xpub');

      final singleItem = _createSingleSigVaultListItem(
        id: 1,
        name: 'member single',
        vault: _createP2wpkhVault(passphrase: 'A'),
      );
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([singleItem]), signProvider);

      await expectLater(
        viewModel.preparePsbtForVault(1, psbtBase64, hasDerivationPath: true),
        throwsA(
          isA<NeedsMultisigSetupException>().having(
            (e) => e.message,
            'message',
            t.exceptions.needs_multisig_setup(name: 'member single'),
          ),
        ),
      );
      expect(signProvider.vaultListItem, isNull);
    });

    test('global xpub이 있는 멀티시그 PSBT에 서명자로 포함된 싱글시그 지갑이면 NeedsMultisigSetupException', () async {
      final multisigVault = _createP2wshVault();
      final psbtBase64 = _createP2wshPsbt(multisigVault).serialize();
      final singleItem = _createSingleSigVaultListItem(
        id: 2,
        name: 'member single',
        vault: _createP2wpkhVault(passphrase: 'B'),
      );
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([singleItem]), signProvider);

      await expectLater(
        viewModel.preparePsbtForVault(2, psbtBase64, hasDerivationPath: true),
        throwsA(isA<NeedsMultisigSetupException>()),
      );
      expect(signProvider.vaultListItem, isNull);
    });

    test('global xpub이 없는 멀티시그 PSBT에 서명자가 아닌 싱글시그 지갑이면 VaultSigningNotAllowedException', () async {
      final multisigVault = _createP2wshVault();
      final psbt = Psbt.parse(_createP2wshPsbt(multisigVault).serialize());
      _removeGlobalXpubs(psbt);
      final psbtBase64 = psbt.serialize();
      final singleItem = _createSingleSigVaultListItem(
        id: 3,
        name: 'stranger single',
        vault: _createP2wpkhVault(passphrase: 'not-a-member'),
      );
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([singleItem]), signProvider);

      await expectLater(
        viewModel.preparePsbtForVault(3, psbtBase64, hasDerivationPath: true),
        throwsA(isA<VaultSigningNotAllowedException>()),
      );
      expect(signProvider.vaultListItem, isNull);
    });

    test('서명 가능한 싱글시그 PSBT면 파싱된 PSBT를 돌려주고 SignProvider에 지갑을 설정한다', () async {
      final vault = _createP2wpkhVault(passphrase: 'owner');
      final psbtBase64 = _createP2wpkhPsbt(vault).serialize();
      final item = _createSingleSigVaultListItem(id: 4, name: 'owner', vault: vault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([item]), signProvider);

      final result = await viewModel.preparePsbtForVault(4, psbtBase64, hasDerivationPath: true);

      expect(result.serialize(), Psbt.parse(psbtBase64).serialize());
      expect(signProvider.vaultListItem, same(item));
    });

    test('derivation path가 없는 경우(Krux/SeedSigner)는 canSign 검사를 건너뛰고 지갑을 설정한다', () async {
      final psbtBase64 = _createP2wpkhPsbt(_createP2wpkhVault(passphrase: 'psbt-owner')).serialize();
      final item = _createSingleSigVaultListItem(
        id: 5,
        name: 'selected',
        vault: _createP2wpkhVault(passphrase: 'selected'),
      );
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([item]), signProvider);

      await viewModel.preparePsbtForVault(5, psbtBase64);

      expect(signProvider.vaultListItem, same(item));
    });

    test('지갑 목록이 로드되지 않았으면 먼저 loadVaultList를 호출한다', () async {
      final vault = _createP2wpkhVault(passphrase: 'owner');
      final psbtBase64 = _createP2wpkhPsbt(vault).serialize();
      final item = _createSingleSigVaultListItem(id: 6, name: 'owner', vault: vault);
      final walletProvider = _FakeWalletProvider([item], isLoaded: false);
      final viewModel = PsbtScannerViewModel(walletProvider, SignProvider());

      await viewModel.preparePsbtForVault(6, psbtBase64, hasDerivationPath: true);

      expect(walletProvider.loadVaultListCallCount, 1);
    });

    test('멀티시그 지갑 자신의 global xpub 없는 PSBT는 서명 대상으로 통과한다', () async {
      final multisigVault = _createP2wshVault();
      final psbt = Psbt.parse(_createP2wshPsbt(multisigVault).serialize());
      _removeGlobalXpubs(psbt);
      final item = _createMultisigVaultListItem(id: 7, name: 'ms', vault: multisigVault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([item]), signProvider);

      await viewModel.preparePsbtForVault(7, psbt.serialize(), hasDerivationPath: true);

      expect(signProvider.vaultListItem, same(item));
    });
  });

  group('PsbtScannerViewModel.getScanErrorMessage', () {
    late PsbtScannerViewModel viewModel;

    setUp(() {
      viewModel = PsbtScannerViewModel(_FakeWalletProvider(const []), SignProvider());
    });

    test('VaultNotFoundException은 자신의 message', () {
      expect(viewModel.getScanErrorMessage(VaultNotFoundException()), t.errors.vault_not_found_error);
      expect(viewModel.getScanErrorMessage(VaultNotFoundException(message: 'custom-nf')), 'custom-nf');
    });

    test('VaultSigningNotAllowedException은 자신의 message', () {
      expect(viewModel.getScanErrorMessage(VaultSigningNotAllowedException()), t.errors.cannot_sign_error);
      expect(viewModel.getScanErrorMessage(VaultSigningNotAllowedException(message: 'custom-sn')), 'custom-sn');
    });

    test('NeedsMultisigSetupException은 지갑 이름이 들어간 message', () {
      final e = NeedsMultisigSetupException(singleSigWalletName: 'my single');
      expect(viewModel.getScanErrorMessage(e), t.exceptions.needs_multisig_setup(name: 'my single'));
    });

    test('그 밖의 오류(파싱 실패 등)는 invalid_qr', () {
      expect(viewModel.getScanErrorMessage(const FormatException('bad')), t.errors.invalid_qr);
      expect(viewModel.getScanErrorMessage(Exception('x')), t.errors.invalid_qr);
      expect(viewModel.getScanErrorMessage('string error'), t.errors.invalid_qr);
    });
  });
}

// ---- fixtures (copied from test/providers/view_model/airgap/psbt_scanner_view_model_test.dart:243-370) ----

void _removeGlobalXpubs(Psbt psbt) {
  (psbt.psbtMap['global'] as Map).removeWhere((key, _) => (key as String).startsWith('01'));
}

SingleSignatureVault _createP2wpkhVault({required String passphrase}) {
  return SingleSignatureVault.fromMnemonic(
    utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
    passphrase: utf8.encode(passphrase),
  );
}

Psbt _createP2wpkhPsbt(SingleSignatureVault vault) {
  final utxo = Utxo(Codec.encodeHex(Hash.sha256('psbt-scanner-view-model-test')), 0, 100000, "m/84'/1'/0'/0/0");
  final tx = Transaction.forSinglePayment([utxo], vault.getAddress(1), '${vault.derivationPath}/1/1', 15000, 3, vault);
  return Psbt.fromTransaction(tx, vault);
}

MultisignatureVault _createP2wshVault({List<String> passphrases = const ['A', 'B', 'C']}) {
  final keyStores =
      passphrases.map((passphrase) {
        final vault = _createP2wpkhVault(passphrase: passphrase);
        return KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2wsh);
      }).toList();
  return MultisignatureVault.fromKeyStoreList(keyStores, 2);
}

Psbt _createP2wshPsbt(MultisignatureVault vault) {
  final utxos = [
    Utxo(Codec.encodeHex(Hash.sha256('psbt-scanner-view-model-test-multisig-0')), 0, 100000, "m/48'/1'/0'/2'/0/0"),
    Utxo(Codec.encodeHex(Hash.sha256('psbt-scanner-view-model-test-multisig-1')), 0, 110000, "m/48'/1'/0'/2'/0/1"),
  ];
  final tx = Transaction.forSinglePayment(utxos, vault.getAddress(1), '${vault.derivationPath}/1/1', 15000, 3, vault);
  return Psbt.fromTransaction(tx, vault);
}

SingleSigVaultListItem _createSingleSigVaultListItem({
  required int id,
  required String name,
  required SingleSignatureVault vault,
}) {
  return SingleSigVaultListItem(
    id: id,
    name: name,
    colorIndex: 0,
    iconIndex: 0,
    descriptor: vault.descriptor,
    signerBsmsByAddressType: {AddressType.p2wpkh: ''},
    createdAt: DateTime(2026),
  );
}

MultisigVaultListItem _createMultisigVaultListItem({
  required int id,
  required String name,
  required MultisignatureVault vault,
}) {
  return MultisigVaultListItem(
    id: id,
    name: name,
    colorIndex: 0,
    iconIndex: 0,
    signers:
        vault.keyStoreList.indexed
            .map((entry) => MultisigSigner(id: entry.$1, name: 'signer ${entry.$1}', keyStore: entry.$2))
            .toList(),
    requiredSignatureCount: 2,
    createdAt: DateTime(2026),
  );
}

class _FakeWalletProvider implements WalletProvider {
  _FakeWalletProvider(this._vaultList, {bool isLoaded = true}) : _isLoaded = isLoaded;

  final List<VaultListItemBase> _vaultList;
  bool _isLoaded;
  int loadVaultListCallCount = 0;

  @override
  bool get isVaultsLoaded => _isLoaded;

  @override
  List<VaultListItemBase> get vaultList => _vaultList;

  @override
  VaultListItemBase getVaultById(int id) => _vaultList.firstWhere((vault) => vault.id == id);

  @override
  Future<void> loadVaultList() async {
    loadVaultListCallCount++;
    _isLoaded = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
