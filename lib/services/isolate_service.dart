import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/model/manager/multisig_wallet.dart';
import 'package:coconut_vault/model/manager/singlesig_wallet.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';

Future<List<SinglesigVaultListItem>> addVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? progressCallback) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  List<SinglesigVaultListItem> vaultList = [];

  var wallet = SinglesigWallet.fromJson(data);
  SinglesigVaultListItem newItem = SinglesigVaultListItem(
      id: wallet.id!,
      name: wallet.name!,
      colorIndex: wallet.color!,
      iconIndex: wallet.icon!,
      secret: wallet.mnemonic!,
      passphrase: wallet.passphrase!);

  vaultList.add(newItem);

  return vaultList;
}

Future<MultisigVaultListItem> addMultisigVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  await SharedPrefsService().init();

  var walletData = MultisigWallet.fromJson(data);
  var newMultisigVault = MultisigVaultListItem(
    id: walletData.id!,
    name: walletData.name!,
    colorIndex: walletData.color!,
    iconIndex: walletData.icon!,
    signers: walletData.signers!,
    requiredSignatureCount: walletData.requiredSignatureCount!,
  );

  if (replyTo != null) {
    replyTo(newMultisigVault);
  }
  return newMultisigVault;
}

Future<String> addSignatureToPsbtIsolate(
    List<dynamic> dataList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  if (dataList[0] is MultisignatureVault) {
    final vault = dataList[0] as MultisignatureVault;
    String psbtBase64 = dataList[1] as String;
    String signedPsbt = vault.addSignatureToPsbt(psbtBase64);

    if (replyTo != null) {
      replyTo(signedPsbt);
    }
    return signedPsbt;
  } else {
    final vault = dataList[0] as SingleSignatureVault;
    String psbtBase64 = dataList[1] as String;
    String signedPsbt = vault.addSignatureToPsbt(psbtBase64);

    if (replyTo != null) {
      replyTo(signedPsbt);
    }
    return signedPsbt;
  }
}

Future<bool> canSignToPsbtIsolate(
    List<dynamic> dataList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  if (dataList[0] is MultisignatureVault) {
    final vault = dataList[0] as MultisignatureVault;
    String psbtBase64 = dataList[1] as String;
    bool canSign = vault.canSignToPsbt(psbtBase64);

    if (replyTo != null) {
      replyTo(canSign);
    }
    return canSign;
  } else {
    final vault = dataList[0] as SingleSignatureVault;
    String psbtBase64 = dataList[1] as String;
    bool canSign = vault.canSignToPsbt(psbtBase64);

    if (replyTo != null) {
      replyTo(canSign);
    }
    return canSign;
  }
}

Future<List<String>> extractSignerBsmsIsolate(
    List<dynamic> vaultList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  List<String> bsmses = [];

  for (int i = 0; i < vaultList.length; i++) {
    SinglesigVaultListItem vaultListItem =
        vaultList[i] as SinglesigVaultListItem;
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
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  List<KeyStore> keyStores = [];
  List<dynamic> decodedKeyStoresJson = jsonDecode(data['keyStores']);
  final int requiredSignatureCount = data['requiredSignatureCount'];

  for (var keyStore in decodedKeyStoresJson) {
    keyStores.add(KeyStore.fromJson(keyStore));
  }

  MultisignatureVault multisignatureVault =
      MultisignatureVault.fromKeyStoreList(
          keyStores, requiredSignatureCount, AddressType.p2wsh);

  if (replyTo != null) {
    replyTo(multisignatureVault);
  }
  return multisignatureVault;
}

Future<VaultListItemBase> initializeWallet(Map<String, dynamic> data,
    void Function(dynamic)? setVaultListLoadingProgress) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  String? vaultType = data[VaultListItemBase.vaultTypeField];

  // coconut_vault 1.0.1 -> 2.0.0 업데이트 되면서 vaultType이 추가됨
  if (vaultType == null || vaultType == VaultType.singleSignature.name) {
    return SinglesigVaultListItem.fromJson(data);
  } else if (vaultType == VaultType.multiSignature.name) {
    return MultisigVaultListItem.fromJson(data);
  } else {
    throw ArgumentError('[initializeWallet] vaultType: $vaultType');
  }
}
