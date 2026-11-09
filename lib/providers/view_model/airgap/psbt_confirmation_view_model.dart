import 'dart:collection';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/extensions/psbt_extensions.dart';
import 'package:coconut_vault/extensions/int_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/balance_format_util.dart';
import 'package:coconut_vault/utils/unit_utils.dart';
import 'package:flutter/foundation.dart';

typedef PsbtConfirmationOutput = ({int vout, String address, int amount, bool isChange});

/// An input the other party of a payjoin added and already signed.
typedef PsbtConfirmationForeignInput = ({int index, String outpoint});

class PsbtConfirmationViewModel extends ChangeNotifier {
  late final SignProvider _signProvider;
  late final VisibilityProvider _visibilityProvider;
  late final String _unsignedPsbtBase64;

  Psbt? _psbt;
  bool _isSendingToMyAddress = false;
  final List<String> _recipientAddresses = [];
  int? _sendingAmount;
  List<int?> _inputs = [];
  List<PsbtConfirmationOutput> _outputs = [];
  List<PsbtConfirmationForeignInput> _foreignInputs = [];
  int? _payjoinNetAmount;

  PsbtConfirmationViewModel(this._signProvider, this._visibilityProvider) {
    _unsignedPsbtBase64 = _signProvider.unsignedPsbtBase64!;
  }

  String get nextScreen {
    switch (_signProvider.vaultType!) {
      case WalletType.singleSignature:
        return AppRoutes.singleSigSign;
      case WalletType.multiSignature:
        return AppRoutes.multisigSign;
      case WalletType.taproot:
        return AppRoutes.taprootSign;
    }
  }

  WalletType get vaultType => _signProvider.vaultType!;
  bool get isSendingToMyAddress => _isSendingToMyAddress;
  List<String> get recipientAddress => UnmodifiableListView(_recipientAddresses);
  int? get sendingAmount => _sendingAmount;

  /// The fee, except for a payjoin: it would be computed from the other
  /// party's input amounts, which this vault cannot verify (BIP 143 commits a
  /// signature only to the amount of the input it signs).
  int? get estimatedFee => isPayjoin ? null : _psbt?.fee;
  bool get hasWarning => isPayjoin;

  /// Input amounts in transaction order; null for an input the other party
  /// added, whose amount is unverified.
  List<int?> get inputs => _inputs;
  List<PsbtConfirmationOutput> get outputs => _outputs;
  List<PsbtConfirmationForeignInput> get foreignInputs => UnmodifiableListView(_foreignInputs);
  bool get isPayjoin => _foreignInputs.isNotEmpty;

  /// For a payjoin, the change in this vault's balance: positive when it
  /// receives. Computed from this vault's own inputs and outputs only.
  int? get payjoinNetAmount => _payjoinNetAmount;

  int? get totalAmount {
    if (_psbt == null) return null;
    if (isPayjoin) return _payjoinNetAmount!.abs();
    return (_sendingAmount ?? _psbt!.sendingAmount(_wallet)) + _psbt!.fee;
  }

  WalletBase get _wallet => _signProvider.vaultListItem!.coconutVault;

  void setTxInfo() {
    _psbt = Psbt.parse(_unsignedPsbtBase64);

    _inputs = _psbt!.inputs.map((input) => input.witnessUtxo?.amount).toList();
    _outputs = [
      for (final (vout, output) in _psbt!.outputs.indexed)
        (vout: vout, address: output.outAddress, amount: output.outAmount!, isChange: output.isChange(_wallet)),
    ];

    final wallet = _wallet;
    if (wallet is SingleSignatureVault) {
      final foreignIndexes = _psbt!.foreignInputIndexes(wallet.keyStore.masterFingerprint);
      if (foreignIndexes.isNotEmpty) {
        _setPayjoinTxInfo(foreignIndexes);
        notifyListeners();
        return;
      }
    }

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
      if (!output.isOwnedBy(_wallet)) {
        outputsToOther.add(output);
      } else if (output.isChange(_wallet)) {
        outputToMyChangeAddress.add(output);
      } else {
        outputToMyReceivingAddress.add(output);
      }
    }

