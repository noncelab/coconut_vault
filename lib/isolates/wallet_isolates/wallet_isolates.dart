import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/taproot/taproot_inheritance_isolates.dart';
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
import 'package:coconut_vault/model/taproot/stored_taproot_seed_info.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';

typedef TaprootCreationResult = ({
  TaprootVaultListItem vault,
  List<TaprootSeedInfoForSave> keyPathSaves,
  List<TaprootSeedInfoForSave> scriptPathSaves,
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

  static (StoredTaprootSeedInfo, KeyStore) createSeedInfo(SeedSource seed) {
    final keystore = KeyStore.fromSeed(Seed.fromMnemonic(seed.mnemonic, passphrase: seed.passphrase), AddressType.p2tr);
    return (
      StoredTaprootSeedInfo(
        extendedPublicKey: keystore.extendedPublicKey.serialize(),
        isPassphraseSet: seed.passphrase.isNotEmpty,
      ),
      keystore,
    );
  }

  /// seed.wipe() 이후에도 살아남도록 사본을 들고 save 모델 구성.
  static TaprootSeedInfoForSave createSeedInfoForSave(SeedSource seed, String extendedPublicKey) {
    return TaprootSeedInfoForSave(
      secretPassphrasePair: (
        secret: Uint8List.fromList(seed.mnemonic),
        passphrase: seed.passphrase.isEmpty ? null : Uint8List.fromList(seed.passphrase),
      ),
      extendedPublicKey: extendedPublicKey,
    );
  }

  /// keyPath seed/signerBsms를 keyStore 목록과 seedInfo/save 모델로 변환한다.
  /// [seeds]가 있는 경우 내부에서 각 seed를 wipe하므로 호출 후에는 사용할 수 없다.
  static ({List<KeyStore> keyStores, List<StoredTaprootSeedInfo> seedInfos, List<TaprootSeedInfoForSave> saves})
      _buildKeyPathEntries(List<SeedSource>? seeds, List<String>? signerBsmses) {
    final keyStores = <KeyStore>[];
    final seedInfos = <StoredTaprootSeedInfo>[];
    final saves = <TaprootSeedInfoForSave>[];

    if (seeds != null) {
      for (final seed in seeds) {
        final (seedInfo, keyStore) = createSeedInfo(seed);
        seedInfos.add(seedInfo);
        saves.add(createSeedInfoForSave(seed, seedInfo.extendedPublicKey));
        final keyPathVault = TaprootVault.fromKeyStoreList([keyStore], []);

        /// seed가 제거된 keystore를 얻기 위해
        keyStores.add(KeyStore.fromSignerBsms(keyPathVault.getSignerBsms("")));

        keyStore.wipeSeed();
        seed.wipe();
      }
    }

    if (signerBsmses != null) {
      for (final signerBsms in signerBsmses) {
        keyStores.add(KeyStore.fromSignerBsms(signerBsms));
      }
    }

    return (keyStores: keyStores, seedInfos: seedInfos, saves: saves);
  }

  /// inheritance leaf 목록을 policy 목록과 scriptPath seedInfo/save 모델로 변환한다.
  /// secret을 보유한 leaf는 내부에서 wipe되므로 호출 후 해당 leaf의 secret은 사용할 수 없다.
  static ({List<Policy> policies, List<ScriptPathSeedInfo> seedInfos, List<TaprootSeedInfoForSave> saves})
      _buildScriptPathEntries(List<InheritanceLeaf>? inheritanceleaves) {
    final policies = <Policy>[];
    final seedInfos = <ScriptPathSeedInfo>[];
    final saves = <TaprootSeedInfoForSave>[];

    if (inheritanceleaves != null) {
      final result = TaprootInheritanceIsolates.buildScriptPathEntries(inheritanceleaves);
      policies.addAll(result.policies);
      seedInfos.addAll(result.seedInfos);
      saves.addAll(result.saves);
    }
    // 추후 다른 종류의 leaves가 생기면 여기서 동일하게 병합

    return (policies: policies, seedInfos: seedInfos, saves: saves);
  }

  static TaprootCreationResult createTaprootVault(Map<String, dynamic> data) {
    setNetworkType();

    final taprootCreateDto = TaprootWalletCreateDto.fromJson(data);
    try {
      final keyPath = _buildKeyPathEntries(taprootCreateDto.keyPathSeeds, taprootCreateDto.keyPathSignerBsmses);
      final scriptPath = _buildScriptPathEntries(taprootCreateDto.inheritanceLeaves);

      final taprootVault = TaprootVault.fromKeyStoreList(keyPath.keyStores, scriptPath.policies);

      final newTaprootVault = TaprootVaultListItem(
        id: taprootCreateDto.id!,
        name: taprootCreateDto.name!,
        colorIndex: taprootCreateDto.color!,
        iconIndex: taprootCreateDto.icon!,
        createdAt: DateTime.now(),
        descriptor: taprootVault.descriptor,
        keyPathSeedInfos: keyPath.seedInfos,
        scriptPathSeedInfos: scriptPath.seedInfos,
      );

      return (vault: newTaprootVault, keyPathSaves: keyPath.saves, scriptPathSaves: scriptPath.saves);
    } finally {
      taprootCreateDto.wipe();
    }
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

  static Future<Map<String, dynamic>> deriveTaprootImportSeed(Map<String, dynamic> args) async {
    setNetworkType();

    final Uint8List mnemonic = args['mnemonic'];
    final Uint8List? passphrase = args['passphrase'];
    final String descriptor = args['descriptor'];
    final String selectedRoleName = args['selectedRoleName'];

    KeyStore? keyStore;
    Seed? seed;

    try {
      seed = Seed.fromMnemonic(mnemonic, passphrase: passphrase);
      keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);

      final extendedPublicKey = keyStore.extendedPublicKey.serialize();
      final masterFingerprint = keyStore.masterFingerprint;
      final importedSingleKeyVault = TaprootVault.fromKeyStoreList([keyStore], []);
      final importedSingleKeyDescriptor = importedSingleKeyVault.descriptor;
      final importedSignerBsms = importedSingleKeyVault.getSignerBsms('');
      final scannedVault = TaprootVault.fromDescriptor(descriptor);

      final isSignerMatch = scannedVault.keyStoreList.any(
        (keyStore) => keyStore.extendedPublicKey.serialize() == extendedPublicKey,
      );
      final isBeneficiaryMatch = scannedVault.policyList.any((policy) {
        if (policy is! InheritancePolicy) {
          return false;
        }
        return policy.beneficiaryKeyStore.extendedPublicKey.serialize() == extendedPublicKey;
      });

      final isSelectedRoleMatch = switch (selectedRoleName) {
        'signer' => isSignerMatch,
        'beneficiary' => isBeneficiaryMatch,
        _ => false,
      };

      return {
        'extendedPublicKey': extendedPublicKey,
        'masterFingerprint': masterFingerprint,
        'isSelectedRoleMatch': isSelectedRoleMatch,
        'importedSingleKeyDescriptor': importedSingleKeyDescriptor,
        'importedSignerBsms': importedSignerBsms,
      };
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
