import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:flutter/services.dart';

class ExportDetailScreen extends StatefulWidget {
  const ExportDetailScreen({super.key, required this.exportDetail});

  final String exportDetail;

  @override
  State<ExportDetailScreen> createState() => _ExportDetailScreen();
}

class _ExportDetailScreen extends State<ExportDetailScreen> {
  static const MethodChannel _channel = MethodChannel(methodChannelOS);
  Timer? _toastTimer;
  OverlayEntry? _currentToast;
  final GlobalKey<ToastWidgetState> _toastKey = GlobalKey<ToastWidgetState>();

  @override
  void initState() {
    super.initState();
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MyBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: AppBar(
          title: const Text('내보내기 상세 정보'),
          centerTitle: true,
          backgroundColor: MyColors.white,
          titleTextStyle: Styles.body1Bold,
          toolbarTextStyle: Styles.body1Bold,
          leading: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: MyColors.darkgrey,
              size: 22,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              //height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: Stack(
                children: [
                  ShrinkAnimationButton(
                    onPressed: () {
                      Clipboard.setData(
                              ClipboardData(text: widget.exportDetail))
                          .then((value) => null);
                      _showToast();
                    },
                    defaultColor: MyColors.lightgrey,
                    pressedColor: MyColors.grey.withOpacity(0.1),
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
                                  padding:
                                      const EdgeInsets.only(top: 7, right: 6),
                                  child: Text(widget.exportDetail,
                                      style: Styles.body1,
                                      textAlign: TextAlign.start),
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
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
