import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/utils/logger.dart';
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
  final GlobalKey<_ToastWidgetState> _toastKey = GlobalKey<_ToastWidgetState>();

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
    if (Platform.isAndroid) {
      try {
        final String version =
            await _channel.invokeMethod('getPlatformVersion');

        // 안드로이드13 부터는 클립보드 복사 메세지가 나오기 때문에 예외 적용
        if (int.parse(version) > 12) {
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
        child: _ToastWidget(
          key: _toastKey,
          onClose: () {
            _hideToast();
          },
        ),
      ),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final VoidCallback onClose;

  const _ToastWidget({required this.onClose, super.key});

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  void hide(VoidCallback onAnimationEnd) {
    _controller.reverse().then((value) {
      onAnimationEnd();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: MyColors.transparentBlack_30,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '니모닉 문구가 복사됐어요',
              style: Styles.body2Bold
                  .merge(const TextStyle(color: MyColors.white)),
            ),
            const Icon(
              Icons.check,
              color: MyColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
