import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
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
    _signerBsmsQrDataHandler = SignerBsmsQrDataHandler(harewareWalletType: widget.hardwareWalletType);
  }

  @override
  bool get useBottomAppBar => true;

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
          scanResult = MultisigNormalizer.fromUrResult(result as Map<dynamic, dynamic>);
          break;
        case HardwareWalletType.jade:
          scanResult = MultisigNormalizer.fromUrResult(result as Map<dynamic, dynamic>);
          break;
        case HardwareWalletType.coldcard:
          scanResult = MultisigNormalizer.fromBbQrResult(result);
          break;
        case HardwareWalletType.seedSigner:
          scanResult = MultisigNormalizer.fromTextResult(result);
          break;
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

  @override
  List<TextSpan> buildTooltipRichText(BuildContext context, VisibilityProvider visibilityProvider) {
    final String languageCode = t.$meta.locale.languageCode;
    final bool isReversedOrder = languageCode == 'en';

    TextSpan buildTextSpan(String text, {bool isBold = false}) {
      return TextSpan(
        text: text,
        style: CoconutTypography.body2_14.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: CoconutColors.black,
        ),
      );
    }

    TextSpan buildStep(String index, String target, String action, {String? suffix}) {
      List<TextSpan> children = [];

      children.add(buildTextSpan(index));

      if (isReversedOrder) {
        children.add(buildTextSpan('$action '));
        children.add(buildTextSpan(target, isBold: true));
      } else {
        children.add(buildTextSpan('$target ', isBold: true));
        children.add(buildTextSpan(action));
      }

      if (suffix != null) {
        children.add(buildTextSpan(suffix));
      }

      return TextSpan(children: children);
    }

    switch (widget.hardwareWalletType) {
      case HardwareWalletType.keystone3Pro:
        return [
          TextSpan(
            text: '${t.bsms_scanner_screen.keystone3pro.guide2_1}\n',
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildStep('1. ', t.bsms_scanner_screen.keystone3pro.guide2_3, t.bsms_scanner_screen.select, suffix: null),
              buildTextSpan('\n'),
              buildStep('2. ', t.bsms_scanner_screen.keystone3pro.guide2_4, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('3. ', t.bsms_scanner_screen.keystone3pro.guide2_5, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('4. '),
              if (isReversedOrder) ...[
                buildTextSpan('${t.bsms_scanner_screen.keystone3pro.guide2_7} '),
                buildTextSpan(t.bsms_scanner_screen.keystone3pro.guide2_6, isBold: true),
              ] else ...[
                buildTextSpan(t.bsms_scanner_screen.keystone3pro.guide2_6, isBold: true),
                buildTextSpan(t.bsms_scanner_screen.keystone3pro.guide2_7),
              ],
            ],
          ),
        ];

      case HardwareWalletType.seedSigner:
        return [
          TextSpan(
            text: '${t.bsms_scanner_screen.seedsigner.guide2_1}\n',
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildStep('1. ', t.bsms_scanner_screen.seedsigner.guide2_2, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('2. ', t.bsms_scanner_screen.seedsigner.guide2_3, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('3. ', t.bsms_scanner_screen.seedsigner.guide2_4, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('4. '),
              buildTextSpan('${t.bsms_scanner_screen.seedsigner.guide2_5} '),
              buildTextSpan(t.bsms_scanner_screen.seedsigner.guide2_6, isBold: true),
            ],
          ),
        ];

      case HardwareWalletType.jade:
        return [
          TextSpan(
            text: null,
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              if (isReversedOrder) ...[
                buildTextSpan('${t.bsms_scanner_screen.jade.guide2_1} '),
                buildTextSpan(t.bsms_scanner_screen.jade.guide2_2, isBold: true),
              ] else ...[
                buildTextSpan(t.bsms_scanner_screen.jade.guide2_1, isBold: true),
                buildTextSpan(t.bsms_scanner_screen.jade.guide2_2),
              ],
              buildTextSpan('\n'),
              buildStep('1. ', t.bsms_scanner_screen.jade.guide2_3, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('2. ', t.bsms_scanner_screen.jade.guide2_4, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('3. ', t.bsms_scanner_screen.jade.guide2_5, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('4. ', t.bsms_scanner_screen.jade.guide2_6, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('5. '),
              if (isReversedOrder) ...[
                buildTextSpan('${t.bsms_scanner_screen.jade.guide2_8} '),
                buildTextSpan(t.bsms_scanner_screen.jade.guide2_7, isBold: true),
              ] else ...[
                buildTextSpan(t.bsms_scanner_screen.jade.guide2_7, isBold: true),
                buildTextSpan(t.bsms_scanner_screen.jade.guide2_8),
              ],
            ],
          ),
        ];

      case HardwareWalletType.coldcard:
        final pressBtn = t.bsms_scanner_screen.press_button;
        return [
          TextSpan(
            text: null,
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildStep('1. ', t.bsms_scanner_screen.cold_card.guide2_1, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('2. ', t.bsms_scanner_screen.cold_card.guide2_2, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('3. ', t.bsms_scanner_screen.cold_card.guide2_3, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('4. ', t.bsms_scanner_screen.cold_card.guide2_4, pressBtn),
              buildTextSpan('\n'),
              buildStep('5. ', t.bsms_scanner_screen.cold_card.guide2_5, pressBtn),
              buildTextSpan('\n'),
              buildStep('6. ', t.bsms_scanner_screen.cold_card.guide2_6, pressBtn),
            ],
          ),
        ];

      case HardwareWalletType.krux:
        return [
          TextSpan(
            text: '${t.bsms_scanner_screen.krux.guide2_1}\n',
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildTextSpan('1. '),
              if (isReversedOrder) ...[
                buildTextSpan('${t.bsms_scanner_screen.krux.guide2_2} '),
                buildTextSpan('${t.bsms_scanner_screen.select} '),
                buildTextSpan(t.bsms_scanner_screen.krux.guide2_3, isBold: true),
              ] else ...[
                buildTextSpan(t.bsms_scanner_screen.krux.guide2_2),
                buildTextSpan(t.bsms_scanner_screen.krux.guide2_3, isBold: true),
                buildTextSpan(t.bsms_scanner_screen.select),
              ],
              buildTextSpan('\n'),
              buildStep('2. ', t.bsms_scanner_screen.krux.guide2_4, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('3. '),
              buildTextSpan('${t.bsms_scanner_screen.krux.guide2_5} '),
              buildTextSpan(t.bsms_scanner_screen.krux.guide2_6, isBold: true),
              buildTextSpan('\n'),
              buildStep('4. ', t.bsms_scanner_screen.krux.guide2_7, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildTextSpan('5. '),
              isReversedOrder ? buildTextSpan('${t.bsms_scanner_screen.select} ') : buildTextSpan(''),
              buildTextSpan(t.bsms_scanner_screen.krux.guide2_8, isBold: true),
              !isReversedOrder ? buildTextSpan(t.bsms_scanner_screen.select) : buildTextSpan(''),
            ],
          ),
        ];

      case HardwareWalletType.coconutVault:
      default:
        return [
          TextSpan(
            text: '${t.bsms_scanner_screen.coconut_vault.guide2_1}\n',
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: <TextSpan>[
              buildTextSpan('1. '),
              isReversedOrder ? buildTextSpan('${t.bsms_scanner_screen.select} ') : buildTextSpan(''),
              buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_2),
              !isReversedOrder ? buildTextSpan(t.bsms_scanner_screen.select) : buildTextSpan(''),
              buildTextSpan('\n'),
              buildStep('2. ', t.bsms_scanner_screen.coconut_vault.guide2_3, t.bsms_scanner_screen.select),
              buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_4),
            ],
          ),
        ];
    }
  }
}
