import 'dart:math';

import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/hash_util.dart';
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

  RandomVaultMnemonic? _randomVaultMnemonic;

  AppUpdatePreparationViewModel(this._walletProvider) {
    _setRandomMnemonic();
  }

  RandomVaultMnemonic? get randomVaultMnemonic => _randomVaultMnemonic;

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
}
