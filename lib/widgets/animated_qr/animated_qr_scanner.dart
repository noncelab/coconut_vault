import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AnimatedQrScanner extends StatefulWidget {
  final Function(QRViewController) setQrViewController;
  final Function(dynamic) onComplete;
  final Function(String) onFailed;
  final Color borderColor;
  final IQrScanDataHandler qrDataHandler;

  const AnimatedQrScanner({
    super.key,
    required this.setQrViewController,
    required this.onComplete,
    required this.onFailed,
    required this.qrDataHandler,
    this.borderColor = CoconutColors.white,
  });

  @override
  State<AnimatedQrScanner> createState() => _AnimatedQrScannerState();
}

class _AnimatedQrScannerState extends State<AnimatedQrScanner> with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final double _borderWidth = 8;
  late AnimationController _controller;
  late Animation<double> _animation;

  double? _progress;
  double scannerLoadingVerticalPos = 0;

  Timer? _scanTimeoutTimer;
  bool _showLoadingBar = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
    _scanTimeoutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQrViewCreated(QRViewController controller) {
    widget.setQrViewController(controller);

    var handler = widget.qrDataHandler;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code == null) return;

      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = Timer(const Duration(seconds: 1), () {
        setState(() {
          _showLoadingBar = false;
        });
      });

      try {
        if (!handler.isCompleted() && !handler.joinData(scanData.code!)) {
          if (!scanData.code!.startsWith('ur')) {
            widget.onFailed('Invalid QR code');
          }
          handler.reset();
          _progress = null;
          setState(() {
            _showLoadingBar = false;
          });
          return;
        }

        setState(() {
          _progress = handler.progress;
          _showLoadingBar = _progress != null;
        });

        if (handler.isCompleted()) {
          _progress = null;
          widget.onComplete(handler.result!);
          handler.reset();
          _scanTimeoutTimer?.cancel();
        }
      } catch (e) {
        Logger.log(e.toString());
        widget.onFailed(e.toString());
        handler.reset();
        _progress = null;
        _scanTimeoutTimer?.cancel();
      }
    }, onError: (e) {
      widget.onFailed(e.toString());
      handler.reset();
      _progress = null;
      _scanTimeoutTimer?.cancel();
    });
  }

  QrScannerOverlayShape _getOverlayShape() {
    return QrScannerOverlayShape(
      borderColor: widget.borderColor,
      borderRadius: 8,
      borderLength:
          (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
              ? 160.0
              : MediaQuery.of(context).size.width * 0.85 / 2,
      borderWidth: _borderWidth,
      cutOutSize:
          (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
              ? 320.0
              : MediaQuery.of(context).size.width * 0.85,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: [
            QRView(
              key: qrKey,
              onQRViewCreated: _onQrViewCreated,
              overlay: _getOverlayShape(),
            ),
            Positioned(
              top: scannerLoadingVerticalPos,
              left: 0,
              right: 0,
              bottom: 0,
              child: Visibility(
                visible: _showLoadingBar,
                child: Center(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 100),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: (_progress != null)
                        ? AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment(_animation.value, 0),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
}
