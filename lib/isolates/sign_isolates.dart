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

  // Taproot
  static Future<String> signWithSingleKeyPath(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    WalletIsolates.setNetworkType();

    final psbtBase64 = dataList[1] as String;
    final taprootVault = TaprootVault.fromKeyStoreList([KeyStore.fromSeed(dataList[0] as Seed, AddressType.p2tr)], []);
    String signedPsbt = taprootVault.addSignatureToPsbt(psbtBase64);
    return signedPsbt;
  }

  // Taproot - Script Path (beneficiary)
  static Future<String> signWithBeneficiary(List<dynamic> dataList) async {
    assert(dataList[0] is Seed);
    assert(dataList[1] is String);
    assert(dataList[2] is String);
    WalletIsolates.setNetworkType();

    final psbtBase64 = dataList[1] as String;
    TaprootVault childVault = TaprootVault.fromCoordinatorBsms(dataList[2] as String);
    childVault.bindSeedToBeneficiaryKeyStore(dataList[0] as Seed);
    String signedPsbt = childVault.addSignatureToPsbt(psbtBase64);
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

    Psbt psbtObj = Psbt.parse(psbtBase64);
    Logger.log(
      '--> [canSignToPsbtWithMultisignatureVault] psbtR: ${psbtObj.inputs[0].requiredSignature} psbtT: ${psbtObj.inputs[0].derivationPathList.length}',
    );

    // INFO: 모든 input의 정책(threshold, 참여자 구성, witness script)이 이 vault와 정확히 일치하는지
    // 검증합니다. input 0만 확인할 경우, 서로 다른 정책의 input이 섞인 PSBT에서 로컬 공개키가
    // 우연히 포함된 다른 정책의 input에도 서명이 이루어질 수 있습니다(정책 우회).
    // 하나라도 일치하지 않으면 PSBT 전체를 거부합니다.
    for (int i = 0; i < psbtObj.inputs.length; i++) {
      if (!_isMultisigInputConsistentWithVault(multisigWallet, psbtObj.inputs[i])) {
        return false;
      }
    }

    return true;
  }

  /// 하나의 PSBT input이 [multisigWallet]에 등록된 정책과 정확히 일치하는지 검증합니다.
  /// - threshold(요구 서명 수)와 참여자 수(서명자 수)가 동일한지
  /// - 참여자의 masterFingerprint 집합이 정확히 일치하는지 (추가/누락 없이)
  /// - 로컬에 등록된 xpub들로 동일한 derivation path에서 witness script를 재구성했을 때
  ///   PSBT에 담긴 witness script와 바이트 단위로 동일한지
  static bool _isMultisigInputConsistentWithVault(MultisignatureVault multisigWallet, PsbtInput input) {
    if (input.witnessScript == null) {
      return false;
    }

    if (multisigWallet.requiredSignature != input.requiredSignature ||
        multisigWallet.keyStoreList.length != input.derivationPathList.length) {
      return false;
    }

    final walletFingerprintSet = multisigWallet.keyStoreList.map((e) => e.masterFingerprint.toUpperCase()).toSet();
    final inputFingerprintSet = input.derivationPathList.map((e) => e.masterFingerprint.toUpperCase()).toSet();
    if (walletFingerprintSet.length != inputFingerprintSet.length ||
        !walletFingerprintSet.containsAll(inputFingerprintSet)) {
      return false;
    }

    final expectedWitnessScript = multisigWallet.getWitnessScript(input.derivationPathList.first.path);
    if (expectedWitnessScript != input.witnessScript!.rawSerialize()) {
      return false;
    }

    return true;
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
      return parsedPsbt.isForVault(taprootVault);
    } catch (_) {
      return false;
    }
  }
}
