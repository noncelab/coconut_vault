import 'package:coconut_vault/widgets/custom_message_screen_for_web.dart';
import 'package:coconut_vault/widgets/message_screen_for_web.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/services/isolate_service.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/unit_utils.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/information_item_row.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:provider/provider.dart';

class PsbtConfirmationScreen extends StatefulWidget {
  final int id;

  const PsbtConfirmationScreen({super.key, required this.id});

  @override
  State<PsbtConfirmationScreen> createState() => _PsbtConfirmationScreenState();
}

class _PsbtConfirmationScreenState extends State<PsbtConfirmationScreen> {
  late VaultModel _vaultModel;
  late WalletBase _walletBase;
  String? _waitingForSignaturePsbtBase64;
  PSBT? _psbt;
  final bool _showWarning = false;
  PsbtOutput? _output;
  int? _sendingAmountWhenAddressIsMyChange; // 내 지갑의 change address로 보내는 경우 잔액
  bool _isSendingToMyAddress = false;
  bool _showLoading = true;
  bool _isMultisig = false;

  String _bitcoinString = '';
  String _sendAddress = '';

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    if (_vaultModel.waitingForSignaturePsbtBase64 == null) {
      throw "[psbt_confirmation_screen] _model.waitingForSignaturePsbtBase64 is null";
    }

    _waitingForSignaturePsbtBase64 = _vaultModel.waitingForSignaturePsbtBase64;
    final vaultBaseItem = _vaultModel.getVaultById(widget.id);
    _walletBase = vaultBaseItem.coconutVault;
    _isMultisig = vaultBaseItem.vaultType == VaultType.multiSignature;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setTxInfo(_vaultModel.waitingForSignaturePsbtBase64!);
      setState(
        () => _showLoading = false,
      );
    });
  }

  void setTxInfo(String psbtBase64) {
    try {
      var psbt = PSBT.parse(psbtBase64);

      setState(() {
        _psbt = psbt;
      });

      List<PsbtOutput> outputs = psbt.outputs;

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
        setState(() {
          _output = outputsToOther[0];
        });
      } else if (outputToMyReceivingAddress.isNotEmpty) {
        setState(() {
          _output = outputToMyReceivingAddress[0];
          _isSendingToMyAddress = true;
        });
      } else if (outputToMyChangeAddress.isNotEmpty) {
        // 받는 주소에 내 지갑의 change address를 입력한 경우
        // 원래 이 경우 output.sendingAmount = 0, 보낼 주소가 표기되지 않았었지만, 버그처럼 보이는 문제 때문에 대응합니다.
        // (주의!!) coconut_lib에서 output 배열에 sendingOutput을 먼저 담으므로 항상 첫번째 것을 사용하면 전액 보내기 일때와 아닐 때 모두 커버 됨
        // 하지만 coconut_lib에 종속적이므로 coconut_lib에 변경 발생 시 대응 필요
        setState(() {
          _output = outputToMyChangeAddress[0];
          _sendingAmountWhenAddressIsMyChange = _output!.amount;
          _isSendingToMyAddress = true;
        });
      }

      setState(() {
        _bitcoinString = _psbt != null
            ? satoshiToBitcoinString(_sendingAmountWhenAddressIsMyChange != null
                ? _sendingAmountWhenAddressIsMyChange!
                : _psbt!.sendingAmount)
            : '';
        _sendAddress = _output != null ? _output!.getAddress() : '';
      });
    } catch (_) {
      if (context.mounted) {
        showAlertDialog(context: context, content: "psbt 파싱 실패: $_");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.buildWithNext(
        title: '스캔 정보 확인',
        context: context,
        isActive: !_showLoading,
        onNextPressed: () {
          if (_isMultisig) {
            Navigator.pushNamed(
              context,
              '/multi-signature',
              arguments: {
                'id': widget.id,
                'psbtBase64': _waitingForSignaturePsbtBase64!,
                'sendAddress': _sendAddress,
                'bitcoinString': _bitcoinString,
              },
            );
          } else {
            Navigator.pushNamed(
              context,
              '/singlesig-sign',
              arguments: {
                'id': widget.id,
                'psbtBase64': _waitingForSignaturePsbtBase64!,
                'sendAddress': _sendAddress,
                'bitcoinString': _bitcoinString,
              },
            );
            //sign();
          }
        },
        isBottom: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CustomTooltip(
                    richText: RichText(
                      text: const TextSpan(
                        text: '[3] ',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.4,
                          letterSpacing: 0.5,
                          color: MyColors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '월렛에서 스캔한 정보가 맞는지 다시 한번 확인해 주세요.',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    showIcon: true,
                    type: TooltipType.info,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          text: _bitcoinString,
                          children: const <TextSpan>[
                            TextSpan(text: ' BTC', style: Styles.unit),
                          ],
                        ),
                        style: Styles.balance1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.0),
                        color: MyColors.transparentBlack_03,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            InformationRowItem(
                              label: '보낼 주소',
                              value: _sendAddress,
                              isNumber: true,
                            ),
                            const Divider(
                              color: MyColors.borderLightgrey,
                              height: 1,
                            ),
                            InformationRowItem(
                              label: '예상 수수료',
                              value: _psbt != null
                                  ? "${satoshiToBitcoinString(_psbt!.fee)} BTC"
                                  : "",
                              isNumber: true,
                            ),
                            const Divider(
                              color: MyColors.borderLightgrey,
                              height: 1,
                            ),
                            InformationRowItem(
                              label: '총 소요 수량',
                              value: _psbt != null
                                  ? "${satoshiToBitcoinString(_psbt!.sendingAmount + _psbt!.fee)} BTC"
                                  : "",
                              isNumber: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isSendingToMyAddress) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      "내 지갑으로 보내는 트랜잭션입니다.",
                      textAlign: TextAlign.center,
                      style: Styles.caption,
                    ),
                  ],
                  if (_showWarning) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: Paddings.widgetContainer,
                      decoration: BoxDecoration(
                          borderRadius: MyBorder.defaultRadius,
                          color: MyColors.transparentBlack_30),
                      child: const Text(
                        "⚠️ 해당 지갑으로 만든 psbt가 아닐 수 있습니다. 또는 잔액이 없는 트랜잭션일 수 있습니다.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Visibility(
              visible: _showLoading,
              child: const CustomMessageScreenForWeb(message: '서명 중'),
            ),
          ],
        ),
      ),
    );
  }
}

// Future<String> addSignatureToPsbt(WalletBase vault, String data) async {
//   final addSignatureToPsbtHandler =
//   IsolateHandler<List<dynamic>, String>(addSignatureToPsbtIsolate);
//   try {
//     await addSignatureToPsbtHandler.initialize(
//         initialType: InitializeType.addSign);
//
//     String signedPsbt = await addSignatureToPsbtHandler.run([vault, data]);
//     Logger.log(signedPsbt);
//     return signedPsbt;
//   } catch (e) {
//     Logger.log('[addSignatureToPsbtIsolate] ${e.toString()}');
//     throw (e.toString());
//   } finally {
//     addSignatureToPsbtHandler.dispose();
//   }
// }

Future<String> addSignatureToPsbt(
    SingleSignatureVault vault, String data) async {
  try {
    return vault.addSignatureToPsbt(data);
  } catch (e) {
    Logger.log('[addSignatureToPsbtIsolate] ${e.toString()}');
    rethrow;
  }
}

Future<bool> canSignToPsbt(SingleSignatureVault vault, String data) async {
  try {
    return vault.canSignToPsbt(data);
  } catch (e) {
    Logger.log('[canSignToPsbtIsolate] ${e.toString()}');
    rethrow;
  }
}
