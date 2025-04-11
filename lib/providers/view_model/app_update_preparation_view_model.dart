import 'dart:math';

import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:flutter/material.dart';

class MnemonicWordItem {
  final String vaultName;
  final String mnemonicWord;
  final int mnemonicWordIndex;

  const MnemonicWordItem({
    required this.vaultName,
    required this.mnemonicWord,
    required this.mnemonicWordIndex,
  });
}

class AppUpdatePreparationViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  final List<MnemonicWordItem> _mnemonicWordItems = [];
  final _random = Random();
  bool _isMnemonicLoaded = false;
  bool _isMnemonicValidationFinished = false;
  int _currentMnemonicIndex = 0;

  WalletProvider get walletProvider => _walletProvider;
  List<MnemonicWordItem> get mnemonicWordItems => _mnemonicWordItems;
  bool get isMnemonicLoaded => _isMnemonicLoaded;
  bool get isMnemonicValidationFinished => _isMnemonicValidationFinished;
  int get currentMnemonicIndex => _currentMnemonicIndex;

  AppUpdatePreparationViewModel(this._walletProvider) {
    _initialize();
  }

  Future<void> _initialize() async {
    List<VaultListItemBase> filteredList =
        _walletProvider.getVaultsByWalletType(WalletType.singleSignature);
    if (filteredList.isEmpty) {
      _isMnemonicLoaded = true;
      _isMnemonicValidationFinished = true;
      notifyListeners();
    }

    for (int i = 0; i < filteredList.length; i++) {
      _mnemonicWordItems
          .add(await _getMnemonicWordItemFromVault(filteredList[i]));
      if (_mnemonicWordItems.length == filteredList.length) {
        _isMnemonicLoaded = true;
        notifyListeners();
      }
    }
  }

  Future<MnemonicWordItem> _getMnemonicWordItemFromVault(
      VaultListItemBase vault) async {
    return await _walletProvider.getSecret(vault.id).then((secret) {
      List<String> mnemonicList = secret.mnemonic.split(' ');
      int mnemonicIndex = _random.nextInt(mnemonicList.length);
      return MnemonicWordItem(
          vaultName: vault.name,
          mnemonicWord: hashString(mnemonicList[mnemonicIndex]),
          mnemonicWordIndex: mnemonicIndex);
    });
  }

  void proceedNextMnemonic() {
    if (_isMnemonicValidationFinished) return;
    ++_currentMnemonicIndex;
    if (_currentMnemonicIndex == _mnemonicWordItems.length) {
      _currentMnemonicIndex = _mnemonicWordItems.length - 1;
      _isMnemonicValidationFinished = true;
    }

    notifyListeners();
  }
}
