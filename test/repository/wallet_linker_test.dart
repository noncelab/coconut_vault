import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/repository/wallet_linker.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _mnemonic(String words) => Uint8List.fromList(utf8.encode(words));

SingleSigVaultListItem _makeSingleSig({required int id, required String mnemonic}) {
  final keyStoreP2wpkh = KeyStore.fromMnemonic(_mnemonic(mnemonic), AddressType.p2wpkh);

  final derivationPath = NetworkType.currentNetworkType.isTestnet ? "84'/1'/0'" : "84'/0'/0'";
  final descriptor = Descriptor.forSingleSignature(AddressType.p2wpkh, keyStoreP2wpkh, derivationPath);

  final singleSignatureVault = SingleSignatureVault.fromKeyStore(keyStoreP2wpkh, accountIndex: 0);
  final signerBsmsP2wsh = singleSignatureVault.getSignerBsms(AddressType.p2wsh, '');

  return SingleSigVaultListItem(
    id: id,
    name: 'single-$id',
    colorIndex: 0,
    iconIndex: 0,
    descriptor: descriptor.serialize(),
    signerBsmsByAddressType: {AddressType.p2wsh: signerBsmsP2wsh},
    createdAt: DateTime.now(),
  );
}

KeyStore _p2wshKeyStore(String mnemonic, {int accountIndex = 0}) {
  return KeyStore.fromMnemonic(_mnemonic(mnemonic), AddressType.p2wsh, accountIndex: accountIndex);
}

MultisigVaultListItem _makeMultisigVault({
  required int id,
  required List<KeyStore> keyStores,
  required List<String> signerBsmsList,
  required int required,
}) {
  final signers = <MultisigSigner>[];
  for (int i = 0; i < keyStores.length; i++) {
    signers.add(MultisigSigner(id: i, name: 'signer-$i', keyStore: keyStores[i], signerBsms: signerBsmsList[i]));
  }

  return MultisigVaultListItem(
    id: id,
    name: 'multisig-$id',
    colorIndex: 0,
    iconIndex: 0,
    signers: signers,
    requiredSignatureCount: required,
    createdAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    NetworkType.setNetworkType(NetworkType.mainnet);
  });

  group('WalletLinker.isSinglesigKeyMatch', () {
    test('signer BSMS path로 호출하면 MFP+derivation path+xpub이 일치해야 true', () {
      final single = _makeSingleSig(id: 1, mnemonic: _testMnemonic);
      final p2wshKeyStore = _p2wshKeyStore(_testMnemonic);

      final bsms = Bsms.parseSigner(single.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false));

      expect(WalletLinker.isSinglesigKeyMatch(single, p2wshKeyStore, bsms.signer!.path), isTrue);
    });

    test('Descriptor.getDerivationPath의 m/ prefix가 있어도 정규화되어 매칭', () {
      final single = _makeSingleSig(id: 1, mnemonic: _testMnemonic);
      final p2wshKeyStore = _p2wshKeyStore(_testMnemonic);

      final multisigVault = MultisignatureVault.fromKeyStoreList([p2wshKeyStore], 1, addressType: AddressType.p2wsh);
      final parsedDescriptor = Descriptor.parse(multisigVault.descriptor);
      final pathFromDescriptor = parsedDescriptor.getDerivationPath(0);

      // importMultisig가 이 path 형식(m/...)으로 isSinglesigKeyMatch를 호출
      expect(WalletLinker.isSinglesigKeyMatch(single, p2wshKeyStore, pathFromDescriptor), isTrue);
    });

    test('derivation path가 다르면 false', () {
      final single = _makeSingleSig(id: 1, mnemonic: _testMnemonic);
      final p2wshKeyStoreAccount1 = _p2wshKeyStore(_testMnemonic, accountIndex: 1);
      final wrongPath = WalletUtility.getDerivationPath(AddressType.p2wsh, 1).replaceAll('m/', '');

      expect(WalletLinker.isSinglesigKeyMatch(single, p2wshKeyStoreAccount1, wrongPath), isFalse);
    });

    test('xpub/MFP가 다르면 false', () {
      final single = _makeSingleSig(id: 1, mnemonic: _testMnemonic);
      // 같은 path에 다른 xpub/MFP
      final wrongKeyStore = KeyStore.fromExtendedPublicKey(
        'zpub6rYqhgYyyvypyGmx5NomXL5DJobtWTrer9yKXQo5SP7X4jw6rYCbqmfgyBNiuFvrhAwUasmLE4jzd6DPosbSYL2z5bk4tSorCZ7bsFp6HPx',
        '92DBF650',
      );
      final path = WalletUtility.getDerivationPath(AddressType.p2wsh, 0).replaceAll('m/', '');

      expect(WalletLinker.isSinglesigKeyMatch(single, wrongKeyStore, path), isFalse);
    });
  });

  group('WalletLinker.linkNewSinglesigWallet', () {
    test('singlesig 추가 시 일치하는 signer에 양방향 링크', () {
      final single = _makeSingleSig(id: 1, mnemonic: _testMnemonic);
      final p2wshKeyStore = _p2wshKeyStore(_testMnemonic);
      final singleSigVault = SingleSignatureVault.fromKeyStore(
        KeyStore.fromMnemonic(_mnemonic(_testMnemonic), AddressType.p2wpkh),
      );
      final bsms = singleSigVault.getSignerBsms(AddressType.p2wsh, '');

      final multisig = _makeMultisigVault(id: 2, keyStores: [p2wshKeyStore], signerBsmsList: [bsms], required: 1);

      final linker = WalletLinker([multisig, single]);
      linker.linkNewSinglesigWallet(single);

      expect(multisig.signers[0].innerVaultId, 1);
      expect(single.linkedMultisigInfo, {2: 0});
    });

    test('같은 singlesig가 여러 multisig의 signer로 등록되면 모두 링크', () {
      final single = _makeSingleSig(id: 1, mnemonic: _testMnemonic);
      final p2wshKeyStore = _p2wshKeyStore(_testMnemonic);
      final singleSigVault = SingleSignatureVault.fromKeyStore(
        KeyStore.fromMnemonic(_mnemonic(_testMnemonic), AddressType.p2wpkh),
      );
      final bsms = singleSigVault.getSignerBsms(AddressType.p2wsh, '');

      final multisig1 = _makeMultisigVault(id: 2, keyStores: [p2wshKeyStore], signerBsmsList: [bsms], required: 1);
      final multisig2 = _makeMultisigVault(id: 3, keyStores: [p2wshKeyStore], signerBsmsList: [bsms], required: 1);

      final linker = WalletLinker([multisig1, multisig2, single]);
      linker.linkNewSinglesigWallet(single);

      expect(single.linkedMultisigInfo, {2: 0, 3: 0});
    });
  });
}

const _testMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
