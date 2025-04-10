import 'dart:async';
import 'dart:math';

import 'package:coconut_vault/enums/app_update_step_enum.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/app_update_helpers/app_update_preparation_screen.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/material.dart';

class RandomVaultMnemonic {
  final String vaultName;
  final String mnemonic;
  final int mnemonicIndex;

  const RandomVaultMnemonic({
    required this.vaultName,
    required this.mnemonic,
    required this.mnemonicIndex,
  });
}

class AppUpdatePreparationViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  int _backupProgress = 0;
  Completer<void>? _progress40Reached;
  Completer<void>? _progress80Reached;

  RandomVaultMnemonic? _randomVaultMnemonic;
  AppUpdateStep _currentStep = AppUpdateStep.initial;

  AppUpdatePreparationViewModel(this._walletProvider) {
    _setRandomMnemonic();
  }

  int get backupProgress => _backupProgress;
  RandomVaultMnemonic? get randomVaultMnemonic => _randomVaultMnemonic;
  AppUpdateStep get currentStep => _currentStep;

  void setCurrentStep(AppUpdateStep step) {
    _currentStep = step;
    notifyListeners();
  }

  Future<void> _setRandomMnemonic() async {
    // TODO: 두개의 랜덤 니모닉을 확인할 수 있도록 수정 필요, 현재는 한개만 랜덤으로 확인합니다.
    final vaultIdList =
        _walletProvider.vaultList.map((vault) => vault.id).toList();
    final random = Random();
    final randomVaultId = vaultIdList[random.nextInt(vaultIdList.length)];

    final mnemonic =
        await _walletProvider.getSecret(randomVaultId).then((secret) {
      return secret.mnemonic.split(' ');
    });

    final randomMnemonicIndex = random.nextInt(mnemonic.length);

    final vaultName = _walletProvider.getVaultById(randomVaultId).name;

    _randomVaultMnemonic = RandomVaultMnemonic(
      vaultName: vaultName,
      mnemonic: hashString(mnemonic[randomMnemonicIndex]),
      mnemonicIndex: randomMnemonicIndex,
    );
  }

  void setProgressReached(int value) {
    if (value == 40 &&
        _progress40Reached != null &&
        !_progress40Reached!.isCompleted) {
      _progress40Reached!.complete();
    } else if (value == 80 &&
        _progress80Reached != null &&
        !_progress80Reached!.isCompleted) {
      _progress80Reached!.complete();
    }
  }

  void createBackupData() async {
    _progress40Reached = Completer<void>();
    final result = await _walletProvider.createBackupData();

    _backupProgress = 40;
    notifyListeners();

    await _progress40Reached!.future;
    _saveEncryptedBackupWithData(result);
  }

  void _saveEncryptedBackupWithData(String data) async {
    _progress80Reached = Completer<void>();
    final savedPath = await UpdatePreparation.encryptAndSave(data: data);
    Logger.log('--> savedPath: $savedPath');

    _backupProgress = 80;
    notifyListeners();

    await _progress80Reached!.future;
    _deleteAllWallets();
  }

  void _deleteAllWallets() async {
    await _walletProvider.deleteAllWallets();
    _backupProgress = 100;
    notifyListeners();
  }
}
