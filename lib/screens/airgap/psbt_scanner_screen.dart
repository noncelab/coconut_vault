import 'dart:convert';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/extended_public_key_not_found_exception.dart';
import 'package:coconut_vault/model/exception/vault_can_not_sign_exception.dart';
import 'package:coconut_vault/model/exception/vault_not_found_exception.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/animated_qr/coconut_qr_scanner.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/bc_ur_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:ur/ur.dart';
import 'package:cbor/cbor.dart';

class PsbtScannerScreen extends StatefulWidget {
  final int? id;
  final HardwareWalletType? hardwareWalletType;
  const PsbtScannerScreen({super.key, this.id, this.hardwareWalletType});

  @override
  State<PsbtScannerScreen> createState() => _PsbtScannerScreenState();
}

class _PsbtScannerScreenState extends State<PsbtScannerScreen> {
  late PsbtScannerViewModel _viewModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  MobileScannerController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;
  late IQrScanDataHandler _scanDataHandler;

  @override
  void initState() {
    super.initState();
    final shouldResetAll = widget.id == null;
    _viewModel = PsbtScannerViewModel(
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<SignProvider>(context, listen: false),
      shouldResetAll: shouldResetAll,
    );

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

  void _setQRViewController(MobileScannerController qrViewcontroller) {
    controller = qrViewcontroller;
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.errors.scan_error_title,
          description: message,
          backgroundColor: CoconutColors.white,
          leftButtonText: t.cancel,
          rightButtonText: t.confirm,
          rightButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          onTapRight: () {
            _isProcessing = false;
            controller?.start();
            Navigator.pop(context);
          },
        );
      },
    );
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
      } else if (e is ExtendedPublicKeyNotFoundException) {
        await _showErrorDialog(ExtendedPublicKeyNotFoundException.defaultErrorMessage);
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
        Navigator.pushReplacementNamed(context, AppRoutes.psbtConfirmation);
      } else if (Platform.isIOS) {
        Navigator.pushNamed(context, AppRoutes.psbtConfirmation).then((o) {
          // 뒤로가기로 다시 돌아왔을 때
          _isProcessing = false;
          controller?.start();
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
      await controller?.start();
    }
  }

  List<TextSpan> _getGuideTextSpan() {
    final textStyle = CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black);
    final textStyleBold = CoconutTypography.body2_14_Bold.copyWith(height: 1.3, color: CoconutColors.black);
    final hwwType = widget.hardwareWalletType ?? HardwareWalletType.coconutVault;

    final visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);
    final isEnglish = visibilityProvider.language == 'en';

    switch (hwwType) {
      case HardwareWalletType.coconutVault:
        // TODO: 숫자 빼기
        return [
          TextSpan(
            text: '[2] ',
            style: CoconutTypography.body1_16_Bold.copyWith(height: 1.2, color: CoconutColors.black),
          ),
          TextSpan(
            text: widget.id == null ? t.psbt_scanner_screen.guide : t.psbt_scanner_screen.guide_single_sig_same_name,
            style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
          ),
        ];
      case HardwareWalletType.seedSigner:
        return [
          if (isEnglish) ...[
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.confirm_sign_info, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_the_en, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.seed_signer_text1, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.button_en, style: textStyle),
          ] else ...[
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.confirm_sign_info, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.seed_signer_text1, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.click_button, style: textStyle),
          ],
          const TextSpan(text: '\n'),
          TextSpan(
            text: t.psbt_scanner_screen.tooltip.scan_QR_code(name: t.hardware_wallet_type.seedsigner),
            style: textStyle,
          ),
        ];
      case HardwareWalletType.jade:
        return [
          if (isEnglish) ...[
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.confirm_sign_info, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_the_en, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.jade_text1, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.button_en, style: textStyle),
          ] else ...[
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.confirm_sign_info, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.jade_text1, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.click_button, style: textStyle),
          ],
          const TextSpan(text: '\n'),
          TextSpan(
            text: t.psbt_scanner_screen.tooltip.scan_QR_code(name: t.hardware_wallet_type.jade),
            style: textStyle,
          ),
        ];
      case HardwareWalletType.coldcard:
        return [
          if (isEnglish) ...[
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text1, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_the_en, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text2, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.button_en, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_the_en, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text3, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.button_en, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '3. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text4, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_the_en, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text5, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.button_en, style: textStyle),
          ] else ...[
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text1, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text2, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_button, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text3, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_button, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '3. ', style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text4, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.coldcard_text5, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.press_button, style: textStyle),
          ],
          const TextSpan(text: '\n'),
          TextSpan(
            text: t.psbt_scanner_screen.tooltip.scan_QR_code(name: t.hardware_wallet_type.coldcard),
            style: textStyle,
          ),
        ];
      case HardwareWalletType.keystone3Pro:
        return [
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.psbt_scanner_screen.tooltip.confirm_sign_info, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.psbt_scanner_screen.tooltip.keystone_text1, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '3. ', style: textStyle),
          TextSpan(text: t.psbt_scanner_screen.tooltip.keystone_text2, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(
            text: t.psbt_scanner_screen.tooltip.scan_QR_code(name: t.hardware_wallet_type.keystone),
            style: textStyle,
          ),
        ];
      case HardwareWalletType.krux:
        return [
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.psbt_scanner_screen.tooltip.krux_text1, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          if (isEnglish) ...[
            TextSpan(text: t.psbt_scanner_screen.tooltip.krux_text3, style: textStyle),
            TextSpan(text: t.psbt_scanner_screen.tooltip.krux_text2, style: textStyleBold),
          ] else ...[
            TextSpan(text: t.psbt_scanner_screen.tooltip.krux_text2, style: textStyleBold),
            TextSpan(text: t.psbt_scanner_screen.tooltip.krux_text3, style: textStyle),
          ],
          const TextSpan(text: '\n'),
          TextSpan(
            text: t.psbt_scanner_screen.tooltip.scan_QR_code(name: t.hardware_wallet_type.krux),
            style: textStyle,
          ),
        ];
      case HardwareWalletType.auto:
        return [TextSpan(text: t.psbt_scanner_screen.tooltip.auto_text, style: textStyle)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoadingOverlay(
      child: Scaffold(
        appBar: CoconutAppBar.build(title: t.sign, context: context, backgroundColor: CoconutColors.white),
        body: Stack(
          children: [
            Container(
              color: CoconutColors.white,
              child: CoconutQrScanner(
                setQrViewController: _setQRViewController,
                onComplete: _onCompletedScanningForBcUr,
                onFailed: onFailedScanning,
                qrDataHandler: _scanDataHandler,
              ),
            ),
            CustomTooltip.buildInfoTooltip(
              context,
              richText: RichText(text: TextSpan(style: CoconutTypography.body2_14, children: _getGuideTextSpan())),
              isBackgroundWhite: false,
              paddingTop: 20,
            ),
          ],
        ),
      ),
    );
  }
}
