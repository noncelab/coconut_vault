import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/signer_bsms_qr_data_handler.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// 멀티시그 서명 지갑 생성 시 HWW으로부터
// Signer bsms 및 descriptor 정보를 스캔합니다.
class SignerBsmsScannerScreen extends StatefulWidget {
  final int? id;
  final HardwareWalletType? hardwareWalletType;
  const SignerBsmsScannerScreen({super.key, this.id, this.hardwareWalletType = HardwareWalletType.coconutVault});

  @override
  State<SignerBsmsScannerScreen> createState() => _SignerBsmsScannerScreenState();
}

class _SignerBsmsScannerScreenState extends BsmsScannerBase<SignerBsmsScannerScreen> {
  static String wrongFormatMessage1 = t.errors.invalid_single_sig_qr_error; // TODO 리네이밍
  static final String networkMismatchMessage = t.errors.invalid_network_type_error;
  late final SignerBsmsQrDataHandler _signerBsmsQrDataHandler;

  @override
  void initState() {
    super.initState();
    _signerBsmsQrDataHandler = SignerBsmsQrDataHandler(hardwareWalletType: widget.hardwareWalletType);
  }

  @override
  bool get useBottomAppBar => true;

  @override
  double get topMaskHeight => 50.0;

  @override
  String get appBarTitle => widget.hardwareWalletType!.displayName;

  @override
  void onBarcodeDetected(BarcodeCapture capture) {
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
    String? scanResult;

    try {
      _signerBsmsQrDataHandler.joinData(scanData);
      if (!_signerBsmsQrDataHandler.isCompleted()) {
        setState(() => isProcessing = false);
        return;
      }

      controller?.pause();

      final result = _signerBsmsQrDataHandler.result;
      if (result == null) {
        onFailedScanning(wrongFormatMessage1);
        setState(() => isProcessing = false);
        return;
      }

      Logger.log('--> SignerBsmsScannerScreen: result: $result');

      switch (widget.hardwareWalletType) {
        case HardwareWalletType.coconutVault:
          Bsms.parseSigner(scanData);
          scanResult = scanData;
          break;
        case HardwareWalletType.keystone3Pro:
        case HardwareWalletType.jade:
          scanResult = MultisigNormalizer.fromUrResult(result as Map<dynamic, dynamic>);
          break;
        case HardwareWalletType.coldcard:
          scanResult = MultisigNormalizer.fromBbQrResult(result);
          break;
        case HardwareWalletType.seedSigner:
        case HardwareWalletType.krux:
          scanResult = MultisigNormalizer.fromTextResult(result);
          break;
        default:
          break;
      }
    } catch (e) {
      // TODO: 상태에 따른 에러 메시지 처리
      final message = e.toString();
      Logger.log('--> SignerBsmsScannerScreen: message: $message');
      final isNetworkMismatch = message.contains('Extended public key is not compatible with the network type');

      onFailedScanning(isNetworkMismatch ? networkMismatchMessage : wrongFormatMessage1);
      return;
    }

    if (!mounted) return;
    // TODO: bsms 정보로 반환하기
    Logger.log('--> scanResult: $scanResult');
    Navigator.pop(context, scanResult);
    return;
  }

  // TODO: figma 참고해서 수정 / 일본어 누락
  @override
  List<TextSpan> buildTooltipRichText(BuildContext context, VisibilityProvider visibilityProvider) {
    TextSpan buildTextSpan(String text, {bool isBold = false}) {
      return TextSpan(
        text: text,
        style: CoconutTypography.body2_14.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: CoconutColors.black,
        ),
      );
    }

    switch (visibilityProvider.language) {
      case 'en':
        return [
          TextSpan(
            text: t.bsms_scanner_screen.guide2_1,
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildTextSpan('\n'),
              buildTextSpan('1. '),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan(t.bsms_scanner_screen.guide2_2),
              buildTextSpan('\n'),
              buildTextSpan('2. '),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan(t.bsms_scanner_screen.guide2_3, isBold: true),
              buildTextSpan('\n'),
              buildTextSpan(t.bsms_scanner_screen.guide2_4),
            ],
          ),
        ];
      case 'kr':
      default:
        return [
          TextSpan(
            text: t.bsms_scanner_screen.guide2_1,
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildTextSpan('\n'),
              buildTextSpan('1. '),
              buildTextSpan(t.bsms_scanner_screen.guide2_2),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('2. '),
              buildTextSpan(t.bsms_scanner_screen.guide2_3, isBold: true),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan(t.bsms_scanner_screen.guide2_4),
            ],
          ),
        ];
    }
  }
}
