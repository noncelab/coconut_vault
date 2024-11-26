import 'package:coconut_vault/model/state/app_model.dart';
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
      errorMessage = '잘못된 서명 정보에요. 다시 시도해 주세요.';
    } else {
      errorMessage = '[스캔 실패] $message';
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
          title: '서명 업데이트',
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
                    text: const TextSpan(
                      text: '',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.4,
                        letterSpacing: 0.5,
                        color: MyColors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              '다른 볼트에서 서명을 추가했나요? 정보를 업데이트 하기 위해 추가된 서명 트랜잭션의 QR 코드를 스캔해 주세요.',
                          style: TextStyle(
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
