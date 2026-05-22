import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/utils/logger.dart';

class SignIsolates {
  static Future<String> addSignatureToPsbtWithSingleVault(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    WalletIsolates.setNetworkType();

    final seed = dataList[0] as Seed;
    final psbtBase64 = dataList[1] as String;
    final accountIndex = dataList.length > 2 ? dataList[2] as int : 0;
    final keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh, accountIndex: accountIndex);
    final coconutVault = SingleSignatureVault.fromKeyStore(keyStore, accountIndex: accountIndex);
    String signedPsbt = coconutVault.addSignatureToPsbt(psbtBase64);
    return signedPsbt;
  }

  static Future<String> addSignatureToPsbtWithMultisigVault(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    WalletIsolates.setNetworkType();

    final psbtBase64 = dataList[1] as String;
    final keyStore = KeyStore.fromSeed(dataList[0] as Seed, AddressType.p2wsh);
    String signedPsbt = keyStore.addSignatureToPsbt(psbtBase64, AddressType.p2wsh);
    return signedPsbt;
  }

  static Future<bool> canSignToPsbtWithSingleSignatureVault(List<dynamic> dataList) async {
    assert(dataList[0] is SingleSignatureVault);
    assert(dataList[1] is String);

    WalletIsolates.setNetworkType();
    final psbtBase64 = dataList[1] as String;
    return (dataList[0] as SingleSignatureVault).hasPublicKeyInPsbt(psbtBase64);
  }

  static Future<bool> canSignToPsbtWithMultisignatureVault(List<dynamic> dataList) async {
    assert(dataList[0] is MultisignatureVault);
    assert(dataList[1] is String);

    WalletIsolates.setNetworkType();
    final psbtBase64 = dataList[1] as String;
    final multisigWallet = dataList[0] as MultisignatureVault;

    bool allKeyStoreCanSign = true;
    for (KeyStore keyStore in multisigWallet.keyStoreList) {
      if (!keyStore.hasPublicKeyInPsbt(psbtBase64)) {
        allKeyStoreCanSign = false;
      }
    }

    if (!allKeyStoreCanSign) return false;

    // quorum 확인
    Psbt psbtObj = Psbt.parse(psbtBase64);
    Logger.log(
      '--> [canSignToPsbtWithMultisignatureVault] psbtR: ${psbtObj.inputs[0].requiredSignature} psbtT: ${psbtObj.inputs[0].derivationPathList.length}',
    );
    if (multisigWallet.requiredSignature != psbtObj.inputs[0].requiredSignature ||
        multisigWallet.keyStoreList.length != psbtObj.inputs[0].derivationPathList.length) {
      return false;
    }

    return true;
  }

  static Future<bool> canSignToPsbtWithTaprootVault(List<dynamic> dataList) async {
    assert(dataList[0] is TaprootVault);
    assert(dataList[1] is String);

    WalletIsolates.setNetworkType();
    final psbtBase64 = dataList[1] as String;
    try {
      final parsedPsbt = Psbt.parse(psbtBase64);
      final taprootVault = dataList[0] as TaprootVault;
      return parsedPsbt.isForVault(taprootVault);
    } catch (_) {
      return false;
    }
  }
}
