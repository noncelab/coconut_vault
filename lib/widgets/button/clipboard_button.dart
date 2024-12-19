import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/services.dart';

class ClipboardButton extends StatefulWidget {
  final String text;
  final String toastMessage;

  const ClipboardButton(
      {super.key, required this.text, required this.toastMessage});

  @override
  State<ClipboardButton> createState() => _ClipboardButtonState();
}

class _ClipboardButtonState extends State<ClipboardButton> {
  static const MethodChannel _channel = MethodChannel(methodChannelOS);
  Timer? _toastTimer;
  OverlayEntry? _currentToast;
  final GlobalKey<ToastWidgetState> _toastKey = GlobalKey<ToastWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShrinkAnimationButton(
              defaultColor: MyColors.lightgrey,
              pressedColor: MyColors.grey.withOpacity(0.1),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.text))
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
                            child: Text(widget.text,
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
          message: widget.toastMessage,
        ),
      ),
    );
  }
}
