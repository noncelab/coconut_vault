import 'dart:io';

import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class SignerScannerScreen extends StatefulWidget {
  const SignerScannerScreen({super.key});

  @override
  State<SignerScannerScreen> createState() => _SignerScannerScreenState();
}

class _SignerScannerScreenState extends State<SignerScannerScreen> {
  late AppModel _appModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

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

  void onFailedScanning(String message) {
    if (_isProcessing) return;
    _isProcessing = true;

    String errorMessage;
    if (message.contains('Invalid Scheme')) {
      errorMessage = '잘못된 QR이에요. 다시 시도해 주세요.';
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
    return Stack(
      children: [
        Container(
          color: MyColors.white,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
                borderColor: MyColors.white,
                borderRadius: 8,
                borderLength: (MediaQuery.of(context).size.width < 400 ||
                        MediaQuery.of(context).size.height < 400)
                    ? 160.0
                    : MediaQuery.of(context).size.width * 0.9 / 2,
                borderWidth: 8,
                cutOutSize: (MediaQuery.of(context).size.width < 400 ||
                        MediaQuery.of(context).size.height < 400)
                    ? 320.0
                    : MediaQuery.of(context).size.width * 0.9),
            onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: CustomTooltip(
            richText: RichText(
              text: TextSpan(
                text: '키를 보관 중인 볼트',
                style: Styles.body1.merge(
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 20.8 / 16,
                    letterSpacing: -0.01,
                  ),
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '에서 QR 코드를 생성해야 해요. 홈 화면 - 내보내기 화면에서 ',
                    style: Styles.body1.merge(
                      const TextStyle(
                        height: 20.8 / 16,
                        letterSpacing: -0.01,
                      ),
                    ),
                  ),
                  TextSpan(
                    text: '다른 볼트에서 다중 서명 키로 사용',
                    style: Styles.body1.merge(
                      const TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 20.8 / 16,
                        letterSpacing: -0.01,
                      ),
                    ),
                  ),
                  TextSpan(
                    text: '을 선택해 주세요. 화면에 보이는 QR 코드를 스캔합니다.',
                    style: Styles.body1.merge(
                      const TextStyle(
                        height: 20.8 / 16,
                        letterSpacing: -0.01,
                      ),
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
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 권한이 없습니다.')),
      );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isProcessing || scanData.code == null) return;

      debugPrint(scanData.code!);
      debugPrint(scanData.code!.contains('\n').toString());
      List<String> data = scanData.code!.split('\n');

      if (!scanData.code!.contains('\n') ||
          !data[0].contains('BSMS') ||
          !(data[2].contains('Vpub') ||
              data[2].contains('Xpub') ||
              data[2].contains('Zpub'))) {
        onFailedScanning('Invalid Scheme');
        return;
      }
      _isProcessing = true;

      Navigator.pop(context, scanData.code!);
    });
  }
}