    if (_isBatchTransaction(outputToMyReceivingAddress, outputToMyChangeAddress, outputsToOther)) {
      Map<String, double> recipientAmounts = {};
      if (outputsToOther.isNotEmpty) {
        for (var output in outputsToOther) {
          recipientAmounts[output.outAddress] = UnitUtil.convertSatoshiToBitcoin(output.outAmount!);
        }
      }
      if (outputToMyReceivingAddress.isNotEmpty) {
        for (var output in outputToMyReceivingAddress) {
          recipientAmounts[output.outAddress] = UnitUtil.convertSatoshiToBitcoin(output.outAmount!);
        }
        _isSendingToMyAddress = true;
      }
      if (outputToMyChangeAddress.length > 1) {
        for (int i = outputToMyChangeAddress.length - 1; i > 0; i--) {
          var output = outputToMyChangeAddress[i];
          recipientAmounts[output.outAddress] = UnitUtil.convertSatoshiToBitcoin(output.outAmount!);
        }
      }
      _sendingAmount = _psbt!.sendingAmount(_wallet);
      _recipientAddresses.addAll(
        recipientAmounts.entries.map((e) {
          final amountSatoshi = UnitUtil.convertBitcoinToSatoshi(e.value);
          if (_visibilityProvider.isBtcUnit) {
            return '${e.key} (${BalanceFormatUtil.formatSatoshiToReadableBitcoin(amountSatoshi)} ${t.btc})';
          }
          return '${e.key} (${amountSatoshi.toThousandsSeparatedString()} ${t.sats})';
        }),
      );
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

      _sendingAmount = sendingAmountWhenAddressIsMyChange ?? _psbt!.sendingAmount(_wallet);
      if (output != null) {
        _recipientAddresses.add(output.outAddress);
      }
      _updateSignProvider(_psbt!, _recipientAddresses[0], _sendingAmount!);
    }

    notifyListeners();
  }

  void _setPayjoinTxInfo(List<int> foreignIndexes) {
    final psbt = _psbt!;
    final txInputs = psbt.unsignedTransaction!.inputs;
    _foreignInputs = [
      for (final index in foreignIndexes)
        (index: index, outpoint: '${txInputs[index].transactionHash}:${txInputs[index].index}'),
    ];
    for (final index in foreignIndexes) {
      _inputs[index] = null;
    }

    final net = psbt.netAmount(_wallet);
    _payjoinNetAmount = net;
    _sendingAmount = net.abs();

    // Sending: the outputs that are not ours. Receiving: our own outputs,
    // where the funds arrive.
    final isReceiving = net > 0;
    var shownOutputs = psbt.outputs.where((output) => output.isOwnedBy(_wallet) == isReceiving).toList();
    if (shownOutputs.isEmpty) shownOutputs = psbt.outputs;
    final recipients = {
      for (final output in shownOutputs) output.outAddress: UnitUtil.convertSatoshiToBitcoin(output.outAmount!),
    };
    _recipientAddresses.addAll(recipients.keys);

    _signProvider.savePsbt(psbt);
    _signProvider.saveSendingAmount(_sendingAmount!);
    _signProvider.savePayjoinNetAmount(net);
    if (recipients.length == 1) {
      _signProvider.saveRecipientAddress(recipients.keys.single);
    } else {
      _signProvider.saveRecipientAmounts(recipients);
    }
  }

  ///예외: 사용자가 배치 트랜잭션에 '남의 주소 또는 내 Receive 주소 1개'와 '본인 change 주소 1개'를 입력하고, 이 트랜잭션의 잔액이 없는 희박한 상황에서는 배치 트랜잭션임을 구분하지 못함
  bool _isBatchTransaction(
    List<PsbtOutput> outputToMyReceivingAddress,
    List<PsbtOutput> outputToMyChangeAddress,
    List<PsbtOutput> outputsToOther,
  ) {
    var countExceptToMyChangeAddress = outputToMyReceivingAddress.length + outputsToOther.length;
    if (countExceptToMyChangeAddress >= 2) {
      return true;
    }
    if (outputToMyChangeAddress.length >= 3) {
      return true;
    }
    if (outputToMyChangeAddress.length == 2 && countExceptToMyChangeAddress >= 1) {
      return true;
    }

    return false;
  }

  void _updateSignProvider(Psbt psbt, String recipient, int amount) {
    _signProvider.savePsbt(psbt);
    _signProvider.saveRecipientAddress(recipient);
    _signProvider.saveSendingAmount(amount);
  }

  void _updateSignProviderForBatch(Psbt psbt, Map<String, double> recipientAmounts, int amount) {
    _signProvider.savePsbt(psbt);
    _signProvider.saveRecipientAmounts(recipientAmounts);
    _signProvider.saveSendingAmount(amount);
  }

  void resetSignProvider() {
    _signProvider.resetPsbt();
    _signProvider.resetRecipientAddress();
    _signProvider.resetRecipientAmounts();
    _signProvider.resetSendingAmount();
    _signProvider.savePayjoinNetAmount(null);
  }
}
