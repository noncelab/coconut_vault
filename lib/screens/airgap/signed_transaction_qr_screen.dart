import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';

class SignedTransactionQrScreen extends StatefulWidget {
  const SignedTransactionQrScreen({
    super.key,
  });

  @override
  State<SignedTransactionQrScreen> createState() => _SignedTransactionQrScreenState();
}

class _SignedTransactionQrScreenState extends State<SignedTransactionQrScreen> {
  late SignProvider _signProvider;

  @override
  void initState() {
    super.initState();
    _signProvider = Provider.of<SignProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.buildWithNext(
          title: t.signed_tx,
          context: context,
          onNextPressed: () {
            _signProvider.resetAll();
            Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
          },
          nextButtonTitle: t.complete),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: CoconutColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CoconutToolTip(
                    tooltipType: CoconutTooltipType.fixed,
                    richText: RichText(
                      text: TextSpan(
                        text: '[4] ',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.4,
                          letterSpacing: 0.5,
                          color: CoconutColors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: _signProvider.isMultisig!
                                ? t.signed_transaction_qr_screen.guide_multisig
                                : t.signed_transaction_qr_screen
                                    .guide_single_sig(name: _signProvider.walletName!),
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    showIcon: true,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: CoconutBoxDecoration.shadowBoxDecoration,
                  child: AnimatedQrView(
                    qrViewDataHandler:
                        BcUrQrViewHandler(_signProvider.signedPsbtBase64!, UrType.cryptoPsbt),
                    qrSize: MediaQuery.of(context).size.width * 0.8,
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
