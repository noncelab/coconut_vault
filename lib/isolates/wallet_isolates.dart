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
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_info.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';

typedef TaprootCreationResult =
    ({
      TaprootVaultListItem vault,
      List<TaprootSeedInfoForSave> keyPathSaves,
      List<ScriptPathSeedInfoForSave> scriptPathSaves,
    });

class WalletIsolates {
  static void setNetworkType() {
    const String? appFlavor =
        String.fromEnvironment('FLUTTER_APP_FLAVOR') != '' ? String.fromEnvironment('FLUTTER_APP_FLAVOR') : null;
    NetworkType.setNetworkType(appFlavor == "mainnet" ? NetworkType.mainnet : NetworkType.regtest);
  }

  static List<SingleSigVaultListItem> createSingleSigVault(Map<String, dynamic> data) {
    setNetworkType();

    List<SingleSigVaultListItem> vaultList = [];

    var wallet = SingleSigWalletCreateDto.fromJson(data);
    final keyStore = KeyStore.fromSeed(
      Seed.fromMnemonic(wallet.mnemonic!, passphrase: wallet.passphrase ?? Uint8List(0)),
      AddressType.p2wpkh,
    );
    final derivationPath = NetworkType.currentNetworkType.isTestnet ? "84'/1'/0'" : "84'/0'/0'";
    final descriptor = Descriptor.forSingleSignature(AddressType.p2wpkh, keyStore, derivationPath);
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
    // TODO: keyStore.wipe(); 누락인지 확인
    return vaultList;
  }

