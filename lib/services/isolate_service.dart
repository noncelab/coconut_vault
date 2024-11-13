import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/vault_list_item.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';

Future<List<VaultListItem>> addVaultIsolate(
    Map<String, dynamic> data, void Function(dynamic)? progressCallback) async {
  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);
  await SharedPrefsService().init();
  List<VaultListItem> vaultList = [];

  final params = data;
  String inputText = params['inputText'];
  int selectedIconIndex = params['selectedIconIndex'];
  int selectedColorIndex = params['selectedColorIndex'];
  String importingSecret = params['importingSecret'];
  String importingPassphrase = params['importingPassphrase'];
  VaultListItem newItem = await VaultListItem.create(
    name: inputText,
    colorIndex: selectedColorIndex,
    iconIndex: selectedIconIndex,
    secret: importingSecret,
    passphrase: importingPassphrase,
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
