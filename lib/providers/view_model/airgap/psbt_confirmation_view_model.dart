import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:flutter/foundation.dart';

class PsbtConfirmationViewModel extends ChangeNotifier {
  late final SignProvider _signProvider;
  late final String _unsignedPsbtBase64;

  PSBT? _psbt;
  PsbtOutput? _output;
  int? _sendingAmountWhenAddressIsMyChange; // 내 지갑의 change address로 보내는 경우 잔액
  bool _isSendingToMyAddress = false;
  String? _recipientAddress;
  int? _sendingAmount;
  // 현재 사용하지 않지만 관련 UI가 존재
  bool _hasWarning = false;

  PsbtConfirmationViewModel(this._signProvider) {
    _unsignedPsbtBase64 = _signProvider.unsignedPsbtBase64!;
  }

  bool get isMultisig =>
      _signProvider.vaultListItem!.vaultType == WalletType.multiSignature;
  bool get isSendingToMyAddress => _isSendingToMyAddress;
  String? get recipientAddress => _recipientAddress;
  int? get sendingAmount => _sendingAmount;
  int? get estimatedFee => _psbt?.fee;
  bool get hasWarning => _hasWarning;

  int? get totalAmount =>
      _psbt != null ? _psbt!.sendingAmount + _psbt!.fee : null;

  void setTxInfo() {
    _psbt = PSBT.parse(_unsignedPsbtBase64);

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
      if (output.derivationPath == null) {
        outputsToOther.add(output);
      } else if (output.isChange) {
        outputToMyChangeAddress.add(output);
      } else {
        outputToMyReceivingAddress.add(output);
      }
    }

    if (outputsToOther.isNotEmpty) {
      _output = outputsToOther[0];
    } else if (outputToMyReceivingAddress.isNotEmpty) {
      _output = outputToMyReceivingAddress[0];
      _isSendingToMyAddress = true;
    } else if (outputToMyChangeAddress.isNotEmpty) {
      // 받는 주소에 내 지갑의 change address를 입력한 경우
      // 원래 이 경우 output.sendingAmount = 0, 보낼 주소가 표기되지 않았었지만, 버그처럼 보이는 문제 때문에 대응합니다.
      // (주의!!) coconut_lib에서 output 배열에 sendingOutput을 먼저 담으므로 항상 첫번째 것을 사용하면 전액 보내기 일때와 아닐 때 모두 커버 됨
      // 하지만 coconut_lib에 종속적이므로 coconut_lib에 변경 발생 시 대응 필요
      _output = outputToMyChangeAddress[0];
      _sendingAmountWhenAddressIsMyChange = _output!.amount;
      _isSendingToMyAddress = true;
    }

    _sendingAmount =
        _sendingAmountWhenAddressIsMyChange ?? _psbt!.sendingAmount;
    _recipientAddress = _output != null ? _output!.getAddress() : '';

    notifyListeners();

    _updateSignProvider(_psbt!, _recipientAddress!, _sendingAmount!);
  }

  void _updateSignProvider(PSBT psbt, String recipient, int amount) {
    _signProvider.savePsbt(psbt);
    _signProvider.saveRecipientAddress(recipient);
    _signProvider.saveSendingAmount(amount);
  }

  void resetSignProvider() {
    _signProvider.resetPsbt();
    _signProvider.resetRecipientAddress();
    _signProvider.resetSendingAmount();
  }
}
