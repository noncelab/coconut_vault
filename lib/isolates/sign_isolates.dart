import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/logger.dart';

class SignIsolates {
  static Future<String> addSignatureToPsbt(
      List<dynamic> dataList, void Function(dynamic)? replyTo) async {
    String psbtBase64 = dataList[1] as String;
    String signedPsbt = dataList[0] is MultisignatureVault
        ? (dataList[0] as MultisignatureVault).addSignatureToPsbt(psbtBase64)
        : (dataList[0] as SingleSignatureVault).addSignatureToPsbt(psbtBase64);

    if (replyTo != null) {
      replyTo(signedPsbt);
    }
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
