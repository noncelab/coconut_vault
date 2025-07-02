import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';

Future<List<SingleSigVaultListItem>> addVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? progressCallback) async {
  List<SingleSigVaultListItem> vaultList = [];

  var wallet = SinglesigWallet.fromJson(data);
  SingleSigVaultListItem newItem = SingleSigVaultListItem(
      id: wallet.id!,
      name: wallet.name!,
      colorIndex: wallet.color!,
      iconIndex: wallet.icon!,
      secret: wallet.mnemonic!,
      passphrase: wallet.passphrase!);

  vaultList.insert(0, newItem);

  return vaultList;
}

Future<MultisigVaultListItem> addMultisigVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? replyTo) async {
  await SharedPrefsRepository().init();

  var walletData = MultisigWallet.fromJson(data);
  var newMultisigVault = MultisigVaultListItem(
    id: walletData.id!,
    name: walletData.name!,
    colorIndex: walletData.color!,
    iconIndex: walletData.icon!,
    signers: walletData.signers!,
    requiredSignatureCount: walletData.requiredSignatureCount!,
    addressType: walletData.addressType,
  );

  if (replyTo != null) {
    replyTo(newMultisigVault);
  }
  return newMultisigVault;
}

Future<String> addSignatureToPsbtIsolate(
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

Future<bool> canSignToPsbtIsolate(List<dynamic> dataList, void Function(dynamic)? replyTo) async {
  //TODO: 여기 확인
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

Future<List<String>> extractSignerBsmsIsolate(
    List<dynamic> vaultList, void Function(dynamic)? replyTo) async {
  List<String> bsmses = [];

  for (int i = 0; i < vaultList.length; i++) {
    SingleSigVaultListItem vaultListItem = vaultList[i] as SingleSigVaultListItem;
    if (vaultListItem.signerBsms != null) {
      bsmses.add(vaultListItem.signerBsms!);
    }
  }

  if (replyTo != null) {
    replyTo(bsmses);
  }
  return bsmses;
}

Future<MultisignatureVault> fromKeyStoreIsolate(
    Map<String, dynamic> data, void Function(dynamic)? replyTo) async {
  List<KeyStore> keyStores = [];
  List<dynamic> decodedKeyStoresJson = jsonDecode(data['keyStores']);
  final int requiredSignatureCount = data['requiredSignatureCount'];
  final String addressType = data['addressType'];

  for (var keyStore in decodedKeyStoresJson) {
    keyStores.add(KeyStore.fromJson(keyStore));
  }

  MultisignatureVault multiSignatureVault = MultisignatureVault.fromKeyStoreList(
      keyStores, requiredSignatureCount,
      addressType: AddressType.getAddressTypeFromName(addressType));

  if (replyTo != null) {
    replyTo(multiSignatureVault);
  }
  return multiSignatureVault;
}

Future<VaultListItemBase> initializeWallet(
    Map<String, dynamic> data, void Function(dynamic)? setVaultListLoadingProgress) async {
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
