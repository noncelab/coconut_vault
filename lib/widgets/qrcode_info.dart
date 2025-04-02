import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class QRCodeInfo extends StatefulWidget {
  final String qrData;
  final Widget? qrcodeTopWidget;

  const QRCodeInfo({super.key, required this.qrData, this.qrcodeTopWidget});

  @override
  State<QRCodeInfo> createState() => _QRCodeInfoState();
}

class _QRCodeInfoState extends State<QRCodeInfo> {
  static const MethodChannel _channel = MethodChannel(methodChannelOS);
  Timer? _toastTimer;
  OverlayEntry? _currentToast;
  final GlobalKey<ToastWidgetState> _toastKey = GlobalKey<ToastWidgetState>();

  @override
  Widget build(BuildContext context) {
    final double qrSize = MediaQuery.of(context).size.width * 275 / 375;

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
    if (Platform.isAndroid) {
      try {
        final int version = await _channel.invokeMethod('getSdkVersion');

        // 안드로이드13 부터는 클립보드 복사 메세지가 나오기 때문에 예외 적용
        if (version > 31) {
          return;
        }
      } on PlatformException catch (e) {
        Logger.log("Failed to get platform version: '${e.message}'.");
      }
    }

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
          message: t.toast.mnemonic_copied,
        ),
      ),
    );
  }
}
