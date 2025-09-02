import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';

class SignIsolates {
  static Future<String> addSignatureToPsbtWithSingleVault(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    final keyStore = KeyStore.fromSeed(dataList[0] as Seed, AddressType.p2wpkh);
    final psbtBase64 = dataList[1] as String;
    final coconutVault = SingleSignatureVault.fromKeyStore(keyStore);
    String signedPsbt = coconutVault.addSignatureToPsbt(psbtBase64);
    return signedPsbt;
  }

  static Future<String> addSignatureToPsbtWithMultisigVault(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    final psbtBase64 = dataList[1] as String;
    final keyStore = KeyStore.fromSeed(dataList[0] as Seed, AddressType.p2wsh);
    String signedPsbt = keyStore.addSignatureToPsbt(psbtBase64, AddressType.p2wsh);
    return signedPsbt;
  }

  static Future<bool> canSignToPsbt(List<dynamic> dataList, void Function(dynamic)? replyTo) async {
    String psbtBase64 = dataList[1] as String;
    var isMultisig = dataList[0] is MultisignatureVault;

    bool canSign = isMultisig
        ? (dataList[0] as MultisignatureVault).hasPublicKeyInPsbt(psbtBase64)
        : (dataList[0] as SingleSignatureVault).hasPublicKeyInPsbt(psbtBase64);

    if (!isMultisig || !canSign) return canSign;

    // quorum 확인
    Psbt psbtObj = Psbt.parse(psbtBase64);
    var multisigWallet = dataList[0] as MultisignatureVault;
    Logger.log(
        '--> psbtR: ${psbtObj.inputs[0].requiredSignature} psbtT: ${psbtObj.inputs[0].derivationPathList.length}');
    if (multisigWallet.requiredSignature != psbtObj.inputs[0].requiredSignature ||
        multisigWallet.keyStoreList.length != psbtObj.inputs[0].derivationPathList.length) {
      return false;
    }

    if (replyTo != null) {
      replyTo(canSign);
    }
    return canSign;
  }
}
