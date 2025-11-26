import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/wallet_address.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';

class WalletIsolates {
  static void setNetworkType() {
    const String? appFlavor =
        String.fromEnvironment('FLUTTER_APP_FLAVOR') != '' ? String.fromEnvironment('FLUTTER_APP_FLAVOR') : null;
    NetworkType.setNetworkType(appFlavor == "mainnet" ? NetworkType.mainnet : NetworkType.regtest);
  }

  static Future<List<SingleSigVaultListItem>> addVault(Map<String, dynamic> data) async {
    setNetworkType();

    List<SingleSigVaultListItem> vaultList = [];

    var wallet = SingleSigWalletCreateDto.fromJson(data);
    final keyStore = KeyStore.fromSeed(
      Seed.fromMnemonic(wallet.mnemonic!, passphrase: wallet.passphrase ?? Uint8List(0)),
      AddressType.p2wpkh,
    );
    final derivationPath = NetworkType.currentNetworkType.isTestnet ? "84'/1'/0'" : "84'/0'/0'";
    final descriptor = Descriptor.forSingleSignature(
      AddressType.p2wpkh,
      keyStore.extendedPublicKey.serialize(),
      derivationPath,
      keyStore.masterFingerprint,
    );
    final signerBsms = SingleSignatureVault.fromKeyStore(keyStore).getSignerBsms(AddressType.p2wsh, '');
    SingleSigVaultListItem newItem = SingleSigVaultListItem(
      id: wallet.id!,
      name: wallet.name!,
      colorIndex: wallet.color!,
      iconIndex: wallet.icon!,
      descriptor: descriptor.serialize(),
      signerBsmsByAddressType: {AddressType.p2wsh: signerBsms},
      createdAt: DateTime.now(),
    );

    vaultList.insert(0, newItem);

    wallet.wipe();
    return vaultList;
  }

  static Future<MultisigVaultListItem> addMultisigVault(Map<String, dynamic> data) async {
    setNetworkType();

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
    setNetworkType();

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
    setNetworkType();

    List<KeyStore> keyStores = [];
    List<dynamic> decodedKeyStoresJson = jsonDecode(data['keyStores']);
    final int requiredSignatureCount = data['requiredSignatureCount'];

    for (var keyStore in decodedKeyStoresJson) {
      keyStores.add(KeyStore.fromJson(keyStore));
    }

    MultisignatureVault multiSignatureVault = MultisignatureVault.fromKeyStoreList(
      keyStores,
      requiredSignatureCount,
      addressType: AddressType.p2wsh,
    );

    return multiSignatureVault;
  }

  static Future<Map<String, dynamic>> verifyPassphrase(Map<String, dynamic> args) async {
    setNetworkType();

    final vaultListItem = args['valutListItem'] as VaultListItemBase;
    assert(vaultListItem.vaultType == WalletType.singleSignature);

    final singleSigVaultListItem = vaultListItem.coconutVault as SingleSignatureVault;

    Seed? seed;
    KeyStore? keyStore;

    try {
      seed = Seed.fromMnemonic(args['mnemonic'], passphrase: args['passphrase']);
      keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh);

      final savedMfp = singleSigVaultListItem.keyStore.masterFingerprint;
      final recoveredMfp = keyStore.masterFingerprint;
      final extendedPublicKey = singleSigVaultListItem.keyStore.extendedPublicKey.serialize();
      final success = savedMfp == recoveredMfp;

      return {
        "success": success,
        "savedMfp": savedMfp,
        "recoveredMfp": recoveredMfp,
        "extendedPublicKey": extendedPublicKey,
      };
    } finally {
      if (keyStore != null) {
        keyStore.wipeSeed();
      }
      if (seed != null) {
        seed.wipe();
      }
      if (args['mnemonic'] != null) {
        (args['mnemonic'] as Uint8List).wipe();
      }
      if (args['passphrase'] != null) {
        (args['passphrase'] as Uint8List).wipe();
      }
    }
  }

  static Future<List<WalletAddress>> getAddressList(Map<String, dynamic> args) async {
    setNetworkType();

    final startIndex = args['startIndex'];
    final count = args['count'];
    final isChange = args['isChange'];
    final WalletBase wallet = args['walletBase'];

    List<WalletAddress> addressList = [];
    for (int i = startIndex; i < startIndex + count; i++) {
      String address = wallet.getAddress(i, isChange: isChange);
      String derivationPath = '${wallet.derivationPath}${isChange ? '/1' : '/0'}/$i';
      addressList.add(WalletAddress(address, derivationPath, i));
    }

    return addressList;
  }
}
