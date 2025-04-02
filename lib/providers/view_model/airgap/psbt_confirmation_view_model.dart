import 'dart:collection';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/utils/unit_utils.dart';
import 'package:flutter/foundation.dart';

class PsbtConfirmationViewModel extends ChangeNotifier {
  late final SignProvider _signProvider;
  late final String _unsignedPsbtBase64;

  Psbt? _psbt;
  bool _isSendingToMyAddress = false;
  final List<String> _recipientAddresses = [];
  int? _sendingAmount;
  // 현재 사용하지 않지만 관련 UI가 존재
  bool _hasWarning = false;

  PsbtConfirmationViewModel(this._signProvider) {
    _unsignedPsbtBase64 = _signProvider.unsignedPsbtBase64!;
  }

  bool get isMultisig => _signProvider.isMultisig!;
  bool get isSendingToMyAddress => _isSendingToMyAddress;
  List<String> get recipientAddress =>
      UnmodifiableListView(_recipientAddresses);
  int? get sendingAmount => _sendingAmount;
  int? get estimatedFee => _psbt?.fee;
  bool get hasWarning => _hasWarning;

  int? get totalAmount =>
      _psbt != null ? _psbt!.sendingAmount + _psbt!.fee : null;

  void setTxInfo() {
    _psbt = Psbt.parse(_unsignedPsbtBase64);

    List<PsbtOutput> outputs = _psbt!.outputs;

    // case1. 다른 사람에게 보내고(B1) 잔액이 있는 경우(A2)
    // case2. 다른 사람에게 보내고(B1) 잔액이 없는 경우
    // case3. 내 지갑의 다른 주소로 보내고(A2) 잔액이 있는 경우(A3)
    // case4. 내 지갑의 다른 주소로 보내고(A2) 잔액이 없는 경우
    // 만약 실수로 내 지갑의 change address로 보내는 경우에는 sendingAmount가 0
    List<PsbtOutput> outputToMyReceivingAddress = [];
    List<PsbtOutput> outputToMyChangeAddress = [];
    List<PsbtOutput> outputsToOther = [];
    for (var output in outputs) {
      if (output.bip32Derivation == null) {
        outputsToOther.add(output);
      } else if (output.isChange) {
        outputToMyChangeAddress.add(output);
      } else {
        outputToMyReceivingAddress.add(output);
      }
    }

    if (_isBatchTransaction(
        outputToMyReceivingAddress, outputToMyChangeAddress, outputsToOther)) {
      Map<String, double> recipientAmounts = {};
      if (outputsToOther.isNotEmpty) {
        for (var output in outputsToOther) {
          recipientAmounts[output.outAddress] =
              UnitUtil.satoshiToBitcoin(output.outAmount!);
        }
      }
      if (outputToMyReceivingAddress.isNotEmpty) {
        for (var output in outputToMyReceivingAddress) {
          recipientAmounts[output.outAddress] =
              UnitUtil.satoshiToBitcoin(output.outAmount!);
        }
        _isSendingToMyAddress = true;
      }
      if (outputToMyChangeAddress.length > 1) {
        for (int i = outputToMyChangeAddress.length - 1; i > 0; i--) {
          var output = outputToMyChangeAddress[i];
          recipientAmounts[output.outAddress] =
              UnitUtil.satoshiToBitcoin(output.outAmount!);
        }
      }
      _sendingAmount = _psbt!.sendingAmount;
      _recipientAddresses
          .addAll(recipientAmounts.entries.map((e) => '${e.key} (${e.value})'));
      _updateSignProviderForBatch(_psbt!, recipientAmounts, _sendingAmount!);
    } else {
      // 내 지갑의 change address로 보내는 경우 잔액
      int? sendingAmountWhenAddressIsMyChange;

      PsbtOutput? output;
      if (outputsToOther.isNotEmpty) {
        output = outputsToOther[0];
      } else if (outputToMyReceivingAddress.isNotEmpty) {
        output = outputToMyReceivingAddress[0];
        _isSendingToMyAddress = true;
      } else if (outputToMyChangeAddress.isNotEmpty) {
        // 받는 주소에 내 지갑의 change address를 입력한 경우
        // 원래 이 경우 output.sendingAmount = 0, 보낼 주소가 표기되지 않았었지만, 버그처럼 보이는 문제 때문에 대응합니다.
        // (주의!!) coconut_lib에서 output 배열에 sendingOutput을 먼저 담으므로 항상 첫번째 것을 사용하면 전액 보내기 일때와 아닐 때 모두 커버 됨
        // 하지만 coconut_lib에 종속적이므로 coconut_lib에 변경 발생 시 대응 필요
        output = outputToMyChangeAddress[0];
        sendingAmountWhenAddressIsMyChange = output.outAmount;
        _isSendingToMyAddress = true;
      }

      _sendingAmount =
          sendingAmountWhenAddressIsMyChange ?? _psbt!.sendingAmount;
      if (output != null) {
        _recipientAddresses.add(output.outAddress);
      }
      _updateSignProvider(_psbt!, _recipientAddresses[0], _sendingAmount!);
    }

    notifyListeners();
  }

  ///예외: 사용자가 배치 트랜잭션에 '남의 주소 또는 내 Receive 주소 1개'와 '본인 change 주소 1개'를 입력하고, 이 트랜잭션의 잔액이 없는 희박한 상황에서는 배치 트랜잭션임을 구분하지 못함
  bool _isBatchTransaction(
      List<PsbtOutput> outputToMyReceivingAddress,
      List<PsbtOutput> outputToMyChangeAddress,
      List<PsbtOutput> outputsToOther) {
    var countExceptToMyChangeAddress =
        outputToMyReceivingAddress.length + outputsToOther.length;
    if (countExceptToMyChangeAddress >= 2) {
      return true;
    }
    if (outputToMyChangeAddress.length >= 3) {
      return true;
    }
    if (outputToMyChangeAddress.length == 2 &&
        countExceptToMyChangeAddress >= 1) {
      return true;
    }

    return false;
  }

  void _updateSignProvider(Psbt psbt, String recipient, int amount) {
    _signProvider.savePsbt(psbt);
    _signProvider.saveRecipientAddress(recipient);
    _signProvider.saveSendingAmount(amount);
  }

  void _updateSignProviderForBatch(
      Psbt psbt, Map<String, double> recipientAmounts, int amount) {
    _signProvider.savePsbt(psbt);
    _signProvider.saveRecipientAmounts(recipientAmounts);
    _signProvider.saveSendingAmount(amount);
  }

  void resetSignProvider() {
    _signProvider.resetPsbt();
    _signProvider.resetRecipientAddress();
    _signProvider.resetRecipientAmounts();
    _signProvider.resetSendingAmount();
  }
}
