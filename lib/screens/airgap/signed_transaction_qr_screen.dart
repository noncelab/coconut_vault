import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_data_handler.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';

class SignedTransactionQrScreen extends StatefulWidget {
  final int id;

  const SignedTransactionQrScreen({
    super.key,
    required this.id,
  });

  @override
  State<SignedTransactionQrScreen> createState() =>
      _SignedTransactionQrScreenState();
}

class _SignedTransactionQrScreenState extends State<SignedTransactionQrScreen> {
  late String _signedRawTx;
  late String _walletName;
  late VaultModel _vaultModel;
  bool _isMultisig = false;

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    if (_vaultModel.signedRawTx == null) {
      throw "[SignedTransactionScreen] _model.signedRawTx is null";
    }

    _signedRawTx = _vaultModel.signedRawTx!;

    final vaultListItem = _vaultModel.getVaultById(widget.id);
    _isMultisig = vaultListItem.vaultType == VaultType.multiSignature;
    _walletName = vaultListItem.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar.buildWithNext(
          title: '서명 트랜잭션',
          context: context,
          onNextPressed: () {
            _vaultModel.clearWaitingForSignaturePsbt();
            _vaultModel.signedRawTx = null;
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (Route<dynamic> route) => false);
          },
          buttonName: '완료'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: MyColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                CustomTooltip(
                  richText: RichText(
                    text: TextSpan(
                      text: '[4] ',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.4,
                        letterSpacing: 0.5,
                        color: MyColors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: _isMultisig
                              ? '다중 서명을 완료했어요. 보내기 정보를 생성한 월렛으로 아래 QR 코드를 스캔해 주세요.'
                              : '월렛의 \'$_walletName 지갑\'에서 만든 보내기 정보에 서명을 완료했어요. 월렛으로 아래 QR 코드를 스캔해 주세요.',
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  showIcon: true,
                  type: TooltipType.info,
                ),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecorations.shadowBoxDecoration,
                  child: AnimatedQrView(
                    data: AnimatedQRDataHandler.splitData(_signedRawTx),
                    size: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
