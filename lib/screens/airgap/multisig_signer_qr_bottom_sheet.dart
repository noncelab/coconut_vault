import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter_svg/svg.dart';

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
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          context: context,
          title: t.signer_qr_bottom_sheet.title,
          isBottom: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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
                          BcUrQrViewHandler(widget.signedRawTx, {'urType': 'crypto-psbt'}),
                      qrSize: MediaQuery.of(context).size.width * 0.8,
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

  List<TextSpan> _getTooltipRichText() {
    return [
      TextSpan(
        text: '[1] ${widget.keyIndex}',
        style: CoconutTypography.body2_14_Bold.copyWith(
          height: 1.2,
          letterSpacing: 0.5,
          color: CoconutColors.black,
        ),
      ),
      TextSpan(
        text: t.signer_qr_bottom_sheet.text2_1,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: widget.multisigName,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.signer_qr_bottom_sheet.text2_2,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.signer_qr_bottom_sheet.text2_3,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.signer_qr_bottom_sheet.text2_4,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
  }
}
