import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/needs_multisig_setup_exception.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PsbtScannerViewModel.setMatchingVault', () {
    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
    });

    test('PSBT의 master fingerprint와 일치하는 단일 서명 vault를 SignProvider에 설정한다', () async {
      final vault = _createP2wpkhVault(passphrase: 'match');
      final psbtBase64 = _createP2wpkhPsbt(vault).serialize();
      final vaultItem = _createSingleSigVaultListItem(id: 1, name: 'matching vault', vault: vault);
      final signProvider = SignProvider();
      final walletProvider = _FakeWalletProvider([vaultItem]);
      final viewModel = PsbtScannerViewModel(walletProvider, signProvider);

      await viewModel.setMatchingVault(psbtBase64);

      expect(signProvider.vaultListItem, same(vaultItem));
      expect(walletProvider.loadVaultListCallCount, 0);
    });

    test('일치하는 단일 서명 vault가 없으면 VaultNotFoundException을 던진다', () async {
      final psbtVault = _createP2wpkhVault(passphrase: 'psbt');
      final otherVault = _createP2wpkhVault(passphrase: 'other');
      final psbtBase64 = _createP2wpkhPsbt(psbtVault).serialize();
      final otherVaultItem = _createSingleSigVaultListItem(id: 2, name: 'other vault', vault: otherVault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([otherVaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(psbtBase64), throwsA(isA<VaultNotFoundException>()));
      expect(signProvider.vaultListItem, isNull);
    });

    test('PSBT의 signer set과 일치하는 멀티시그 vault를 SignProvider에 설정한다', () async {
      final vault = _createP2wshVault();
      final psbtBase64 = _createP2wshPsbt(vault).serialize();
      final vaultItem = _createMultisigVaultListItem(id: 3, name: 'matching multisig vault', vault: vault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);

      await viewModel.setMatchingVault(psbtBase64);

      expect(signProvider.vaultListItem, same(vaultItem));
    });

    test('멀티시그 PSBT와 일치하는 vault가 없으면 VaultNotFoundException을 던진다', () async {
      final psbtVault = _createP2wshVault();
      final otherVault = _createP2wshVault(passphrases: ['D', 'E', 'F']);
      final psbtBase64 = _createP2wshPsbt(psbtVault).serialize();
      final otherVaultItem = _createMultisigVaultListItem(id: 4, name: 'other multisig vault', vault: otherVault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([otherVaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(psbtBase64), throwsA(isA<VaultNotFoundException>()));
      expect(signProvider.vaultListItem, isNull);
    });

    test('멀티시그 PSBT 구성원인 단일 서명 vault만 있으면 NeedsMultisigSetupException을 던진다', () async {
      final multisigVault = _createP2wshVault();
      final singleSigVault = _createP2wpkhVault(passphrase: 'A');
      final psbtBase64 = _createP2wshPsbt(multisigVault).serialize();
      final singleSigVaultItem = _createSingleSigVaultListItem(
        id: 5,
        name: 'single signer vault',
        vault: singleSigVault,
      );
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([singleSigVaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(psbtBase64), throwsA(isA<NeedsMultisigSetupException>()));
      expect(signProvider.vaultListItem, isNull);
    });

    test('PSBT와 일치하는 탭루트 vault를 SignProvider에 설정한다', () async {
      final vault = _createP2trVault(passphrases: ['taproot']);
      final psbtBase64 = _createP2trPsbt(vault).serialize();
      final vaultItem = _createTaprootVaultListItem(id: 6, name: 'matching taproot vault', vault: vault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);

      await viewModel.setMatchingVault(psbtBase64);

      expect(signProvider.vaultListItem, same(vaultItem));
    });

    test('탭루트 PSBT와 일치하는 vault가 없으면 VaultNotFoundException을 던진다', () async {
      final psbtVault = _createP2trVault(passphrases: ['taproot-psbt']);
      final otherVault = _createP2trVault(passphrases: ['taproot-other']);
      final psbtBase64 = _createP2trPsbt(psbtVault).serialize();
      final otherVaultItem = _createTaprootVaultListItem(id: 7, name: 'other taproot vault', vault: otherVault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([otherVaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(psbtBase64), throwsA(isA<VaultNotFoundException>()));
      expect(signProvider.vaultListItem, isNull);
    });

    test('input 0은 vault 정책과 일치하지만 다른 input이 다른 정책이면 매칭되지 않는다 (mixed-policy PSBT 우회 방지)', () async {
      final vaultA = _createP2wshVault(passphrases: ['A', 'B', 'C']);
      // vaultA의 첫 번째 서명자(A)의 public key를 공유하지만, 서로 다른 참여자/threshold(1-of-2)를
      // 가진 별개의 정책. 공격 시나리오: input 0은 정상 vaultA 정책, 이후 input은 다른 정책이지만
      // 로컬 공개키(A)를 포함하는 mixed-policy PSBT.
      final vaultB = MultisignatureVault.fromKeyStoreList([
        vaultA.keyStoreList[0],
        KeyStore.fromSeed(_createP2wpkhVault(passphrase: 'D').keyStore.seed, AddressType.p2wsh),
      ], 1);

      final psbtA = Psbt.parse(_createP2wshPsbt(vaultA).serialize());
      final psbtB = Psbt.parse(_createP2wshPsbt(vaultB).serialize());
      // input 1을 다른 정책(vaultB)의 input 데이터로 치환한다.
      psbtA.psbtMap['inputs'][1] = psbtB.psbtMap['inputs'][1];
      final mixedPolicyPsbtBase64 = psbtA.serialize();

      final vaultItem = _createMultisigVaultListItem(id: 10, name: 'mixed policy target vault', vault: vaultA);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(mixedPolicyPsbtBase64), throwsA(isA<VaultNotFoundException>()));
      expect(signProvider.vaultListItem, isNull);
    });

    test('구성원(공개키)은 동일하지만 threshold가 다른 input이 섞여 있으면 매칭되지 않는다 (mixed-threshold PSBT 우회 방지)', () async {
      final vaultA = _createP2wshVault(passphrases: ['A', 'B', 'C']);
      // vaultA와 서명자 구성(공개키)은 완전히 동일하지만 threshold만 다른(3-of-3) 정책.
      // 공격 시나리오: input 0은 정상 vaultA(2-of-3) 정책, 이후 input은 동일한 서명자들로
      // 구성되었지만 threshold가 다른(3-of-3) input이 섞인 mixed-threshold PSBT.
      final vaultB = MultisignatureVault.fromKeyStoreList(vaultA.keyStoreList, 3);

      final psbtA = Psbt.parse(_createP2wshPsbt(vaultA).serialize());
      final psbtB = Psbt.parse(_createP2wshPsbt(vaultB).serialize());
      // input 1을 동일 서명자, 다른 threshold(3-of-3) 정책의 input 데이터로 치환한다.
      psbtA.psbtMap['inputs'][1] = psbtB.psbtMap['inputs'][1];
      final mixedThresholdPsbtBase64 = psbtA.serialize();

      final vaultItem = _createMultisigVaultListItem(id: 11, name: 'mixed threshold target vault', vault: vaultA);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(mixedThresholdPsbtBase64), throwsA(isA<VaultNotFoundException>()));
      expect(signProvider.vaultListItem, isNull);
    });

    test('일치하는 멀티시그 vault가 서명할 수 없으면 VaultNotFoundException을 던진다', () async {
      final vault = _createP2wshVault();
      final psbtBase64 = _createP2wshPsbt(vault).serialize();
      final vaultItem = _CannotSignMultisigVaultListItem(id: 8, name: 'cannot sign multisig vault', vault: vault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(psbtBase64), throwsA(isA<VaultNotFoundException>()));
      expect(signProvider.vaultListItem, isNull);
    });

    test('일치하는 단일 서명 vault가 서명할 수 없으면 VaultSigningNotAllowedException을 던진다', () async {
      final vault = _createP2wpkhVault(passphrase: 'cannot-sign');
      final psbtBase64 = _createP2wpkhPsbt(vault).serialize();
      final vaultItem = _CannotSignSingleSigVaultListItem(id: 9, name: 'cannot sign single sig vault', vault: vault);
      final signProvider = SignProvider();
      final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);

      expect(() => viewModel.setMatchingVault(psbtBase64), throwsA(isA<VaultSigningNotAllowedException>()));
      expect(signProvider.vaultListItem, isNull);
    });
  });
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

TaprootVault _createP2trVault({List<String> passphrases = const ['taproot-A', 'taproot-B']}) {
  final keyStores =
      passphrases.map((passphrase) {
        final vault = _createP2wpkhVault(passphrase: passphrase);
        return KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2tr);
      }).toList();
  return TaprootVault.fromKeyStoreList(keyStores, []);
}

Psbt _createP2trPsbt(TaprootVault vault) {
  final utxo = Utxo(Codec.encodeHex(Hash.sha256('psbt-scanner-view-model-test-taproot')), 0, 100000, "m/86'/1'/0'/0/0");
  final tx = Transaction.forSinglePayment([utxo], vault.getAddress(1), '${vault.derivationPath}/1/0', 15000, 3, vault);
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
    signers: _createMultisigSigners(vault),
    requiredSignatureCount: 2,
    createdAt: DateTime(2026),
  );
}

