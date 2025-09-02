import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';

class WalletIsolates {
  static Future<List<SingleSigVaultListItem>> addVault(Map<String, dynamic> data) async {
    List<SingleSigVaultListItem> vaultList = [];

    var wallet = SingleSigWalletCreateDto.fromJson(data);
    final keyStore = KeyStore.fromSeed(
        Seed.fromMnemonic(wallet.mnemonic!, passphrase: wallet.passphrase ?? ''),
        AddressType.p2wpkh);
    final derivationPath = NetworkType.currentNetworkType.isTestnet ? "84'/1'/0'" : "84'/0'/0'";
    final descriptor = Descriptor.forSingleSignature(AddressType.p2wpkh,
        keyStore.extendedPublicKey.serialize(), derivationPath, keyStore.masterFingerprint);
    final signerBsms =
        SingleSignatureVault.fromKeyStore(keyStore).getSignerBsms(AddressType.p2wsh, wallet.name!);
    SingleSigVaultListItem newItem = SingleSigVaultListItem(
      id: wallet.id!,
      name: wallet.name!,
      colorIndex: wallet.color!,
      iconIndex: wallet.icon!,
      descriptor: descriptor.serialize(),
      signerBsms: signerBsms,
      createdAt: DateTime.now(),
    );

    vaultList.insert(0, newItem);

    return vaultList;
  }

  static Future<MultisigVaultListItem> addMultisigVault(Map<String, dynamic> data) async {
    var walletData = MultisigWallet.fromJson(data);
    var newMultisigVault = MultisigVaultListItem(
      id: walletData.id!,
      name: walletData.name!,
      colorIndex: walletData.color!,
      iconIndex: walletData.icon!,
      signers: walletData.signers!,
      requiredSignatureCount: walletData.requiredSignatureCount!,
      createdAt: DateTime.now(),
    );

    return newMultisigVault;
  }

  static Future<VaultListItemBase> initializeWallet(Map<String, dynamic> data) async {
    String? vaultType = data[VaultListItemBase.vaultTypeField];

    // coconut_vault 1.0.1 -> 2.0.0 업데이트 되면서 vaultType이 추가됨
    if (vaultType == null || vaultType == WalletType.singleSignature.name) {
      return SingleSigVaultListItem.fromJson(data);
    } else if (vaultType == WalletType.multiSignature.name) {
      return MultisigVaultListItem.fromJson(data);
    } else {
      throw ArgumentError('[initializeWallet] vaultType: $vaultType');
    }
  }

  static Future<MultisignatureVault> fromKeyStores(Map<String, dynamic> data) async {
    List<KeyStore> keyStores = [];
    List<dynamic> decodedKeyStoresJson = jsonDecode(data['keyStores']);
    final int requiredSignatureCount = data['requiredSignatureCount'];

    for (var keyStore in decodedKeyStoresJson) {
      keyStores.add(KeyStore.fromJson(keyStore));
    }

    MultisignatureVault multiSignatureVault = MultisignatureVault.fromKeyStoreList(
        keyStores, requiredSignatureCount,
        addressType: AddressType.p2wsh);

    return multiSignatureVault;
  }

  static Future<List<String>> extractSignerBsms(List<SingleSigVaultListItem> vaultList) async {
    List<String> bsmses = [];

    for (int i = 0; i < vaultList.length; i++) {
      bsmses.add(vaultList[i].signerBsms);
    }

    return bsmses;
  }

  static Future<Map<String, dynamic>> verifyPassphrase(Map<String, dynamic> args) async {
    // 암호화 관련 처리를 사용하여 CPU 동기연산이 발생하므로 isolate로 처리
    final mnemonic = args['mnemonic'] as String;
    final passphrase = args['passphrase'] as String;
    final vaultListItem = args['valutListItem'] as VaultListItemBase;
    assert(vaultListItem.vaultType == WalletType.singleSignature);

    final singleSigVaultListItem = vaultListItem.coconutVault as SingleSignatureVault;
    final keyStore = KeyStore.fromSeed(
      Seed.fromMnemonic(mnemonic, passphrase: passphrase),
      AddressType.p2wpkh,
    );

    final savedMfp = singleSigVaultListItem.keyStore.masterFingerprint;
    final recoveredMfp = keyStore.masterFingerprint;
    final extendedPublicKey = singleSigVaultListItem.keyStore.extendedPublicKey.serialize();
    final success = savedMfp == recoveredMfp;
    return {
      "success": success,
      "savedMfp": savedMfp,
      "recoveredMfp": recoveredMfp,
      "extendedPublicKey": extendedPublicKey
    };
  }
}
