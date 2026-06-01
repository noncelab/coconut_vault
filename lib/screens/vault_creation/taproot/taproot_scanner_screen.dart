import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/common/qr_scanner_screen_base.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/taproot_descriptor_qr_data_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/taproot_wallet_sync_qr_data_handler.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum TaprootScannerDataType { descriptor, walletSync }

class TaprootScannerScreen extends StatefulWidget {
  final Widget? topGuideWidget;
  final FutureOr<bool> Function(TaprootVault)? onTaprootVaultScanned;
  final FutureOr<bool> Function(TaprootWalletSyncData)? onWalletSyncScanned;
  final bool useCloseButton;
  final TaprootScannerDataType dataType;

  const TaprootScannerScreen({
    super.key,
    this.topGuideWidget,
    this.onTaprootVaultScanned,
    this.onWalletSyncScanned,
    this.useCloseButton = false,
    this.dataType = TaprootScannerDataType.descriptor,
  });

  @override
  State<TaprootScannerScreen> createState() => _TaprootScannerScreenState();
}

class _TaprootScannerScreenState extends QrScannerScreenBase<TaprootScannerScreen> {
  final TaprootDescriptorQrDataHandler _descriptorQrDataHandler = TaprootDescriptorQrDataHandler();
  final TaprootWalletSyncQrDataHandler _walletSyncQrDataHandler = TaprootWalletSyncQrDataHandler();

  IQrScanDataHandler get _qrDataHandler {
    return switch (widget.dataType) {
      TaprootScannerDataType.descriptor => _descriptorQrDataHandler,
      TaprootScannerDataType.walletSync => _walletSyncQrDataHandler,
    };
  }

  bool get _isFragmentedDataScanned {
    return switch (widget.dataType) {
      TaprootScannerDataType.descriptor => _descriptorQrDataHandler.isFragmentedDataScanned,
      TaprootScannerDataType.walletSync => _walletSyncQrDataHandler.isFragmentedDataScanned,
    };
  }

  @override
  void initState() {
    super.initState();
    if (_isFragmentedDataScanned) {
      showProgressBar = true;
    }
  }

  @override
  bool get useBottomAppBar => true;

  @override
  bool get showAppBar => false;

  @override
  bool get showBackButton => !widget.useCloseButton;

  @override
  String get appBarTitle => '';

  @override
  String get wrongFormatPromptMessage {
    return switch (widget.dataType) {
      TaprootScannerDataType.descriptor => super.wrongFormatPromptMessage,
      TaprootScannerDataType.walletSync => t.taproot.taproot_import_screen.step2.invalid_wallet_sync_data,
    };
  }

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
      _handleScanFailure(wrongFormatPromptMessage);
      return;
    }

    final joinResult = _qrDataHandler.joinData(scanData);
    if (!joinResult) {
      _handleScanFailure(wrongFormatPromptMessage);
      return;
    }

    if (!_qrDataHandler.isCompleted()) {
      return;
    }

    setState(() => isProcessing = true);
    final result = _qrDataHandler.result;
    if (result == null) {
      _handleScanFailure(wrongFormatPromptMessage);
      return;
    }

    if (!mounted) return;

    if (result is TaprootWalletSyncData) {
      final onWalletSyncScanned = widget.onWalletSyncScanned;
      if (onWalletSyncScanned != null) {
        final didHandleScan = await onWalletSyncScanned(result);
        if (!didHandleScan && mounted) {
          await _resetScanState();
        }
      } else {
        Navigator.pop(context, result);
      }
      return;
    }

    final beneficiaryVault = TaprootVault.fromDescriptor(result as String);
    final onTaprootVaultScanned = widget.onTaprootVaultScanned;
    if (onTaprootVaultScanned != null) {
      final bool didHandleScan;
      try {
        didHandleScan = await onTaprootVaultScanned(beneficiaryVault);
      } catch (e) {
        _handleScanFailure(e is FormatException ? e.message : wrongFormatMessage);
        return;
      }
      if (!didHandleScan && mounted) {
        await _resetScanState();
      }
    } else {
      Navigator.pop(context, beneficiaryVault);
    }
  }

  void _handleScanFailure(String message) {
    _qrDataHandler.reset();

    if (_isFragmentedDataScanned) {
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

  Future<void> _resetScanState() async {
    _qrDataHandler.reset();
    resetScanProgress();

    if (mounted) {
      setState(() => isProcessing = false);
    }

    await _restartScanner();
  }

  @override
  List<TextSpan> buildTooltipRichText(BuildContext context, VisibilityProvider visibilityProvider) {
    return [];
  }
}
