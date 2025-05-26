import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_data_handler.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';

class SignerQrBottomSheet extends StatefulWidget {
  final String multisigName;
  final String keyIndex;
  final String signedRawTx;

  const SignerQrBottomSheet({
    super.key,
    required this.multisigName,
    required this.keyIndex,
    required this.signedRawTx,
  });

  @override
  State<SignerQrBottomSheet> createState() => _SignerQrBottomSheetState();
}

class _SignerQrBottomSheetState extends State<SignerQrBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MyBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CustomAppBar.buildWithClose(
          context: context,
          title: t.signer_qr_bottom_sheet.title,
        ),
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
                        text: '[1] ${widget.keyIndex}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.4,
                          letterSpacing: 0.5,
                          color: MyColors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: t.signer_qr_bottom_sheet.text2_1,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: widget.multisigName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: t.signer_qr_bottom_sheet.text2_2,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: t.signer_qr_bottom_sheet.text2_3,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: t.signer_qr_bottom_sheet.text2_4,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
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
                      data: AnimatedQRDataHandler.splitData(widget.signedRawTx),
                      size: MediaQuery.of(context).size.width * 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
