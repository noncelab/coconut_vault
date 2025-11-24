import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final scanAreaSize =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
            ? 320.0
            : MediaQuery.of(context).size.width * 0.85;

    return CustomPaint(size: MediaQuery.of(context).size, painter: _ScannerOverlayPainter(scanAreaSize));
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanSize;

  _ScannerOverlayPainter(this.scanSize);

  @override
  void paint(Canvas canvas, Size size) {
    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: scanSize, height: scanSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
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
