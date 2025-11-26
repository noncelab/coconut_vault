import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/coordinator_bsms_qr_data_handler.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

// 다중 서명 지갑 생성 시 외부에서 Coordinator BSMS를 스캔하는 화면
class CoordinatorBsmsConfigScannerScreen extends StatefulWidget {
  const CoordinatorBsmsConfigScannerScreen({super.key});

  @override
  State<CoordinatorBsmsConfigScannerScreen> createState() => _CoordinatorBsmsConfigScannerScreenState();
}

class _CoordinatorBsmsConfigScannerScreenState extends BsmsScannerBase<CoordinatorBsmsConfigScannerScreen> {
  static String wrongFormatMessage = t.errors.invalid_multisig_qr_error;
  final CoordinatorBsmsQrDataHandler _coordinatorBsmsQrDataHandler;

  _CoordinatorBsmsConfigScannerScreenState() : _coordinatorBsmsQrDataHandler = CoordinatorBsmsQrDataHandler();

  @override
  bool get showBackButton => true;

  @override
  double get topMaskHeight => 0.0;

  @override
  String get appBarTitle => t.bsms_scanner_screen.import_multisig_wallet;

  @override
  List<TextSpan> buildTooltipRichText(BuildContext context, visibilityProvider) {
    return [
      TextSpan(
        text: t.coordinator_bsms_config_scanner_screen.guide1,
        style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.coordinator_bsms_config_scanner_screen.guide2,
        style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        context: context,
        title: t.bsms_scanner_screen.import_multisig_wallet,
        backgroundColor: CoconutColors.white,
      ),
      body: Stack(
        children: [
          _buildBSMSView(context),
          CustomTooltip.buildInfoTooltip(
            context,
            richText: RichText(
              text: TextSpan(
                style: CoconutTypography.body2_14,
                children: buildTooltipRichText(context, visibilityProvider),
              ),
            ),
            isBackgroundWhite: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBSMSView(BuildContext context) {
    var scanArea =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
            ? 320.0
            : MediaQuery.of(context).size.width * 0.85;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        overlayColor: CoconutColors.black.withValues(alpha: 0.45),
        borderColor: CoconutColors.white,
        borderRadius: 10,
        borderLength: scanArea * 0.5,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    // setState(() {
    //   this.controller = controller;
    // });
    // var words = <String>[];
    // controller.scannedDataStream.listen((scanData) {
    //   if (_isNavigating) return;

    //   try {
    //     if (scanData.code == null && scanData.rawBytes != null) {
    //       words = _decodeCompactQR(scanData.rawBytes!);
    //     } else if (scanData.code != null && scanData.rawBytes != null) {
    //       words = _decodeStandardQR(scanData.code!);
    //     }
    //   } catch (e) {
    //     if (e is FormatException && e.message.contains('Invalid radix-10 number')) {
    //       words = _decodeCompactQR(scanData.rawBytes!);
    //     } else {
    //       if (mounted) {
    //         showDialog(
    //           context: context,
    //           builder: (context) {
    //             return CoconutPopup(
    //               title: t.seed_qr_import_screen.error_title,
    //               description: '${t.seed_qr_import_screen.error_message}: $e',
    //               onTapRight: () => Navigator.of(context).pop(),
    //             );
    //           },
    //         );
    //       }
    //       return;
    //     }
    //   }

    //   if (words.length == 12 || words.length == 24) {
    //     if (mounted) {
    //       _isNavigating = true;
    //       // 1. 네비게이션하기 전 카메라 끄기
    //       controller.pauseCamera();
    //       Navigator.push(
    //         context,
    //         MaterialPageRoute(
    //           builder: (context) => SeedQrConfirmationScreen(scannedData: utf8.encode(words.join(' '))),
    //         ),
    //       ).then((_) {
    //         // 2. 돌아왔을 때 카메라 재개하기
    //         if (mounted) {
    //           controller.resumeCamera();
    //         }
    //         setState(() {
    //           _isNavigating = false;
    //         });
    //       });
    //     }
    //   }
    // });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    // _appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
  }

  /// 외부 Vault의 Coordinator BSMS를 스캔해서 멀티시그 지갑 복사
  /// TODO: 외부에서 만들어진 Coordinator BSMS를 스캔해서 멀티시그 지갑 생성하는 로직 추가
  @override
  void onBarcodeDetected(BarcodeCapture capture) async {
    final codes = capture.barcodes;
    if (codes.isEmpty) {
      setState(() => isProcessing = false);
      return;
    }

    final barcode = codes.first;
    if (barcode.rawValue == null) {
      setState(() => isProcessing = false);
      return;
    }

    final scanData = barcode.rawValue!;
    _coordinatorBsmsQrDataHandler.joinData(scanData);
    if (!_coordinatorBsmsQrDataHandler.isCompleted()) {
      setState(() => isProcessing = false);
      return;
    }

    controller?.pause();

    final result = _coordinatorBsmsQrDataHandler.result;

    if (result == null) {
      onFailedScanning(wrongFormatMessage);
      setState(() => isProcessing = false);
      return;
    }

    final normalizedMultisigConfig = MultisigNormalizer.fromCoordinatorResult(result);
    Logger.log(
      '\t normalizedMultisigConfig: \n name: ${normalizedMultisigConfig.name}\n requiredCount: ${normalizedMultisigConfig.requiredCount}\n signerBsms: [\n${normalizedMultisigConfig.signerBsms.join(',\n')}\n]',
    );

    // if (walletProvider.findMultisigWalletByCoordinatorBsms(coordinatorBsms) != null) {
    //   onFailedScanning(t.errors.duplicate_multisig_registered_error);
    //   return;
    // }

    try {
      // 이 화면이 어느 Vault에 속한 건지에 대한 id는
      // 라우팅 아규먼트나 Provider 등으로 주입해야 함.
      // 예시로 id를 arguments에서 꺼낸다고 가정:
      // final args = ModalRoute.of(context)!.settings.arguments as VaultHomeNavArgs;
      // final vault = await walletProvider.importMultisigVault(decodedData, args.vaultId);

      // assert(walletProvider.isAddVaultCompleted);

      // if (!mounted) return;
      // Navigator.pushNamedAndRemoveUntil(
      //   context,
      //   '/',
      //   (Route<dynamic> route) => false,
      //   arguments: VaultHomeNavArgs(addedWalletId: vault.id),
      // );
    } catch (e) {
      if (e is NotRelatedMultisigWalletException) {
        onFailedScanning(e.message);
        return;
      }
      onFailedScanning(e.toString());
      controller?.start();
    }
  }
}
