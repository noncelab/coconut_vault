import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/signer_bsms_qr_data_handler.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

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
  static final String networkMismatchMessage = t.errors.invalid_network_type_error;
  late final SignerBsmsQrDataHandler _qrDataHandler;
  bool _isFirstScanData = true;

  @override
  void initState() {
    super.initState();
    _qrDataHandler = SignerBsmsQrDataHandler(harewareWalletType: widget.hardwareWalletType);
  }

  @override
  bool get useBottomAppBar => true;

  @override
  String get appBarTitle => widget.hardwareWalletType!.displayName;

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
    SignerBsms? signerBsms;
    String? scanResult;

    try {
      if (_isFirstScanData) {
        if (!_qrDataHandler.validateFormat(scanData)) {
          onFailedScanning(wrongFormatMessage);
          return;
        }
        _isFirstScanData = false;
      }

      final joinResult = _qrDataHandler.joinData(scanData);
      if (joinResult == false && !_qrDataHandler.isFragmentedDataScanned) {
        //_qrDataHandler.reset();
        onFailedScanning(wrongFormatMessage);
        return;
      }

      if (!_qrDataHandler.isCompleted()) {
        //setState(() => isProcessing = false);
        return;
      }

      setState(() => isProcessing = true);
      controller?.pause();

      final result = _qrDataHandler.result;
      if (result == null) {
        onFailedScanning(wrongFormatMessage);
        return;
      }

      Logger.log('--> SignerBsmsScannerScreen: result: $result');

      switch (widget.hardwareWalletType) {
        case HardwareWalletType.coconutVault:
          Bsms.parseSigner(result);
          scanResult = scanData;
          break;
        case HardwareWalletType.keystone3Pro:
        case HardwareWalletType.jade:
          scanResult = MultisigNormalizer.signerBsmsFromUrResult(result as Map<dynamic, dynamic>);
          break;
        case HardwareWalletType.coldcard:
          scanResult = MultisigNormalizer.signerBsmsFromBbQr(result);
          break;
        case HardwareWalletType.seedSigner:
        case HardwareWalletType.krux:
          scanResult = MultisigNormalizer.signerBsmsFromKeyInfo(result);
          break;
        default:
          throw UnimplementedError('missed hardware type: ${widget.hardwareWalletType}');
      }
    } catch (e) {
      if (e is UnimplementedError) rethrow;
      if (e is NetworkMismatchException) {
        onFailedScanning(
          NetworkType.currentNetworkType.isTestnet
              ? t.alert.bsms_network_mismatch.description_when_testnet
              : t.alert.bsms_network_mismatch.description_when_mainnet,
        );
        return;
      }

      final isNetworkMismatch = e.toString().contains('Extended public key is not compatible with the network type');
      onFailedScanning(isNetworkMismatch ? networkMismatchMessage : wrongFormatMessage);
      return;
    }

    try {
      signerBsms = SignerBsms.parse(scanResult);
      Provider.of<WalletProvider>(context, listen: false).validateSignerDerivationPath(signerBsms.derivationPath);
    } catch (e) {
      onFailedScanning(e.toString());
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, signerBsms);
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
