import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';
import 'package:flutter/material.dart';

class MultisigQuorumSelectionViewModel extends ChangeNotifier {
  final WalletCreationProvider _walletCreationProvider;
  late int _requiredCount;
  late int _totalCount;
  late int _buttonClickedCount;
  late bool _isNextButtonEnabled;
  late bool _isProgressAnimationVisible;

  MultisigQuorumSelectionViewModel(this._walletCreationProvider) {
    _walletCreationProvider.resetAll();

    _requiredCount = 2;
    _totalCount = 3;
    _buttonClickedCount = 0;
    _isNextButtonEnabled = false;
    _isProgressAnimationVisible = true;
  }
  int get buttonClickedCount => _buttonClickedCount;
  bool get isProgressAnimationVisible => _isProgressAnimationVisible;
  bool get isQuorumSettingValid =>
      _isNextButtonEnabled && MultisigUtils.validateQuorumRequirement(_requiredCount, _totalCount);
  bool get nextButtonEnabled => _isNextButtonEnabled;
  int get requiredCount => _requiredCount;
  int get totalCount => _totalCount;

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

  void onCountButtonClicked(ChangeCountButtonType buttonType) {
    if (!_isNextButtonEnabled) {
      setNextButtonEnabled(true);
    }
    switch (buttonType) {
      case ChangeCountButtonType.mCountMinus:
        {
          if (requiredCount == 1) return;
          _requiredCount--;
          _buttonClickedCount++;
          notifyListeners();
          break;
        }
      case ChangeCountButtonType.mCountPlus:
        {
          if (requiredCount == totalCount) return;
          _requiredCount++;
          _buttonClickedCount++;
          notifyListeners();
          break;
        }

      case ChangeCountButtonType.nCountMinus:
        {
          if (totalCount == 2) return;
          if (totalCount == requiredCount) {
            _requiredCount--;
          }
          _totalCount--;
          _buttonClickedCount++;
          notifyListeners();
          break;
        }
      case ChangeCountButtonType.nCountPlus:
        {
          if (totalCount == 3) return;
          _totalCount++;
          _buttonClickedCount++;
          notifyListeners();
          break;
        }
    }
  }

  void setNextButtonEnabled(bool value) {
    _isNextButtonEnabled = value;
    notifyListeners();
  }

  // TODO: UI 관련 변수
  void setProgressAnimationVisible(bool value) {
    _isProgressAnimationVisible = value;
    notifyListeners();
  }

  void saveQuorumRequirement() {
    _walletCreationProvider.setQuorumRequirement(_requiredCount, _totalCount);
  }
}

class QueueDataClass {
  final int count;
  final QueueEntity entity;

  const QueueDataClass({
    required this.count,
    required this.entity,
  });
}

enum QueueEntity { n2m1, n2m2, n3m1, n3m2, n3m3 }
