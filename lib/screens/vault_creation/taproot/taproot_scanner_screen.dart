import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/coconut_qr_scanner.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';

class TaprootScannerScreen extends StatefulWidget {
  final bool isEmbedded;
  final List<TextSpan>? titleLines;
  final Function(String)? onScanned;

  const TaprootScannerScreen({super.key, this.isEmbedded = false, this.titleLines, this.onScanned});

  @override
  State<TaprootScannerScreen> createState() => _TaprootScannerScreenState();
}

class _TaprootScanDataHandler implements IQrScanDataHandler {
  String? _scannedData;

  @override
  void reset() => _scannedData = null;

  @override
  bool isCompleted() => _scannedData != null;

  @override
  bool validateFormat(String data) => data.trim().startsWith('tr(');

  @override
  bool joinData(String data) {
    if (validateFormat(data)) {
      _scannedData = data.trim();
      return true;
    }
    return false;
  }

  @override
  double get progress => _scannedData != null ? 1.0 : 0.0;

  @override
  dynamic get result => _scannedData;
}

class _TaprootScannerScreenState extends State<TaprootScannerScreen> {
  final _TaprootScanDataHandler _qrDataHandler = _TaprootScanDataHandler();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CoconutColors.black,
      child: Stack(
        children: [
          CoconutQrScanner(
            setQrViewController: (_) {},
            qrDataHandler: _qrDataHandler,
            onComplete: (result) {
              Logger.log('Scanned Taproot Descriptor: $result');
              widget.onScanned?.call(result as String);
            },
            onFailed: (errorMessage) {
              Logger.error('QR Scan Failed: $errorMessage');
            },
          ),
          if (widget.titleLines != null)
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 34),
                  ...widget.titleLines!.map((line) {
                    final bool isEmpty = (line.text?.isEmpty ?? true) && (line.children?.isEmpty ?? true);
                    return RichText(
                      text: TextSpan(
                        style: CoconutTypography.heading3_21_Bold.setColor(CoconutColors.white),
                        children: [isEmpty ? const TextSpan(text: ' ') : line],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
