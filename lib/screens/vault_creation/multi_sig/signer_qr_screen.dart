import 'package:coconut_vault/widgets/animatedQR/animated_qr_data_handler.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';

class SignerQrScreen extends StatefulWidget {
  final String memo;

  const SignerQrScreen({
    super.key,
    required this.memo,
  });

  @override
  State<SignerQrScreen> createState() => _SignerQrScreenState();
}

class _SignerQrScreenState extends State<SignerQrScreen> {
  late VaultModel _vaultModel;
  late String _signedRawTx;

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();

    if (_vaultModel.signedRawTx == null) {
      throw "[SignedTransactionScreen] _model.waitingForSignaturePsbtBase64 is null";
    }

    _signedRawTx = _vaultModel.signedRawTx!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar.buildWithNext(
          title: '외부 지갑${widget.memo.isNotEmpty ? '(${widget.memo})' : ''}',
          context: context,
          onNextPressed: () {
            // Navigator.pushNamedAndRemoveUntil(
            //     context, '/', (Route<dynamic> route) => false);
          },
          buttonName: '다음'),
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
                    text: const TextSpan(
                      text: '[1] ',
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
                          text: '외부 볼트에서 아래 정보를 스캔해 주세요. 반드시 지갑 이름이 같아야 해요.',
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
