import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/taproot_descriptor_qr_data_handler.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TaprootScannerScreen extends StatefulWidget {
  final int? id;
  final HardwareWalletType? hardwareWalletType;
  final Widget? topGuideWidget;
  final bool Function(TaprootVault)? onTaprootVaultScanned;
  final bool hasAppbar;
  final bool useCloseButton;

  const TaprootScannerScreen({
    super.key,
    this.id,
    this.hardwareWalletType = HardwareWalletType.coconutVault,
    this.topGuideWidget,
    this.onTaprootVaultScanned,
    this.hasAppbar = true,
    this.useCloseButton = false,
  });

  @override
  State<TaprootScannerScreen> createState() => _TaprootScannerScreenState();
}

class _TaprootScannerScreenState extends BsmsScannerBase<TaprootScannerScreen> {
  final TaprootDescriptorQrDataHandler _qrDataHandler = TaprootDescriptorQrDataHandler();

  @override
  void initState() {
    super.initState();
    if (_qrDataHandler.isFragmentedDataScanned) {
      showProgressBar = true;
    }
  }

  @override
  bool get useBottomAppBar => true;

  @override
  bool get showAppBar => widget.hasAppbar;

  @override
  bool get showBackButton => !widget.useCloseButton;

  @override
  String get appBarTitle => widget.hardwareWalletType!.displayName;

  @override
  Widget? buildTopGuideWidget(BuildContext context) => widget.topGuideWidget;

  @override
  Future<void> onFailedScanning(String message) async {
    await super.onFailedScanning(message);
    await _restartScanner();
  }

  @override
  void onBarcodeDetected(BarcodeCapture capture) async {
    final codes = capture.barcodes;
    if (codes.isEmpty) {
      return;
    }
    final barcode = codes.first;
    if (barcode.rawValue == null) {
      return;
    }

    final scanData = barcode.rawValue!;
    Logger.log('--> TaprootScannerScreen: detected raw data: $scanData');

    if (!_qrDataHandler.validateFormat(scanData)) {
      _handleScanFailure(wrongFormatMessage);
      return;
    }

    final joinResult = _qrDataHandler.joinData(scanData);
    if (!joinResult) {
      _handleScanFailure(wrongFormatMessage);
      return;
    }

    if (!_qrDataHandler.isCompleted()) {
      return;
    }

    setState(() => isProcessing = true);
    final descriptor = _qrDataHandler.result;
    if (descriptor == null) {
      _handleScanFailure(wrongFormatMessage);
      return;
    }

    final beneficiaryVault = TaprootVault.fromDescriptor(descriptor);
    if (!mounted) return;
    final onTaprootVaultScanned = widget.onTaprootVaultScanned;
    if (onTaprootVaultScanned != null) {
      final didHandleScan = onTaprootVaultScanned(beneficiaryVault);
      if (!didHandleScan && mounted) {
        setState(() => isProcessing = false);
      }
    } else {
      Navigator.pop(context, beneficiaryVault);
    }
  }

  void _handleScanFailure(String message) {
    _qrDataHandler.reset();

    if (_qrDataHandler.isFragmentedDataScanned) {
      updateScanProgress(_qrDataHandler.progress);
    }

    onFailedScanning(message);
  }

  Future<void> _restartScanner() async {
    if (!mounted) {
      return;
    }

    try {
      await controller?.stop();
      if (!mounted) {
        return;
      }
      await controller?.start();
    } catch (e) {
      debugPrint('Taproot scanner restart failed: $e');
    }
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

    final kruxNetworkGuide =
        NetworkType.currentNetworkType.isTestnet
            ? t.bsms_scanner_screen.krux.guide2_7_regtest
            : t.bsms_scanner_screen.krux.guide2_7;

    switch (widget.hardwareWalletType) {
      case HardwareWalletType.keystone:
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

      case HardwareWalletType.coldCard:
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
              buildStep('1. ', t.bsms_scanner_screen.krux.guide2_2, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('2. ', t.bsms_scanner_screen.krux.guide2_3, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('3. ', t.bsms_scanner_screen.krux.guide2_4, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep('4. ', t.bsms_scanner_screen.krux.guide2_5, t.bsms_scanner_screen.select),
              buildTextSpan('\n'),
              buildStep(
                '5. ',
                '${t.bsms_scanner_screen.krux.guide2_6} → $kruxNetworkGuide',
                t.bsms_scanner_screen.select,
              ),
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
