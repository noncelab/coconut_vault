import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item_factory.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item_factory.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';

Future<List<SinglesigVaultListItem>> addVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? progressCallback) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  List<SinglesigVaultListItem> vaultList = [];

  final params = data;
  int nextId = params['nextId'];
  String inputText = params['inputText'];
  int selectedIconIndex = params['selectedIconIndex'];
  int selectedColorIndex = params['selectedColorIndex'];
  String importingSecret = params['importingSecret'];
  String importingPassphrase = params['importingPassphrase'];

  final factory = SinglesigVaultListItemFactory();
  final secrets = {
    SinglesigVaultListItemFactory.secretField: importingSecret,
    SinglesigVaultListItemFactory.passphraseField: importingPassphrase,
  };

  SinglesigVaultListItem newItem = await factory.create(
    nextId: nextId,
    name: inputText,
    colorIndex: selectedColorIndex,
    iconIndex: selectedIconIndex,
    secrets: secrets,
  );
  vaultList.add(newItem);
  return vaultList;
}

Future<MultisigVaultListItem> addMultisigVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  await SharedPrefsService().init();

  int nextId = data['nextId'];
  String name = data['name'];
  int colorIndex = data['colorIndex'];
  int iconIndex = data['iconIndex'];
  final Map<String, dynamic> secrets = data['secrets'];
  List<MultisigSigner> signers = [];
  List<dynamic> decodedSignersJson = jsonDecode(secrets['signers']);
  int requiredSignatureCount = secrets['requiredSignatureCount'];

  for (var signer in decodedSignersJson) {
    signers.add(MultisigSigner.fromJson(signer));
  }

  var newMultisigVault = await MultisigVaultListItemFactory().create(
      nextId: nextId,
      name: name,
      colorIndex: colorIndex,
      iconIndex: iconIndex,
      secrets: {
        'signers': signers,
        'requiredSignatureCount': requiredSignatureCount,
      });

  if (replyTo != null) {
    replyTo(newMultisigVault);
  }
  return newMultisigVault;
}

Future<String> addSignatureToPsbtIsolate(
    List<dynamic> dataList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  String psbtBase64 = dataList[1] as String;
  String signedPsbt = dataList[0] is MultisignatureVault
      ? (dataList[0] as MultisignatureVault).addSignatureToPsbt(psbtBase64)
      : (dataList[0] as SingleSignatureVault).addSignatureToPsbt(psbtBase64);


  if (replyTo != null) {
    replyTo(signedPsbt);
  }
  return signedPsbt;
}

Future<bool> canSignToPsbtIsolate(
    List<dynamic> dataList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  String psbtBase64 = dataList[1] as String;
  bool canSign = dataList[0] is MultisignatureVault
      ? (dataList[0] as MultisignatureVault).canSignToPsbt(psbtBase64)
      : (dataList[0] as SingleSignatureVault).canSignToPsbt(psbtBase64);

  if (replyTo != null) {
    replyTo(canSign);
  }
  return canSign;
}

Future<List<String>> extractSignerBsmsIsolate(
    List<dynamic> vaultList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  List<String> bsmses = [];

  for (int i = 0; i < vaultList.length; i++) {
    SinglesigVaultListItem vaultListItem =
        vaultList[i] as SinglesigVaultListItem;
    bsmses.add((vaultListItem.coconutVault as SingleSignatureVault)
        .getSignerBsms(AddressType.p2wsh, vaultListItem.name));
  }

  if (replyTo != null) {
    replyTo(bsmses);
  }
  return bsmses;
}

Future<int> getSignerIndexIsolate(
    Map<String, dynamic> data, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  MultisignatureVault multiSignatureVault =
      MultisignatureVault.fromJson(data['multisigVault']);
  SinglesigVaultListItem singlesigVaultListItem =
      SinglesigVaultListItem.fromJson(data['singlesigVault']);

  int signerIndex = MultisigUtils.getSignerIndexUsedInMultisig(
      multiSignatureVault, singlesigVaultListItem);

  if (replyTo != null) {
    replyTo(signerIndex);
  }
  return signerIndex;
}

Future<MultisigVaultListItem> importMultisigVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  final int nextId = data['nextId'];
  final String name = data['name'];
  final int colorIndex = data['colorIndex'];
  final int iconIndex = data['iconIndex'];
  final Map<String, String> namesMap = data['namesMap'];
  final Map<String, dynamic> secrets = data['secrets'];
  List<VaultListItemBase> vaultList = [];
  List<dynamic> decodedVaultListJson = jsonDecode(secrets['vaultList']);

  for (var vaultJson in decodedVaultListJson) {
    if (vaultJson['vaultType'] == VaultType.multiSignature.name) {
      vaultList.add(MultisigVaultListItem.fromJson(vaultJson));
    } else if (vaultJson['vaultType'] == VaultType.singleSignature.name) {
      vaultList.add(SinglesigVaultListItem.fromJson(vaultJson));
    }
  }

  MultisigVaultListItem newMultisigVault = await MultisigVaultListItemFactory()
      .createFromBsms(
          nextId: nextId,
          name: name,
          colorIndex: colorIndex,
          iconIndex: iconIndex,
          namesMap: namesMap,
          secrets: {
        "bsms": secrets['bsms'],
        "vaultList": vaultList,
      });

  if (replyTo != null) {
    replyTo(newMultisigVault);
  }
  return newMultisigVault;
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

  MultisignatureVault multiSignatureVault =
      MultisignatureVault.fromKeyStoreList(
          keyStores, requiredSignatureCount, AddressType.p2wsh);

  if (replyTo != null) {
    replyTo(multiSignatureVault);
  }
  return multiSignatureVault;
}
