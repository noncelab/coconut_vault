import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_fragmented_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/scan_data_handler_exceptions.dart';
import 'package:coconut_vault/widgets/overlays/scanner_overlay.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class CoconutQrScanner extends StatefulWidget {
  static String qrFormatErrorMessage = 'Invalid QR format.';
  static String qrInvalidErrorMessage = 'Invalid QR Code.';
  final Function(MobileScannerController) setQrViewController;
  final Function(dynamic) onComplete;
  final Function(String) onFailed;
  final Color borderColor;
  final IQrScanDataHandler qrDataHandler;

  const CoconutQrScanner({
    super.key,
    required this.setQrViewController,
    required this.onComplete,
    required this.onFailed,
    required this.qrDataHandler,
    this.borderColor = CoconutColors.white,
  });

  @override
  State<CoconutQrScanner> createState() => _CoconutQrScannerState();
}

class _CoconutQrScannerState extends State<CoconutQrScanner> with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);
  bool _isScanningExtraData = false;
  bool _hasBeenScanningExtraData = false;
  double scannerLoadingVerticalPos = 0;
  bool _showLoadingBar = false;
  bool _isFirstScanData = true;

  MobileScannerController? _controller;

  late AppLifecycleStateProvider _appLifecycleStateProvider;

  @override
  void initState() {
    super.initState();
    _appLifecycleStateProvider = Provider.of<AppLifecycleStateProvider>(context, listen: false);
    _appLifecycleStateProvider.startOperation(AppLifecycleOperations.cameraAuthRequest, ignoreNotify: true);
    _controller = MobileScannerController()..addListener(_onCameraStateChanged);
    widget.setQrViewController(_controller!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rect = getQrViewRect();
      if (rect != null) {
        setState(() {
          scannerLoadingVerticalPos =
              ((MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
                  ? 320.0
                  : MediaQuery.of(context).size.width * 0.85) +
              30;
        });
      } else {
        Logger.log('QRView position not available yet');
      }
    });
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    _controller?.removeListener(_onCameraStateChanged);
    _controller?.dispose();
    if (_appLifecycleStateProvider.ignoredOperations.contains(AppLifecycleOperations.cameraAuthRequest)) {
      _appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
    }
    super.dispose();
  }

  void _resetScanState() {
    widget.qrDataHandler.reset();
    _isFirstScanData = true;
  }

  void _onCameraStateChanged() {
    if (_controller!.value.isInitialized) {
      _appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (widget.qrDataHandler.isCompleted()) return;

    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final barcode = codes.first;
    if (barcode.rawValue == null) return;

    final scanData = barcode.rawValue!;
    var handler = widget.qrDataHandler;

    try {
      if (_isFirstScanData) {
        if (!handler.validateFormat(scanData)) {
          widget.onFailed(CoconutQrScanner.qrFormatErrorMessage);
          setState(() {
            _showLoadingBar = false;
          });
          return;
        }
        _isFirstScanData = false;
      }

      if (!handler.isCompleted()) {
        try {
          bool result = handler.joinData(scanData);
          if (!result && handler is! IFragmentedQrScanDataHandler) {
            _resetScanState();
            _resetLoadingBarState();
            widget.onFailed(CoconutQrScanner.qrInvalidErrorMessage);
            return;
          }
          /* handler가 IFragmentedQrScanDataHandler일 땐 joinData 실패해도(result == false) 무시하고 스캔 진행함.
             왜냐하면 animated qr 스캔 중 노이즈 데이터가 오탐되는 경우가 있는데 매번 처음부터 다시 하면 사용성을 해침 */
        } on SequenceLengthMismatchException catch (_) {
          // QR Density 변경됨
          assert(handler is IFragmentedQrScanDataHandler);
          _resetScanState();
          _resetLoadingBarState();
          return;
        }
      }

      setState(() {
        _progressNotifier.value = handler.progress;
        _isScanningExtraData = handler.progress > 0.98;
        if (_isScanningExtraData) {
          _hasBeenScanningExtraData = true;
        }
        _showLoadingBar = true;
      });

      if (handler.isCompleted()) {
        _resetLoadingBarState();
        final result = handler.result;
        if (result == null) {
          widget.onFailed(CoconutQrScanner.qrInvalidErrorMessage);
          return;
        }
        widget.onComplete(result);
      }
    } catch (e) {
      Logger.error(e.toString());
      _resetLoadingBarState();
      _resetScanState();
      widget.onFailed(e.toString());
    }
  }

  void _resetLoadingBarState() {
    _progressNotifier.value = 0;
    setState(() {
      _isScanningExtraData = false;
      _hasBeenScanningExtraData = false;
      if (_showLoadingBar) {
        _showLoadingBar = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),
            const ScannerOverlay(),
            _buildProgressOverlay(context),
          ],
        );
      },
    );
  }

  Widget _buildProgressOverlay(BuildContext context) {
    final scanAreaSize =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
            ? 320.0
            : MediaQuery.of(context).size.width * 0.85;

    final scanAreaTop = (MediaQuery.of(context).size.height - scanAreaSize) / 2;
    final scanAreaBottom = scanAreaTop + scanAreaSize;

    return Stack(
      children: [
        // 프로그레스 바
        Positioned(
          top: scanAreaBottom - 24,
          left: 0,
          right: 0,
          child: Visibility(
            visible: _showLoadingBar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CoconutLayout.spacing_1300w,
                if (!_isScanningExtraData && !_hasBeenScanningExtraData) ...[
                  _buildProgressBar(),
                  CoconutLayout.spacing_300w,
                  _buildProgressText(),
                ],
                if (_isScanningExtraData) Expanded(child: _buildReadingExtraText()),
                CoconutLayout.spacing_1300w,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Rect? getQrViewRect() {
    final renderObject = qrKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final position = renderObject.localToGlobal(Offset.zero);
      final size = renderObject.size;
      return position & size;
    }
    return null;
  }

  Widget _buildReadingExtraText() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Text(
        textAlign: TextAlign.center,
        t.coconut_qr_scanner.reading_extra_data,
        style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.white),
      ),
    );
  }

  Widget _buildProgressText() {
    return ValueListenableBuilder<double>(
      valueListenable: _progressNotifier,
      builder: (context, value, _) {
        return SizedBox(
          width: 35,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Text(
              textAlign: TextAlign.center,
              "${(value * 100).toInt()}%",
              style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                width: maxWidth,
                height: 8,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: CoconutColors.gray350,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, value, _) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: maxWidth * _progressNotifier.value,
                    height: 6,
                    margin: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
