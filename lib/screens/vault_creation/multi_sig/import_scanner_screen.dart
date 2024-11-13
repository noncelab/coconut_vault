import 'dart:convert';
import 'dart:io';

import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ImportScannerScreen extends StatefulWidget {
  const ImportScannerScreen({super.key});

  @override
  State<ImportScannerScreen> createState() => _ImportScannerScreenState();
}

class _ImportScannerScreenState extends State<ImportScannerScreen> {
  late AppModel _appModel;
  late VaultModel _vaultModel;
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
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
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
    _vaultModel.setWaitingForSignaturePsbtBase64(psbtBase64);

    controller?.pauseCamera();
    await _stopCamera();
    if (mounted) {
      Navigator.pop(context);
    }
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
                text: '다른 볼트 앱',
                style: Styles.body1.merge(
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 20.8 / 16,
                    letterSpacing: -0.01,
                  ),
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '의 홈 화면 - 내보내기에서 ',
                    style: Styles.body1.merge(
                      const TextStyle(
                        height: 20.8 / 16,
                        letterSpacing: -0.01,
                      ),
                    ),
                  ),
                  TextSpan(
                    text: '다중 서명 지갑 추가',
                    style: Styles.body1.merge(
                      const TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 20.8 / 16,
                        letterSpacing: -0.01,
                      ),
                    ),
                  ),
                  TextSpan(
                    text: '를 선택해 주세요. 다른 볼트 화면에 나타난 QR 코드를 스캔해 주세요.',
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

      _isProcessing = true;

      Map<String, dynamic> jsonData = jsonDecode(scanData.code!);
      debugPrint(jsonData.toString());

      // TODO: 라이브러리 구현이 되고 나면 pub키를 반환해야 합니다.
      // 현재는 볼트-내보내기와 같은 형식의 QR코드가 아닌이상 에러 발생합니다.
      Navigator.pop(context, jsonData.toString());
    });
  }
}
