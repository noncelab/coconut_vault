import 'dart:convert';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/widgets/animated_qr/coconut_qr_scanner.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/bc_ur_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:ur/ur.dart';
import 'package:cbor/cbor.dart';

class PsbtScannerScreen extends StatefulWidget {
  final int? id;
  const PsbtScannerScreen({super.key, this.id});

  @override
  State<PsbtScannerScreen> createState() => _PsbtScannerScreenState();
}

class _PsbtScannerScreenState extends State<PsbtScannerScreen> {
  late PsbtScannerViewModel _viewModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;
  late IQrScanDataHandler _scanDataHandler;

  @override
  void initState() {
    super.initState();
    _viewModel = PsbtScannerViewModel(Provider.of<WalletProvider>(context, listen: false),
        Provider.of<SignProvider>(context, listen: false));

    _scanDataHandler = BcUrQrScanDataHandler();
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

  void _setQRViewController(QRViewController qrViewcontroller) {
    controller = qrViewcontroller;
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return CoconutPopup(
            insetPadding:
                EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
            title: t.errors.scan_error_title,
            titleTextStyle: CoconutTypography.body1_16_Bold,
            description: message,
            descriptionTextStyle: CoconutTypography.body2_14,
            backgroundColor: CoconutColors.white,
            rightButtonText: t.confirm,
            rightButtonColor: CoconutColors.black.withOpacity(0.7),
            rightButtonTextStyle: CoconutTypography.body2_14.merge(
              const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            onTapRight: () {
              _isProcessing = false;
              controller!.resumeCamera();
              Navigator.pop(context);
            },
          );
        });
  }

  Future<void> _onCompletedScanningForBcUr(dynamic signedPsbt) async {
    assert(signedPsbt is UR);
    await stopCamera();

    if (_isProcessing) return;
    _isProcessing = true;

    String psbtBase64;
    try {
      final ur = signedPsbt as UR;
      final cborBytes = ur.cbor;
      final decodedCbor = cbor.decode(cborBytes) as CborBytes;

      psbtBase64 = base64Encode(decodedCbor.bytes);

      if (widget.id == null) {
        // 스캔된 MFP를 이용해 유효한 볼트를 찾고, SignProvider에 저장
        await _viewModel.setMatchingVault(psbtBase64);
      } else {
        // id를 이용해 특정 지갑에 대해 psbt 파싱
        await _viewModel.parseBase64EncodedToPsbt(widget.id!, psbtBase64);
      }
    } catch (e) {
      vibrateExtraLightDouble();
      if (e is VaultNotFoundException) {
        await _showErrorDialog(VaultNotFoundException.defaultErrorMessage);
      } else if (e is VaultSigningNotAllowedException) {
        await _showErrorDialog(VaultSigningNotAllowedException.defaultErrorMessage);
      } else {
        await _showErrorDialog(t.errors.invalid_qr);
      }
      return;
    }

    vibrateLight();
    _viewModel.saveUnsignedPsbt(psbtBase64);

    if (mounted) {
      /// Go-router 제거 이후로 ios에서는 정상 작동하지만 안드로이드에서는 pushNamed로 화면 이동 시 카메라 컨트롤러 남아있는 이슈
      if (Platform.isAndroid) {
        Navigator.pushReplacementNamed(context, AppRoutes.psbtConfirmation,
            arguments: {'id': 0}); // TODO id 추가
      } else if (Platform.isIOS) {
        Navigator.pushNamed(context, AppRoutes.psbtConfirmation, arguments: {'id': 0}) // TODO id 추가
            .then((o) {
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

    _showErrorDialog(errorMessage);
  }

  Future<void> stopCamera() async {
    if (controller != null) {
      await controller?.pauseCamera();
    }
  }

  List<TextSpan> _getGuideTextSpan() {
    return [
      TextSpan(
        text: '[2] ',
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1, color: CoconutColors.black),
      ),
      TextSpan(
        text: widget.id == null
            ? t.psbt_scanner_screen.guide_single_sig
            : t.psbt_scanner_screen.guide_single_sig_same_name,
        // TODO 툴팁에 표시할 문구 수정 필요(멀티시그, 싱글시그 구분)
        // text: _viewModel.isMultisig
        // ? t.psbt_scanner_screen.guide_multisig
        // : t.psbt_scanner_screen.guide_single_sig,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoadingOverlay(
      child: Scaffold(
        appBar: CoconutAppBar.build(
          title: t.sign,
          context: context,
          backgroundColor: CoconutColors.white,
        ),
        body: Stack(
          children: [
            Container(
                color: CoconutColors.white,
                child: CoconutQrScanner(
                    setQrViewController: _setQRViewController,
                    onComplete: _onCompletedScanningForBcUr,
                    onFailed: onFailedScanning,
                    qrDataHandler: _scanDataHandler)),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: CoconutToolTip(
                backgroundColor: CoconutColors.gray100,
                borderColor: CoconutColors.gray400,
                icon: SvgPicture.asset(
                  'assets/svg/circle-info.svg',
                  colorFilter: const ColorFilter.mode(
                    CoconutColors.black,
                    BlendMode.srcIn,
                  ),
                ),
                tooltipType: CoconutTooltipType.fixed,
                richText: RichText(
                  text: TextSpan(
                    style: CoconutTypography.body3_12,
                    children: _getGuideTextSpan(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
