import 'dart:async';

import 'package:coconut_vault/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class QRCodeInfo extends StatefulWidget {
  final String qrData;
  final Widget? qrcodeTopWidget;
  final String toastMessage;

  const QRCodeInfo({super.key, required this.qrData, required this.toastMessage, this.qrcodeTopWidget});

  @override
  State<QRCodeInfo> createState() => _QRCodeInfoState();
}

class _QRCodeInfoState extends State<QRCodeInfo> {
  Timer? _toastTimer;
  OverlayEntry? _currentToast;
  final GlobalKey<ToastWidgetState> _toastKey = GlobalKey<ToastWidgetState>();

  @override
  Widget build(BuildContext context) {
    const double qrSize = 375;

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.qrcodeTopWidget != null) ...[
              widget.qrcodeTopWidget!,
              const SizedBox(height: 25)
            ],
            Stack(
              children: [
                Container(
                    width: qrSize,
                    height: qrSize,
                    decoration: BoxDecorations.shadowBoxDecoration),
                QrImageView(
                  data: widget.qrData,
                  version: QrVersions.auto,
                  size: qrSize,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ShrinkAnimationButton(
              defaultColor: MyColors.lightgrey,
              pressedColor: MyColors.grey.withOpacity(0.1),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.qrData))
                    .then((value) => null);
                _showToast();
              },
              child: Container(
                padding: const EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: 28,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 6),
                            child: Text(widget.qrData,
                                style: Styles.body1,
                                textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    const Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.content_copy,
                        size: 20,
                        color: MyColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  void _showToast() async {
    if (_currentToast != null) {
      _currentToast!.remove();
      _toastTimer?.cancel();
    }

    _currentToast = _createToast();
    if (mounted) Overlay.of(context).insert(_currentToast!);

    _toastTimer = Timer(const Duration(seconds: 3), () {
      _hideToast();
    });
  }

  void _hideToast() {
    if (_currentToast != null && _toastKey.currentState != null) {
      _toastKey.currentState!.hide(() {
        _currentToast!.remove();
        _currentToast = null;
        _toastTimer?.cancel();
      });
    }
  }

  OverlayEntry _createToast() {
    return OverlayEntry(
      builder: (context) => Positioned(
        bottom: 10.0,
        left: 20.0,
        right: 20.0,
        child: ToastWidget(
          key: _toastKey,
          onClose: () {
            _hideToast();
          },
          message: widget.toastMessage,
        ),
      ),
    );
  }
}


