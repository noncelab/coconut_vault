import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_scanner.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class SignerScanBottomSheet extends StatefulWidget {
  final Function onScanComplete;
  const SignerScanBottomSheet({
    super.key,
    required this.onScanComplete,
  });

  @override
  State<SignerScanBottomSheet> createState() => _SignerScanBottomSheetState();
}

class _SignerScanBottomSheetState extends State<SignerScanBottomSheet> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.loaderOverlay.show();
      Future.delayed(const Duration(milliseconds: 1000), () {
        // fixme 추후 QRCodeScanner가 개선되면 QRCodeScanner 의 카메라 뷰 생성 완료된 콜백 찾아 progress hide 합니다. 현재는 1초 후 hide
        if (mounted) {
          context.loaderOverlay.hide();
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future onCompleteScanning(String psbtBase64) async {
    if (_isProcessing) return;
    _isProcessing = true;

    vibrateLight();

    controller?.pauseCamera();
    await _stopCamera();

    _isProcessing = false;
    if (mounted) {
      widget.onScanComplete.call(psbtBase64);
      Navigator.pop(context);
    }
  }

  void onFailedScanning(String message) {
    if (_isProcessing) return;
    _isProcessing = true;

    String errorMessage;
    if (message.contains('Invalid Scheme')) {
      errorMessage = t.errors.invalid_sign_error;
    } else {
      errorMessage = t.errors.scan_error(error: message);
    }

    showAlertDialog(
        context: context,
        content: errorMessage,
        onConfirmPressed: () {
          _isProcessing = false;
        });
  }

  Future<void> _stopCamera() async {
    if (controller != null) {
      await controller?.pauseCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoadingOverlay(
      child: ClipRRect(
        borderRadius: CoconutBorder.boxDecorationRadius,
        child: Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CustomAppBar.build(
            title: t.signer_scanner_bottom_sheet.title,
            context: context,
            hasRightIcon: false,
            isBottom: true,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Container(
                  color: CoconutColors.white,
                  child: AnimatedQrScanner(
                    setQRViewController: (QRViewController qrViewcontroller) {
                      controller = qrViewcontroller;
                    },
                    onComplete: onCompleteScanning,
                    onFailed: onFailedScanning,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CustomTooltip(
                    richText: RichText(
                      text: TextSpan(
                        text: '',
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
                            text: t.signer_scanner_bottom_sheet.guide,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
