import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
      appBar: CoconutAppBar.build(
        title: t.signed_tx,
        context: context,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                width: double.infinity,
                color: CoconutColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                      child: CoconutToolTip(
                        backgroundColor: CoconutColors.gray100,
                        borderColor: CoconutColors.gray400,
                        icon: SvgPicture.asset(
                          'assets/svg/circle-info.svg',
                          colorFilter: const ColorFilter.mode(
                            CoconutColors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                        tooltipType: CoconutTooltipType.fixed,
                        richText: RichText(
                          text: TextSpan(
                            style: CoconutTypography.body3_12,
                            children: _getTooltipRichText(),
                          ),
                        ),
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
            FixedBottomButton(
              text: t.complete,
              onButtonClicked: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CoconutPopup(
                      title: t.alert.finish_signing.title,
                      description: t.alert.finish_signing.description,
                      onTapRight: () {
                        _signProvider.resetAll();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (Route<dynamic> route) => false);
                      },
                      onTapLeft: () {
                        Navigator.pop(context);
                      },
                      leftButtonText: t.cancel,
                      rightButtonText: t.abort,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _getTooltipRichText() {
    return [
      TextSpan(
        text: '[4] ',
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: _signProvider.isMultisig!
            ? t.signed_transaction_qr_screen.guide_multisig
            : t.signed_transaction_qr_screen.guide_single_sig(name: _signProvider.walletName!),
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
  }
}
