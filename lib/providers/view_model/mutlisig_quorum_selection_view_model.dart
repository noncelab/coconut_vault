import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider/wallet_provider.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';
import 'package:flutter/material.dart';

class MultisigQuorumSelectionViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  final WalletCreationProvider _walletCreationProvider;

  late int _maxCount;

  late int _requiredCount;
  late int _totalCount;

  late int _buttonClickedCount;
  late bool _isNextButtonEnabled;

  MultisigQuorumSelectionViewModel(this._walletProvider, this._walletCreationProvider) {
    _walletCreationProvider.resetAll();

    _maxCount = _walletProvider.vaultList.length >= 3 ? 3 : 2;
    _requiredCount = 2;
    _totalCount = 3;
    _buttonClickedCount = 0;
    _isNextButtonEnabled = false;
  }
  int get buttonClickedCount => _buttonClickedCount;
  bool get isQuorumSettingValid =>
      _isNextButtonEnabled && MultisigUtils.validateQuorumRequirement(_requiredCount, _totalCount);
  bool get nextButtonEnabled => _isNextButtonEnabled;
  int get requiredCount => _requiredCount;
  int get totalCount => _totalCount;
  int get maxCount => _maxCount;

  String buildQuorumMessage() {
    String result = '';

    switch (_totalCount) {
      case 2:
        {
          if (_requiredCount == 1) {
            {
              result = t.select_multisig_quorum_screen.one_or_two_of_n;
              break;
            }
          } else {
            {
              result = t.select_multisig_quorum_screen.n_of_n;
              break;
            }
          }
        }
      case 3:
        {
          if (_requiredCount == 1) {
            {
              result = t.select_multisig_quorum_screen.one_of_n;
              break;
            }
          } else if (_requiredCount == 2) {
            {
              result = t.select_multisig_quorum_screen.one_or_two_of_n;
              break;
            }
          } else {
            {
              result = t.select_multisig_quorum_screen.n_of_n;
              break;
            }
          }
        }
    }
    return result;
  }

  void setNextButtonEnabled(bool value) {
    _isNextButtonEnabled = value;
    notifyListeners();
  }

  void saveQuorumRequirement() {
    _walletCreationProvider.setQuorumRequirement(_requiredCount, _totalCount);
  }

  void onClick(QuorumType quorumType, int count) {
    switch (quorumType) {
      case QuorumType.totalCount:
        if (count >= 2 && count <= 3) {
          if (count == 2 && count < _requiredCount) {
            _requiredCount = count;
          }
          _totalCount = count;
          _buttonClickedCount++;
        }
        break;
      case QuorumType.requiredCount:
        if (count >= 1 && count <= 3) {
          _requiredCount = count;
          _buttonClickedCount++;
        }
        break;
    }
    notifyListeners();
  }
}

enum QuorumType { totalCount, requiredCount }

class QueueDataClass {
  final int count;
  final QueueEntity entity;

  const QueueDataClass({required this.count, required this.entity});
}

enum QueueEntity { n2m1, n2m2, n3m1, n3m2, n3m3 }
