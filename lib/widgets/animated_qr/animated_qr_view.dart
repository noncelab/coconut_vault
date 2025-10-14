import 'dart:async';

import 'package:coconut_vault/widgets/animated_qr/view_data_handler/i_qr_view_data_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AnimatedQrView extends StatefulWidget {
  final double qrSize;
  final int milliSeconds;
  final IQrViewDataHandler qrViewDataHandler;

  const AnimatedQrView({super.key, required this.qrSize, required this.qrViewDataHandler, this.milliSeconds = 500});

  @override
  State<AnimatedQrView> createState() => _AnimatedQrViewState();
}

class _AnimatedQrViewState extends State<AnimatedQrView> {
  late String _qrData;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _qrData = widget.qrViewDataHandler.nextPart();
    _timer = Timer.periodic(Duration(milliseconds: widget.milliSeconds), (timer) {
      setState(() {
        _qrData = widget.qrViewDataHandler.nextPart();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return QrImageView(data: _qrData, size: widget.qrSize, version: 11);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
