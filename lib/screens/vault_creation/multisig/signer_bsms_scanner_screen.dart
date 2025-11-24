import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Signer bsms 및 descriptor 스캐너 화면
class SignerBsmsScannerScreen extends StatefulWidget {
  final int? id;
  // final MultisigBsmsImportType screenType;
  const SignerBsmsScannerScreen({super.key, this.id});

  @override
  State<SignerBsmsScannerScreen> createState() => _SignerBsmsScannerScreenState();
}

class _SignerBsmsScannerScreenState extends BsmsScannerBase<SignerBsmsScannerScreen> {
  static String wrongFormatMessage1 = t.errors.invalid_single_sig_qr_error; // TODO 리네이밍
  static final String networkMismatchMessage = t.errors.invalid_network_type_error;

  @override
  bool get useBottomAppBar => true;

  @override
  double get topMaskHeight => 50.0;

  @override
  String get appBarTitle => t.bsms_scanner_screen.import_bsms; // TODO 문맥에 맞게 바꾸기

  /// 다중서명지갑 생성 시 외부에서 Signer를 스캔합니다.
  @override
  void onBarcodeDetected(BarcodeCapture capture) {
    controller?.pause();

    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final barcode = codes.first;
    if (barcode.rawValue == null) return;

    final scanData = barcode.rawValue!;

    try {
      // Signer 형식이 맞는지 체크
      Bsms.parseSigner(scanData);
    } catch (e) {
      // TODO: 상태에 따른 에러 메시지 처리
      final message = e.toString();
      final isNetworkMismatch = message.contains('Extended public key is not compatible with the network type');

      onFailedScanning(isNetworkMismatch ? networkMismatchMessage : wrongFormatMessage1);
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, scanData);
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
