import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  final TextSpan? tooltipTextSpan;
  final Rect? scanWindow;

  const ScannerOverlay({super.key, this.tooltipTextSpan, this.scanWindow});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final scanAreaSize = ScannerOverlay.calculateScanAreaSize(context, tooltipTextSpan: tooltipTextSpan);
        final rect =
            scanWindow ?? Rect.fromCenter(center: size.center(Offset.zero), width: scanAreaSize, height: scanAreaSize);

        return CustomPaint(size: size, painter: _ScannerOverlayPainter(rect));
      },
    );
  }

  static double calculateScanAreaSize(BuildContext context, {TextSpan? tooltipTextSpan}) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    if (isWideScreen) {
      return 500.0;
    }

    final widthBasedSize = size.width * 0.85;

    // Calculate the tooltip height dynamically
    double tooltipHeight = 0.0;
    if (tooltipTextSpan != null) {
      final textPainter = TextPainter(
        text: tooltipTextSpan,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: size.width - 64); // CustomTooltip의 좌우 패딩(16) 및 마진(16) 고려 (16+16)*2 = 64

      // 실제 텍스트 높이 + CustomTooltip 내부 상하 패딩(약 32) + 상단 툴팁 마진(20)
      tooltipHeight = textPainter.size.height + 52.0;
    }

    // 기기별 상단 여백(SafeArea) + 앱바(kToolbarHeight) + 계산된 툴팁 높이 + 툴팁과 스캔 영역 사이의 최소 여백 보장(20.0)
    final topPadding = MediaQuery.of(context).padding.top;
    final topUiHeight = topPadding + kToolbarHeight + tooltipHeight + 20.0;
    // 스캔 영역은 화면 정중앙에 위치하므로, 상단 툴팁과 겹치지 않으려면 '(화면 높이 - 스캔 크기) / 2 >= topUiHeight' 이어야 함
    final heightBasedSize = size.height - (topUiHeight * 2);

    // Use the smaller value between width-based and height-based calculations to prevent overlap.
    final calculatedSize = widthBasedSize < heightBasedSize ? widthBasedSize : heightBasedSize;

    return calculatedSize > 150.0 ? calculatedSize : 150.0;
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;

  _ScannerOverlayPainter(this.scanRect);

  @override
  void paint(Canvas canvas, Size size) {
    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(8));
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRect(layerRect, paint);

    final bgPath =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(layerRect)
          ..addRRect(rrect);
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    canvas.drawPath(bgPath, bgPaint);

    canvas.restore();

    final borderPaint =
        Paint()
          ..color = CoconutColors.gray350
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
