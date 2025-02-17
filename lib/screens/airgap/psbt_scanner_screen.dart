import 'dart:io';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_scanner.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class PsbtScannerScreen extends StatefulWidget {
  final int id;

  const PsbtScannerScreen({super.key, required this.id});

  @override
  State<PsbtScannerScreen> createState() => _PsbtScannerScreenState();
}

class _PsbtScannerScreenState extends State<PsbtScannerScreen> {
  late WalletProvider _vaultModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late VaultListItemBase _vaultListItem;

  QRViewController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;
  bool _isMultisig = false;

  @override
  void initState() {
    _vaultModel = Provider.of<WalletProvider>(context, listen: false);
    super.initState();
    _vaultListItem = _vaultModel.getVaultById(widget.id);
    _isMultisig = _vaultListItem.vaultType == WalletType.multiSignature;
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

  void showError(String message) {
    showAlertDialog(
        context: context,
        content: message,
        onConfirmPressed: () {
          _isProcessing = false;
          controller!.resumeCamera();
        });
  }

  Future onCompleteScanning(String psbtBase64) async {
    await _stopCamera();
    if (_isProcessing) return;
    _isProcessing = true;

    if (!await _vaultListItem.canSign(psbtBase64)) {
      vibrateLight();
      showError(t.errors.cannot_sign_error);
      return;
    }

    vibrateLight();
    _vaultModel.setWaitingForSignaturePsbtBase64(psbtBase64);

    if (mounted) {
      /// Go-router 제거 이후로 ios에서는 정상 작동하지만 안드로이드에서는 pushNamed로 화면 이동 시 카메라 컨트롤러 남아있는 이슈
      if (Platform.isAndroid) {
        Navigator.pushReplacementNamed(context, AppRoutes.psbtConfirmation,
            arguments: {'id': widget.id});
      } else if (Platform.isIOS) {
        Navigator.pushNamed(context, AppRoutes.psbtConfirmation,
            arguments: {'id': widget.id}).then((o) {
          // 뒤로가기로 다시 돌아왔을 때
          _isProcessing = false;
          controller?.resumeCamera();
        });
      }
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

    showError(errorMessage);
  }

  Future<void> _stopCamera() async {
    if (controller != null) {
      await controller?.pauseCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoadingOverlay(
      child: Scaffold(
        appBar: CustomAppBar.build(
          title: _vaultListItem.name,
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
                            ? t.psbt_scanner_screen.guide_multisig
                            : t.psbt_scanner_screen.guide_singlesig,
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
    );
  }
}
