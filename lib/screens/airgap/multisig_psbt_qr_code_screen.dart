import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PsbtQrCodeViewScreen extends StatefulWidget {
  final String multisigName;
  final String keyIndex;
  final String signedRawTx;
  final HardwareWalletType hardwareWalletType;

  const PsbtQrCodeViewScreen({
    super.key,
    required this.multisigName,
    required this.keyIndex,
    required this.signedRawTx,
    required this.hardwareWalletType,
  });

  @override
  State<PsbtQrCodeViewScreen> createState() => _PsbtQrCodeViewScreenState();
}

class _PsbtQrCodeViewScreenState extends State<PsbtQrCodeViewScreen> {
  late VisibilityProvider _visibilityProvider;

  bool _isEnglish = true;

  @override
  void initState() {
    super.initState();
    _visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);
    _isEnglish = _visibilityProvider.language == 'en';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(context: context, title: t.signer_qr_bottom_sheet.title, isBottom: true),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              color: CoconutColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CustomTooltip.buildInfoTooltip(
                    context,
                    richText: RichText(
                      text: TextSpan(style: CoconutTypography.body2_14, children: _getTooltipRichText()),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: CoconutBoxDecoration.shadowBoxDecoration,
                    child: AnimatedQrView(
                      qrViewDataHandler: BcUrQrViewHandler(widget.signedRawTx, UrType.cryptoPsbt),
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
    final textStyle = CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black);
    final textStyleNumberBold = CoconutTypography.body1_16_Bold.copyWith(height: 1.2, color: CoconutColors.black);
    final textStyleBold = CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black);

    if (_isEnglish) {
      return [
        TextSpan(text: '[1] ', style: textStyleNumberBold),
        TextSpan(text: t.signer_qr_bottom_sheet.text1, style: textStyle),
        TextSpan(text: widget.keyIndex, style: textStyleBold),
        TextSpan(text: ',', style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '1. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.text2, style: textStyleBold),
        const TextSpan(text: '\n'),
        TextSpan(text: '2. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.text3, style: textStyle),
      ];
    }

    return [
      TextSpan(text: '[1] ${widget.keyIndex}', style: textStyleNumberBold),
      TextSpan(text: t.signer_qr_bottom_sheet.text1, style: textStyle),
      const TextSpan(text: '\n'),
      TextSpan(text: '1. ', style: textStyle),
      TextSpan(text: t.signer_qr_bottom_sheet.text2, style: textStyleBold),
      TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
      const TextSpan(text: '\n'),
      TextSpan(text: '2. ', style: textStyle),
      TextSpan(text: t.signer_qr_bottom_sheet.text3, style: textStyleBold),
    ];
  }
}
