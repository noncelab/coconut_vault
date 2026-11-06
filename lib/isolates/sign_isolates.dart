import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';

class SignIsolates {
  static Future<String> addSignatureToPsbtWithSingleVault(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    WalletIsolates.setNetworkType();

    final seed = dataList[0] as Seed;
    final psbtBase64 = dataList[1] as String;
    final accountIndex = dataList.length > 2 ? dataList[2] as int : 0;
    KeyStore? keyStore;
    try {
      keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh, accountIndex: accountIndex);
      final coconutVault = SingleSignatureVault.fromKeyStore(keyStore, accountIndex: accountIndex);
      return coconutVault.addSignatureToPsbt(psbtBase64);
    } finally {
      keyStore?.wipeSeed();
      seed.wipe();
    }
  }

  static Future<String> addSignatureToPsbtWithMultisigVault(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    WalletIsolates.setNetworkType();

    final psbtBase64 = dataList[1] as String;
    final seed = dataList[0] as Seed;
    KeyStore? keyStore;
    try {
      keyStore = KeyStore.fromSeed(seed, AddressType.p2wsh);
      return keyStore.addSignatureToPsbt(psbtBase64, AddressType.p2wsh);
    } finally {
      keyStore?.wipeSeed();
      seed.wipe();
    }
  }

  // Taproot
  static Future<String> signWithSingleKeyPath(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    assert(dataList[2] is String);
    WalletIsolates.setNetworkType();

    final psbtBase64 = dataList[1] as String;
    final seed = dataList[0] as Seed;
    final String coordinatorBsms = dataList[2] as String;
    TaprootVault? taprootVault;

    try {
      taprootVault = TaprootVault.fromCoordinatorBsms(coordinatorBsms);
      taprootVault.bindSeedToKeyStore(seed);
      return taprootVault.addSignatureToPsbt(psbtBase64);
    } finally {
      taprootVault?.keyStoreList.forEach((keyStore) => keyStore.wipeSeed());
      seed.wipe();
    }
  }

  // Taproot - Script Path (beneficiary)
  static Future<String> signWithBeneficiary(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    assert(dataList[2] is String);
    WalletIsolates.setNetworkType();

    final psbtBase64 = dataList[1] as String;
    final seed = dataList[0] as Seed;
    TaprootVault? childVault;

    try {
      childVault = TaprootVault.fromCoordinatorBsms(dataList[2] as String);
      childVault.bindSeedToBeneficiaryKeyStore(seed);
      return childVault.addSignatureToPsbt(psbtBase64);
    } finally {
      childVault?.keyStoreList.forEach((keyStore) => keyStore.wipeSeed());
      seed.wipe();
    }
  }

  static Future<bool> canSignToPsbtWithSingleSignatureVault(List<dynamic> dataList) async {
    assert(dataList[0] is SingleSignatureVault);
    assert(dataList[1] is String);

    WalletIsolates.setNetworkType();
    final psbtBase64 = dataList[1] as String;
    try {
      return Psbt.parse(psbtBase64).matchesVault(dataList[0] as SingleSignatureVault);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canSignToPsbtWithMultisignatureVault(List<dynamic> dataList) async {
    assert(dataList[0] is MultisignatureVault);
    assert(dataList[1] is String);

    WalletIsolates.setNetworkType();
    final psbtBase64 = dataList[1] as String;
    try {
      return Psbt.parse(psbtBase64).matchesVault(dataList[0] as MultisignatureVault);
    } catch (_) {
      return false;
    }
  }

  /// INFO: keyPath, scriptPath 서명 가능 여부는 여기서 판단 안하고 TaprootSignScreen에서 확인 후 안내
  static Future<bool> canSignToPsbtWithTaprootVault(List<dynamic> dataList) async {
    assert(dataList[0] is TaprootVault);
    assert(dataList[1] is String);

    WalletIsolates.setNetworkType();
    final psbtBase64 = dataList[1] as String;
    try {
      final parsedPsbt = Psbt.parse(psbtBase64);
      final taprootVault = dataList[0] as TaprootVault;
      return parsedPsbt.matchesVault(taprootVault);
    } catch (_) {
      return false;
    }
  }
}
