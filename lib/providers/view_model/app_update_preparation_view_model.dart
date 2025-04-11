import 'dart:math';

import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:flutter/material.dart';

class VaultMnemonicItem {
  final String vaultName;
  final String mnemonicWord;
  final int mnemonicWordIndex;

  const VaultMnemonicItem({
    required this.vaultName,
    required this.mnemonicWord,
    required this.mnemonicWordIndex,
  });
}

class AppUpdatePreparationViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  final List<VaultMnemonicItem> _vaultMnemonicItems = [];
  final _random = Random();
  bool _isMnemonicLoaded = false;
  bool _isMnemonicFinished = false;
  int _currentMnemonicIndex = 0;

  WalletProvider get walletProvider => _walletProvider;
  List<VaultMnemonicItem> get vaultMnemonicItems => _vaultMnemonicItems;
  bool get isMnemonicLoaded => _isMnemonicLoaded;
  bool get isMnemonicFinished => _isMnemonicFinished;
  int get currentMnemonicIndex => _currentMnemonicIndex;

  AppUpdatePreparationViewModel(this._walletProvider) {
    _initialize();
  }

  Future<void> _initialize() async {
    List<VaultListItemBase> filteredList =
        _walletProvider.getVaultsByWalletType(WalletType.singleSignature);
    if (filteredList.isEmpty) {
      _isMnemonicLoaded = true;
      _isMnemonicFinished = true;
      notifyListeners();
    }

    for (int i = 0; i < filteredList.length; i++) {
      _vaultMnemonicItems.add(await _getMnemonicItemFromVault(filteredList[i]));
      if (_vaultMnemonicItems.length == filteredList.length) {
        _isMnemonicLoaded = true;
        notifyListeners();
      }
    }
  }

  Future<VaultMnemonicItem> _getMnemonicItemFromVault(
      VaultListItemBase vault) async {
    return await _walletProvider.getSecret(vault.id).then((secret) {
      List<String> mnemonicList = secret.mnemonic.split(' ');
      int mnemonicIndex = _random.nextInt(mnemonicList.length);
      return VaultMnemonicItem(
          vaultName: vault.name,
          mnemonicWord: hashString(mnemonicList[mnemonicIndex]),
          mnemonicWordIndex: mnemonicIndex);
    });
  }

  void proceedNextMnemonic() {
    if (_isMnemonicFinished) return;
    ++_currentMnemonicIndex;
    if (_currentMnemonicIndex == _vaultMnemonicItems.length) {
      _currentMnemonicIndex = _vaultMnemonicItems.length - 1;
      _isMnemonicFinished = true;
    }

    notifyListeners();
  }
}