TaprootVaultListItem _createTaprootVaultListItem({required int id, required String name, required TaprootVault vault}) {
  return TaprootVaultListItem(
    id: id,
    name: name,
    colorIndex: 0,
    iconIndex: 0,
    descriptor: vault.descriptor,
    keyPathSeedInfos: const [],
    scriptPathSeedInfos: const [],
    createdAt: DateTime(2026),
  );
}

List<MultisigSigner> _createMultisigSigners(MultisignatureVault vault) {
  return vault.keyStoreList.indexed.map((entry) {
    return MultisigSigner(id: entry.$1, name: 'signer ${entry.$1}', keyStore: entry.$2);
  }).toList();
}

class _CannotSignMultisigVaultListItem extends MultisigVaultListItem {
  _CannotSignMultisigVaultListItem({required int id, required String name, required MultisignatureVault vault})
    : super(
        id: id,
        name: name,
        colorIndex: 0,
        iconIndex: 0,
        signers: _createMultisigSigners(vault),
        requiredSignatureCount: 2,
        createdAt: DateTime(2026),
      );

  @override
  Future<bool> canSign(String psbt) async => false;
}

class _CannotSignSingleSigVaultListItem extends SingleSigVaultListItem {
  _CannotSignSingleSigVaultListItem({required int id, required String name, required SingleSignatureVault vault})
    : super(
        id: id,
        name: name,
        colorIndex: 0,
        iconIndex: 0,
        descriptor: vault.descriptor,
        signerBsmsByAddressType: {AddressType.p2wpkh: ''},
        createdAt: DateTime(2026),
      );

  @override
  Future<bool> canSign(String psbt) async => false;
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
