import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// 다중 서명 지갑 생성 시 외부에서 Coordinator BSMS를 스캔하는 화면
class CoordinatorBsmsConfigScannerScreen extends StatefulWidget {
  const CoordinatorBsmsConfigScannerScreen({super.key});

  @override
  State<CoordinatorBsmsConfigScannerScreen> createState() => _CoordinatorBsmsConfigScannerScreenState();
}

class _CoordinatorBsmsConfigScannerScreenState extends BsmsScannerBase<CoordinatorBsmsConfigScannerScreen> {
  static String wrongFormatMessage = t.errors.invalid_multisig_qr_error;

  @override
  bool get showBackButton => true;

  @override
  double get topMaskHeight => 0.0;

  @override
  String get appBarTitle => t.bsms_scanner_screen.import_multisig_wallet;

  // TODO: figma 참고해서 수정 / 일본어 누락
  @override
  List<TextSpan> buildTooltipRichText(BuildContext context, visibilityProvider) {
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
            text: t.bsms_scanner_screen.guide1_1,
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildTextSpan(' ${t.bsms_scanner_screen.guide1_2}'),
              buildTextSpan('\n'),
              buildTextSpan('1. '),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan(t.bsms_scanner_screen.guide1_3, isBold: true),
              buildTextSpan('\n'),
              buildTextSpan('2. '),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan(t.bsms_scanner_screen.guide1_4),
              buildTextSpan('\n'),
              buildTextSpan('3. '),
              buildTextSpan(t.bsms_scanner_screen.guide1_5),
            ],
          ),
        ];
      case 'kr':
      default:
        return [
          TextSpan(
            text: t.bsms_scanner_screen.guide1_1,
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildTextSpan(' ${t.bsms_scanner_screen.guide1_2}'),
              buildTextSpan('\n'),
              buildTextSpan('1. '),
              buildTextSpan(t.bsms_scanner_screen.guide1_3, isBold: true),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('2. '),
              buildTextSpan(t.bsms_scanner_screen.guide1_4),
              buildTextSpan(t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('3. '),
              buildTextSpan(t.bsms_scanner_screen.guide1_5),
            ],
          ),
        ];
    }
  }

  /// 외부 Vault의 Coordinator BSMS를 스캔해서 멀티시그 지갑 복사
  /// TODO: 외부에서 만들어진 Coordinator BSMS를 스캔해서 멀티시그 지갑 생성하는 로직 추가
  @override
  void onBarcodeDetected(BarcodeCapture capture) async {
    controller?.pause();

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
    MultisigImportDetail decodedData;
    String coordinatorBsms;
    Map<String, dynamic> decodedJson;

    try {
      decodedJson = jsonDecode(scanData);
      decodedData = MultisigImportDetail.fromJson(decodedJson);
      coordinatorBsms = decodedData.coordinatorBsms;
      Bsms.parseCoordinator(coordinatorBsms);
    } catch (_) {
      onFailedScanning(wrongFormatMessage);
      return;
    }

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
    }
  }
}
