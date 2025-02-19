import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_data_handler.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';

class SignedTransactionQrScreen extends StatefulWidget {
  const SignedTransactionQrScreen({
    super.key,
  });

  @override
  State<SignedTransactionQrScreen> createState() =>
      _SignedTransactionQrScreenState();
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
      backgroundColor: Colors.white,
      appBar: CustomAppBar.buildWithNext(
          title: t.signed_tx,
          context: context,
          onNextPressed: () {
            _signProvider.resetAll();
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (Route<dynamic> route) => false);
          },
          buttonName: t.complete),
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
                          text: _signProvider.vaultListItem!.vaultType ==
                                  WalletType.multiSignature
                              ? t.signed_transaction_qr_screen.guide_multisig
                              : t.signed_transaction_qr_screen.guide_single_sig(
                                  name: _signProvider.vaultListItem!.name),
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
                    data: AnimatedQRDataHandler.splitData(
                        _signProvider.signedPsbtBase64!),
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
