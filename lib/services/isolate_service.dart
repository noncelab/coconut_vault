import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item_factory.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';

Future<List<SinglesigVaultListItem>> addVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? progressCallback) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  await SharedPrefsService().init();
  List<SinglesigVaultListItem> vaultList = [];

  final params = data;
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
    name: inputText,
    colorIndex: selectedColorIndex,
    iconIndex: selectedIconIndex,
    secrets: secrets,
  );
  vaultList.add(newItem);
  return vaultList;
}

Future<String> addSignatureToPsbtIsolate(
    List<dynamic> dataList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  SingleSignatureVault vault = dataList[0] as SingleSignatureVault;
  String psbtBase64 = dataList[1] as String;
  String signedPsbt = vault.addSignatureToPsbt(psbtBase64);

  if (replyTo != null) {
    replyTo(signedPsbt);
  }
  return signedPsbt;
}

Future<bool> canSignToPsbtIsolate(
    List<dynamic> dataList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  SingleSignatureVault vault = dataList[0] as SingleSignatureVault;
  String psbtBase64 = dataList[1] as String;
  bool canSign = vault.canSignToPsbt(psbtBase64);

  if (replyTo != null) {
    replyTo(canSign);
  }
  return canSign;
}

Future<List<String>> extractBsmsIsolate(
    List<dynamic> vaultList, void Function(dynamic)? replyTo) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  List<String> pubStringList = List<String>.filled(vaultList.length, '');

  for (int i = 0; i < vaultList.length; i++) {
    VaultListItem vaultListItem = vaultList[i] as VaultListItem;
    pubStringList[i] = vaultListItem.coconutVault
        .getSignerBsms(AddressType.p2wsh, vaultListItem.name);
  }

  if (replyTo != null) {
    replyTo(pubStringList);
  }
  return pubStringList;
}
