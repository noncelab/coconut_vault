import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/animated_qr/qr_scan_density.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:flutter/material.dart';

class PsbtQrCodeScreen extends StatefulWidget {
  final String qrData;
  final List<TextSpan> guideRichText;
  final String? appBarTitle;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const PsbtQrCodeScreen({
    super.key,
    required this.qrData,
    required this.guideRichText,
    this.appBarTitle,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  State<PsbtQrCodeScreen> createState() => _PsbtQrCodeScreenState();
}

class _PsbtQrCodeScreenState extends State<PsbtQrCodeScreen> {
  late double _sliderValue;
  late QrScanDensity _qrScanDensity;
  int? _lastSnappedValue;

  @override
  void initState() {
    super.initState();
    _qrScanDensity = QrScanDensity.fast;
    _sliderValue = _qrScanDensity.index * 5;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: widget.appBarTitle != null
            ? CoconutAppBar.build(
                context: context,
                title: widget.appBarTitle!,
                isBottom: true,
              )
            : null,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: CoconutColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomTooltip.buildInfoTooltip(
                        context,
                        richText: RichText(
                          text: TextSpan(
                            style: CoconutTypography.body2_14.copyWith(
                              height: 1.2,
                              color: CoconutColors.black,
                            ),
                            children: widget.guideRichText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      AdaptiveQrImage(
                        qrDensity: _qrScanDensity,
                        qrViewDataHandler: BcUrQrViewHandler(
                          widget.qrData,
                          UrType.cryptoPsbt,
                          maxFragmentLen: _getMaxFragmentLen(_qrScanDensity),
                        ),
                      ),
                      CoconutLayout.spacing_800h,
                      _buildDensitySliderWidget(context),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
              FixedBottomButton(
                onButtonClicked: widget.onButtonPressed,
                text: widget.buttonText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getMaxFragmentLen(QrScanDensity density) {
    switch (density) {
      case QrScanDensity.fast:
        return 80;
      case QrScanDensity.normal:
        return 40;
      case QrScanDensity.slow:
        return 20;
    }
  }

  int _getSnappedValue(double value) {
    if (value <= 2.5) return 0;
    if (value <= 7.5) return 5;
    return 10;
  }

  QrScanDensity _mapValueToDensity(int val) {
    switch (val) {
      case 0:
        return QrScanDensity.slow;
      case 5:
        return QrScanDensity.normal;
      case 10:
      default:
        return QrScanDensity.fast;
    }
  }

  Widget _buildDensitySliderWidget(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Row(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                t.signer_qr_bottom_sheet.low_density_qr,
                style: CoconutTypography.body3_12,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: CoconutColors.gray400,
                  inactiveTrackColor: CoconutColors.gray400,
                  trackHeight: 8,
                  thumbColor: CoconutColors.gray800,
                  overlayColor: CoconutColors.gray700.withOpacity(0.2),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _sliderValue,
                  min: 0,
                  max: 10.0,
                  divisions: 100,
                  onChanged: (double value) {
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                  onChangeEnd: (double value) {
                    final snapped = _getSnappedValue(value);
                    if (_lastSnappedValue != snapped) {
                      vibrateExtraLight();
                      _lastSnappedValue = snapped;
                    }
                    setState(() {
                      _sliderValue = snapped.toDouble();
                      _qrScanDensity = _mapValueToDensity(snapped);
                    });
                  },
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                t.signer_qr_bottom_sheet.high_density_qr,
                style: CoconutTypography.body3_12,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
