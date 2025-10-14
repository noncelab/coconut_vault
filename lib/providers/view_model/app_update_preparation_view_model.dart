import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/app_version_util.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/material.dart';

class MnemonicWordsItem {
  final String vaultName;
  final String mnemonicWords;
  final int mnemonicWordLength;
  final int mnemonicWordIndex;

  const MnemonicWordsItem({
    required this.vaultName,
    required this.mnemonicWords,
    required this.mnemonicWordLength,
    required this.mnemonicWordIndex,
  });
}

class AppUpdatePreparationViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  final List<MnemonicWordsItem> _mnemonicWordsItems = [];
  final _random = Random();
  bool _isMnemonicLoaded = false;
  bool _isMnemonicValidationFinished = false;
  int _currentMnemonicIndex = 0;

  WalletProvider get walletProvider => _walletProvider;
  bool get isMnemonicLoaded => _isMnemonicLoaded;
  bool get isMnemonicValidationFinished => _isMnemonicValidationFinished;
  String get walletName => _mnemonicWordsItems[_currentMnemonicIndex].vaultName;
  int get mnemonicWordLength => _mnemonicWordsItems[_currentMnemonicIndex].mnemonicWordLength;
  int get mnemonicWordIndex => _mnemonicWordsItems[_currentMnemonicIndex].mnemonicWordIndex + 1;
  int get backupProgress => _backupProgress;

  int _backupProgress = 0;
  Completer<void>? _progress40Reached;
  Completer<void>? _progress80Reached;

  AppUpdatePreparationViewModel(this._walletProvider) {
    _walletProvider.isVaultListLoadingNotifier.addListener(_loadVaultCompletedListener);
    _initialize();
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_loadVaultCompletedListener);
    super.dispose();
  }

  void _loadVaultCompletedListener() {
    if (!_walletProvider.isVaultListLoading) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    // 모든 볼트가 로드될 때까지 대기
    if (_walletProvider.isVaultListLoadingNotifier.value) return;

    List<VaultListItemBase> filteredList = _walletProvider.getVaultsByWalletType(WalletType.singleSignature);
    if (filteredList.isEmpty) {
      _isMnemonicLoaded = true;
      _isMnemonicValidationFinished = true;
      notifyListeners();
      return;
    }

    for (int i = 0; i < filteredList.length; i++) {
      _mnemonicWordsItems.add(await _getMnemonicWordsFromVault(filteredList[i]));
      if (_mnemonicWordsItems.length == filteredList.length) {
        _isMnemonicLoaded = true;
        notifyListeners();
      }
    }
  }

  Future<MnemonicWordsItem> _getMnemonicWordsFromVault(VaultListItemBase vault) async {
    return await _walletProvider.getSecret(vault.id).then((mnemonic) {
      List<String> mnemonicList = utf8.decode(mnemonic).split(' ');
      int mnemonicIndex = _random.nextInt(mnemonicList.length);
      Logger.log('-->${vault.name} mnemonicList: $mnemonicList, mnemonicIndex: $mnemonicIndex');
      return MnemonicWordsItem(
        vaultName: vault.name,
        mnemonicWords: hashString(mnemonicList[mnemonicIndex]),
        mnemonicWordLength: mnemonicList[mnemonicIndex].length,
        mnemonicWordIndex: mnemonicIndex,
      );
    });
  }

  bool isWordMatched(String userInput) {
    final success = hashString(userInput.toLowerCase()) == _mnemonicWordsItems[_currentMnemonicIndex].mnemonicWords;
    if (!success) {
      return false;
    }

    _proceedNextMnemonic();
    return true;
  }

  void _proceedNextMnemonic() {
    if (_isMnemonicValidationFinished) return;
    ++_currentMnemonicIndex;
    if (_currentMnemonicIndex == _mnemonicWordsItems.length) {
      _currentMnemonicIndex = _mnemonicWordsItems.length - 1;
      _isMnemonicValidationFinished = true;
    }

    notifyListeners();
  }

  void setProgressReached(int value) {
    if (value == 40 && _progress40Reached != null && !_progress40Reached!.isCompleted) {
      _progress40Reached!.complete();
    } else if (value == 80 && _progress80Reached != null && !_progress80Reached!.isCompleted) {
      _progress80Reached!.complete();
    }
  }

  void createBackupData() async {
    _progress40Reached = Completer<void>();
    final result = await _walletProvider.createBackupData();

    _backupProgress = 40;
    notifyListeners();

    saveEncryptedBackupWithData(result);
    await _progress40Reached!.future;
  }

  void saveEncryptedBackupWithData(String data) async {
    _progress80Reached = Completer<void>();
    final savedPath = await UpdatePreparation.encryptAndSave(data: data);
    Logger.log('--> savedPath: $savedPath');

    _backupProgress = 80;
    notifyListeners();

    deleteAllWallets();
    await _progress80Reached!.future;
  }

  void deleteAllWallets() async {
    await _walletProvider.deleteAllWallets();
    await AppVersionUtil.saveAppVersionToPrefs(); // 업데이트전 버전 저장
    _backupProgress = 100;
    notifyListeners();
  }
}
