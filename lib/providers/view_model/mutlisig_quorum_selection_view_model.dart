import 'package:coconut_vault/constants/multisig.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';
import 'package:flutter/material.dart';

class MultisigQuorumSelectionViewModel extends ChangeNotifier {
  final WalletCreationProvider _walletCreationProvider;

  late int _requiredCount;
  late int _totalCount;

  late int _buttonClickedCount;
  late bool _isNextButtonEnabled;

  MultisigQuorumSelectionViewModel(this._walletCreationProvider) {
    _walletCreationProvider.resetAll();

    _totalCount = 3; // kMultisigMaxTotalCount에 상관없이 2/3 권장
    _requiredCount = MultisigUtils.calculateRecommendedRequiredCount(_totalCount);
    _buttonClickedCount = 0;
    _isNextButtonEnabled = false;
  }

  int get buttonClickedCount => _buttonClickedCount;
  bool get isQuorumSettingValid => _isNextButtonEnabled && MultisigUtils.isValidQuorum(_requiredCount, _totalCount);
  bool get nextButtonEnabled => _isNextButtonEnabled;
  int get requiredCount => _requiredCount;
  int get totalCount => _totalCount;
  MultisigCategory get quorumCategory => MultisigUtils.classifyPolicy(_requiredCount, _totalCount);
  String get quorumCategoryText => MultisigUtils.buildQuorumCategoryText(quorumCategory);
  String get quorumMessage => MultisigUtils.buildQuorumMessage(quorumCategory, _requiredCount);

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
        if (count >= 2 && count <= kMultisigMaxTotalCount) {
          if (count == kMultisigMinTotalCount && count < _requiredCount) {
            _requiredCount = count;
          }
          _totalCount = count;
          _buttonClickedCount++;
        }
        break;
      case QuorumType.requiredCount:
        if (count >= 1 && count <= kMultisigMaxTotalCount) {
          _requiredCount = count;
          _buttonClickedCount++;
        }
        break;
    }
    notifyListeners();
  }
}

enum QuorumType { totalCount, requiredCount }
