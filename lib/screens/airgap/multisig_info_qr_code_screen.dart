import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/airgap/multisig_psbt_qr_code_screen.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MultisigQrCodeViewScreen extends StatefulWidget {
  final String multisigName;
  final String keyIndex;
  final String signedRawTx;
  final HardwareWalletType hardwareWalletType;
  final String qrData;
  final VoidCallback onNextPressed;

  const MultisigQrCodeViewScreen({
    super.key,
    required this.multisigName,
    required this.keyIndex,
    required this.signedRawTx,
    required this.hardwareWalletType,
    required this.qrData,
    required this.onNextPressed,
  });

  @override
  State<MultisigQrCodeViewScreen> createState() => _MultisigQrCodeViewScreenState();
}

class _MultisigQrCodeViewScreenState extends State<MultisigQrCodeViewScreen> {
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
        appBar: CoconutAppBar.build(
          context: context,
          title: t.signer_qr_bottom_sheet.add_to_hww.title(name: widget.hardwareWalletType.displayName),
          isBottom: true,
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
                        child: _buildQrView(),
                      ),
                    ],
                  ),
                ),
              ),
              FixedBottomButton(
                onButtonClicked: () async {
                  Navigator.pop(context);
                  widget.onNextPressed();
                },
                text: t.next,
                showGradient: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrView() {
    final qrSize = MediaQuery.of(context).size.width * 0.8;
    final handler = BcUrQrViewHandler(widget.qrData, UrType.bytes, maxFragmentLen: 50); // TODO: 키스톤: 10000

    final qrData = handler.nextPart();
    debugPrint('--> MultisigInfoQrCodeScreen: Generated UR: ${qrData.toUpperCase()}');
    debugPrint('--> MultisigInfoQrCodeScreen: isSinglePart: ${handler.isSinglePart}');
    debugPrint('--> MultisigInfoQrCodeScreen: qrData type: ${widget.qrData.runtimeType}');
    debugPrint(
      '-->${widget.qrData.toString().substring(0, widget.qrData.toString().length > 200 ? 200 : widget.qrData.toString().length)}...',
    );

    // 단일 프래그먼트인 경우 QrImageView 직접 사용 (애니메이션 불필요)
    if (handler.isSinglePart) {
      return QrImageView(data: qrData.toUpperCase(), size: qrSize, version: QrVersions.auto);
    }

    // 다중 프래그먼트인 경우에만 AnimatedQrView 사용
    // return AnimatedQrView(qrViewDataHandler: handler, qrScanDensity: QrScanDensity.normal, qrSize: qrSize);
    return AnimatedQrView(qrViewDataHandler: handler, qrSize: qrSize);
  }

  List<TextSpan> _getTooltipRichText() {
    final textStyle = CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black);
    final textStyleBold = CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black);

    if (widget.hardwareWalletType == HardwareWalletType.keystone3Pro) {
      if (_isEnglish) {
        return [
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text0_en, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text1_en, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text2_en, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text3_en, style: textStyleBold),
          const TextSpan(text: '\n'),
          TextSpan(text: '3. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text4_en, style: textStyleBold),
          const TextSpan(text: '\n'),
          TextSpan(text: '4. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text5_en, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '5. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text6_en, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text7_en, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text8_en(noInput: ''), style: textStyle),
          TextSpan(
            text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text9_en(name: widget.multisigName),
            style: textStyle,
          ), //TODO: 이름 삽입
          const TextSpan(text: '\n'),
          TextSpan(text: '6. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text10_en, style: textStyleBold),
        ];
      }

      return [
        TextSpan(text: '1. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text0, style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text1, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text2, style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '2. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text3, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '3. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text4, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '4. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text5, style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '5. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text6, style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text7, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text8(name: widget.multisigName), style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '6. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.keystone_text9, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
      ];
    } else {
      if (_isEnglish) {
        return [
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text0_en, style: textStyle),
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text1_en, style: textStyleBold),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text2_en, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '3. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text3_en, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text4_en, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '4. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text5_en, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
        ];
      }

      return [
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text0, style: textStyle),
        TextSpan(text: '1. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text1, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),

        const TextSpan(text: '\n'),
        TextSpan(text: '2. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text2, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '3. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text3, style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text4, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
        const TextSpan(text: '\n'),
        TextSpan(text: '4. ', style: textStyle),
        TextSpan(text: t.signer_qr_bottom_sheet.add_to_hww.krux_text5, style: textStyleBold),
        TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
      ];
    }
  }
}
