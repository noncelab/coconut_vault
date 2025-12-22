import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/screens/airgap/multisig_psbt_qr_code_screen.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/i_qr_view_data_handler.dart';
import 'package:coconut_vault/widgets/coconut_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AnimatedQrView extends StatefulWidget {
  final int milliSeconds;
  final double qrSize;
  final QrScanDensity qrScanDensity;
  final IQrViewDataHandler qrViewDataHandler;

  const AnimatedQrView({
    super.key,
    required this.qrViewDataHandler,
    this.qrScanDensity = QrScanDensity.normal,
    this.milliSeconds = 600,
    required this.qrSize,
  });

  @override
  State<AnimatedQrView> createState() => _AnimatedQrViewState();
}

class _AnimatedQrViewState extends State<AnimatedQrView> {
  final maxBitsInFastMode = 1840;
  final maxBitsInNormalMode = 1232;
  final maxBitsInSlowMode = 848;

  late int maxBits;
  late String _qrData;
  late final Timer _timer;

  int _qrVersion = 9;

  @override
  void initState() {
    super.initState();
    maxBits =
        widget.qrScanDensity == QrScanDensity.fast
            ? maxBitsInFastMode
            : widget.qrScanDensity == QrScanDensity.normal
            ? maxBitsInNormalMode
            : maxBitsInSlowMode;
    _qrData = widget.qrViewDataHandler.nextPart();
    _qrVersion =
        widget.qrScanDensity == QrScanDensity.fast
            ? 9
            : widget.qrScanDensity == QrScanDensity.normal
            ? 7
            : 5;
    _timer = Timer.periodic(Duration(milliseconds: widget.milliSeconds), (timer) {
      final next = widget.qrViewDataHandler.nextPart();
      final int estimatedBits = next.runes.fold<int>(0, (prev, c) => prev + c.bitLength);

      final int maxCharsForVersion =
          _qrVersion == 5
              ? 100
              : _qrVersion == 7
              ? 150
              : 250;
      final bool isWithinVersionLimit = next.length <= maxCharsForVersion;

      if (estimatedBits <= maxBits && isWithinVersionLimit) {
        setState(() {
          _qrData = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int estimatedBits = _qrData.runes.fold<int>(0, (prev, c) => prev + (c.bitLength));

    final int maxCharsForVersion =
        _qrVersion == 5
            ? 100
            : _qrVersion == 7
            ? 150
            : 250;

    if (_qrData.isEmpty) {
      // QR 전환이 바로 안될 때를 대비한 위젯
      return Stack(
        children: [
          QrImageView(data: _qrData, size: widget.qrSize, version: QrVersions.auto),
          Positioned(
            left: 70,
            right: 70,
            top: 70,
            bottom: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: CoconutColors.gray300),
                child: const CoconutLoadingOverlay(applyFullScreen: true),
              ),
            ),
          ),
        ],
      );
    }

    // 시드사이너가 QR version 11 이상 인식 못하므로 10 이하로 설정해야 합니다.
    // 시드사이너가 QR version 10 인 경우 빠르게 인식이 안되어 9로 설정합니다.
    // 아래 QrImageView의 maxInputLength는 2192bits(274bytes)
    if (estimatedBits > maxBits || _qrData.length > maxCharsForVersion) {
      // 데이터가 버전별 최대 길이를 초과하면 QrVersions.auto 사용
      return QrImageView(data: _qrData, size: widget.qrSize, version: QrVersions.auto);
    }

    return QrImageView(data: _qrData, size: widget.qrSize, version: _qrVersion);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