  static MultisigVaultListItem createMultisigVault(Map<String, dynamic> data) {
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

  static (TaprootSeedInfo, KeyStore) _createSeedInfo(SeedSource seed) {
    final keystore = KeyStore.fromSeed(Seed.fromMnemonic(seed.mnemonic, passphrase: seed.passphrase), AddressType.p2tr);
    return (
      TaprootSeedInfo(
        extendedPublicKey: keystore.extendedPublicKey.serialize(),
        isPassphraseSet: seed.passphrase.isNotEmpty,
      ),
      keystore,
    );
  }

  static TaprootCreationResult createTaprootVault(Map<String, dynamic> data) {
    setNetworkType();

    final wallet = TaprootWalletCreateDto.fromJson(data);
    final keyStoreList = <KeyStore>[];
    final keyPathSeedInfos = <TaprootSeedInfo>[];
    final keyPathSaves = <TaprootSeedInfoForSave>[];
    if (wallet.keyPathSeeds != null) {
      for (final seed in wallet.keyPathSeeds!) {
        final (seedInfo, keyStore) = _createSeedInfo(seed);
        keyPathSeedInfos.add(seedInfo);
        // seed.wipe() 이후에도 살아남도록 사본을 들고 save 모델 구성.
        keyPathSaves.add(
          TaprootSeedInfoForSave(
            secretPassphrasePair: (
              secret: Uint8List.fromList(seed.mnemonic),
              passphrase: seed.passphrase.isEmpty ? null : Uint8List.fromList(seed.passphrase),
            ),
            extendedPublicKey: seedInfo.extendedPublicKey,
          ),
        );
        final taprootVault = TaprootVault.fromKeyStoreList([keyStore], []);

        /// seed가 제거된 keystore를 얻기 위해
        keyStoreList.add(KeyStore.fromSignerBsms(taprootVault.getSignerBsms("")));

        keyStore.wipeSeed();
        seed.wipe();
      }
    }

    if (wallet.keyPathSignerBsmses != null) {
      for (final signerBsms in wallet.keyPathSignerBsmses!) {
        keyStoreList.add(KeyStore.fromSignerBsms(signerBsms));
      }
    }

    final policyList = <Policy>[];
    final scriptPathSeedInfos = <ScriptPathSeedInfo>[];
    final scriptPathSaves = <ScriptPathSeedInfoForSave>[];
    if (wallet.inheritanceLeaves != null) {
      for (final leaf in wallet.inheritanceLeaves!) {
        if (leaf.descriptor != null) {
          policyList.add(InheritancePolicy.fromDescriptorAndLocktime(leaf.descriptor!, leaf.lockTime));
        } else {
          final secret = leaf.secret!;
          final (seedInfo, keyStore) = _createSeedInfo(secret);
          final taprootVault = TaprootVault.fromKeyStoreList([keyStore], []);
          final inheritancePolicy = InheritancePolicy.fromDescriptorAndLocktime(taprootVault.descriptor, leaf.lockTime);
          policyList.add(inheritancePolicy);
          Logger.log('--> inheritance policy miniscript: ${inheritancePolicy.toMiniscript()}');
          final scriptKey = hashString(inheritancePolicy.toMiniscript());
          scriptPathSeedInfos.add(
            ScriptPathSeedInfo(key: scriptKey, role: ScriptPathRole.beneficiary, seedInfos: [seedInfo]),
          );
          // miniscript hash(=scriptKey)와 seed를 같은 분기 안에서 페어링하여 save 모델 구성.
          scriptPathSaves.add(
            ScriptPathSeedInfoForSave(
              key: scriptKey,
              role: ScriptPathRole.beneficiary,
              seedInfos: [
                TaprootSeedInfoForSave(
                  secretPassphrasePair: (
                    secret: Uint8List.fromList(secret.mnemonic),
                    passphrase: secret.passphrase.isEmpty ? null : Uint8List.fromList(secret.passphrase),
                  ),
                  extendedPublicKey: seedInfo.extendedPublicKey,
                ),
              ],
            ),
          );
          // seed 정보 정리
          keyStore.wipeSeed();
          secret.wipe();
        }
      }
    }

    final taprootVault = TaprootVault.fromKeyStoreList(keyStoreList, policyList);

    final newTaprootVault = TaprootVaultListItem(
      id: wallet.id!,
      name: wallet.name!,
      colorIndex: wallet.color!,
      iconIndex: wallet.icon!,
      createdAt: DateTime.now(),
      descriptor: taprootVault.descriptor,
      keyPathSeedInfos: keyPathSeedInfos,
      scriptPathSeedInfos: scriptPathSeedInfos,
    );

    wallet.wipe();
    return (vault: newTaprootVault, keyPathSaves: keyPathSaves, scriptPathSaves: scriptPathSaves);
  }

  static Future<VaultListItemBase> initializeWallet(Map<String, dynamic> data) async {
    setNetworkType();

    String? vaultType = data[VaultListItemBase.vaultTypeField];

    // coconut_vault 1.0.1 -> 2.0.0 업데이트 되면서 vaultType이 추가됨
    if (vaultType == null || vaultType == WalletType.singleSignature.name) {
      return SingleSigVaultListItem.fromJson(data);
    } else if (vaultType == WalletType.multiSignature.name) {
      return MultisigVaultListItem.fromJson(data);
    } else if (vaultType == WalletType.taproot.name) {
      return TaprootVaultListItem.fromJson(data);
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

  /// 니모닉으로부터 KeyStore를 생성하고 masterFingerprint를 반환
  static Future<Map<String, dynamic>> verifyMnemonicMfp(Map<String, dynamic> args) async {
    setNetworkType();

    final Uint8List mnemonic = args['mnemonic'];
    final Uint8List? passphrase = args['passphrase'];
    final String expectedMfp = args['expectedMfp'];
    final String addressTypeName = args['addressTypeName'];
    final AddressType addressType = AddressType.getAddressTypeFromName(addressTypeName);

    KeyStore? keyStore;
    Seed? seed;

    try {
      seed = Seed.fromMnemonic(mnemonic, passphrase: passphrase);
      keyStore = KeyStore.fromSeed(seed, addressType);

      final expectedMfpToUpper = expectedMfp.toUpperCase();
      final actualMfpToUpper = keyStore.masterFingerprint.toUpperCase();
      final success = expectedMfpToUpper == actualMfpToUpper;

      return {"success": success, "actualMfp": actualMfpToUpper};
    } finally {
      if (keyStore != null) {
        keyStore.wipeSeed();
      }
      if (seed != null) {
        seed.wipe();
      }
      mnemonic.wipe();
      if (passphrase != null) {
        passphrase.wipe();
      }
    }
  }

  static Future<Map<String, dynamic>> deriveNewAccountVault(Map<String, dynamic> args) async {
    setNetworkType();

    final Uint8List mnemonic = args['mnemonic'];
    final Uint8List? passphrase = args['passphrase'];
    final String addressTypeName = args['addressTypeName'];
    final int currentAccountIndex = args['currentAccountIndex'];
    final int newAccountIndex = args['newAccountIndex'];
    final String expectedMfp = args['expectedMfp'];

    final AddressType addressType = AddressType.getAddressTypeFromName(addressTypeName);

    try {
      final derivedVault = SingleSignatureVault.fromMnemonic(
        mnemonic,
        addressType: addressType,
        passphrase: passphrase,
        accountIndex: currentAccountIndex,
      );

      if (derivedVault.keyStore.masterFingerprint.toUpperCase() != expectedMfp.toUpperCase()) {
        throw Exception('Invalid passphrase');
      }

      final updatedCoconutVault = SingleSignatureVault.fromMnemonic(
        mnemonic,
        addressType: addressType,
        passphrase: passphrase,
        accountIndex: newAccountIndex,
      );

      return {'descriptor': updatedCoconutVault.descriptor, 'derivationPath': updatedCoconutVault.derivationPath};
    } finally {
      mnemonic.wipe();
      if (passphrase != null) {
        passphrase.wipe();
      }
    }
  }
}
