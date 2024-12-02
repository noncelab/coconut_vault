import 'dart:io';

import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class PsbtScannerScreen extends StatefulWidget {
  final int id;

  const PsbtScannerScreen({super.key, required this.id});

  @override
  State<PsbtScannerScreen> createState() => _PsbtScannerScreenState();
}

class _PsbtScannerScreenState extends State<PsbtScannerScreen> {
  late AppModel _appModel;
  late VaultModel _vaultModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late VaultListItemBase _vaultListItem;

  QRViewController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;
  bool _isMultisig = false;

  @override
  void initState() {
    _appModel = Provider.of<AppModel>(context, listen: false);
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    _vaultListItem = _vaultModel.getVaultById(widget.id);
    _isMultisig = _vaultListItem.vaultType == VaultType.multiSignature;
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
      /// Go-router 제거 이후로 ios에서는 정상 작동하지만 안드로이드에서는 pushNamed로 화면 이동 시 카메라 컨트롤러 남아있는 이슈
      if (Platform.isAndroid) {
        Navigator.pushReplacementNamed(context, "/psbt-confirmation",
            arguments: {'id': widget.id});
      } else if (Platform.isIOS) {
        Navigator.pushNamed(context, "/psbt-confirmation",
            arguments: {'id': widget.id}).then((o) {
          // 뒤로가기로 다시 돌아왔을 때
          _isProcessing = false;
        });
      }
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
  void didUpdateWidget(covariant PsbtScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 현재의 라우트 경로를 가져옴
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != null && currentRoute.startsWith('/psbt-scanner')) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(
        title: TextUtils.replaceNewlineWithSpace(_vaultListItem.name),
        context: context,
        hasRightIcon: false,
        isBottom: true,
      ),
      body: Stack(
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
                  text: '[2] ',
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
                      text: _isMultisig
                          ? '월렛에서 만든 보내기 정보 또는 외부 볼트에서 다중 서명 중인 정보를 스캔해주세요.'
                          : '월렛에서 만든 보내기 정보를 스캔해 주세요. 반드시 지갑 이름이 같아야 해요.',
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
    );
  }
}
