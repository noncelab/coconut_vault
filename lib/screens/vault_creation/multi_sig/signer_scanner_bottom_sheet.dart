import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_scanner.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class SignerScannerBottomSheet extends StatefulWidget {
  final Function onScanComplete;
  const SignerScannerBottomSheet({
    super.key,
    required this.onScanComplete,
  });

  @override
  State<SignerScannerBottomSheet> createState() =>
      _SignerScannerBottomSheetState();
}

class _SignerScannerBottomSheetState extends State<SignerScannerBottomSheet> {
  late AppModel _appModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;

  @override
  void initState() {
    _appModel = Provider.of<AppModel>(context, listen: false);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _appModel.showIndicator();
      await Future.delayed(const Duration(milliseconds: 1000));
      // fixme 추후 QRCodeScanner가 개선되면 QRCodeScanner 의 카메라 뷰 생성 완료된 콜백 찾아 progress hide 합니다. 현재는 1초 후 hide
      _appModel.hideIndicator();
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
    return ClipRRect(
      borderRadius: MyBorder.boxDecorationRadius,
      child: Scaffold(
        backgroundColor: Colors.white,
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
                color: MyColors.white,
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
                        color: MyColors.black,
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
              Visibility(
                visible: _appModel.isLoading,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration:
                      const BoxDecoration(color: MyColors.transparentBlack_30),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: MyColors.darkgrey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
