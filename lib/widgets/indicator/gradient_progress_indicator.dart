import 'dart:math';

import 'package:flutter/material.dart';

class GradientCircularProgressIndicator extends StatelessWidget {
  final double radius;
  final List<Color> gradientColors;
  final double strokeWidth;
  final double progress;

  const GradientCircularProgressIndicator({
    super.key,
    required this.radius,
    required this.gradientColors,
    this.strokeWidth = 40.0,
    this.progress = 0.1, // 0.0 ~ 1.0
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromRadius(radius),
      painter: GradientCircularProgressPainter(
        radius: radius,
        gradientColors: gradientColors,
        strokeWidth: strokeWidth,
        progress: progress,
      ),
    );
  }
}

class GradientCircularProgressPainter extends CustomPainter {
  GradientCircularProgressPainter({
    required this.radius,
    required this.gradientColors,
    required this.strokeWidth,
    required this.progress,
  });

  final double radius;
  final List<Color> gradientColors;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    size = Size.fromRadius(radius);
    double offset = strokeWidth / 2;
    Rect rect = Offset(offset, offset) & Size(size.width - strokeWidth, size.height - strokeWidth);

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    var paint = Paint()
      ..style = PaintingStyle.stroke
      // ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    paint.shader = SweepGradient(
      colors: gradientColors,
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      transform: const GradientRotation(startAngle),
    ) // ✅ 중심 기준 회전 보정
        .createShader(rect);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    final center = Offset(size.width / 2, size.height / 2);
    final radiusAdjusted = (size.width - strokeWidth) / 2;

    final endPoint = Offset(
      center.dx + radiusAdjusted * cos(startAngle + sweepAngle),
      center.dy + radiusAdjusted * sin(startAngle + sweepAngle),
    );

    // 둥근 앞머리를 위한 작은 원
    // 반원 중심
    final tailCenter = endPoint;

    // arc가 끝나는 지점에서의 tangent 방향 계산
    final angle = startAngle + sweepAngle;
    final dx = cos(angle);
    final dy = sin(angle);

    // 반원 그릴 각도는 180도지만, arc 끝 방향으로 이동
    final headPath = Path()
      ..moveTo(tailCenter.dx + (strokeWidth / 2) * dy + 15, tailCenter.dy - (strokeWidth / 2) * dx)
      ..arcTo(
        Rect.fromCircle(center: tailCenter, radius: strokeWidth / 2),
        angle + pi * 2, // tangent 방향에 맞춰 시작
        pi,
        false,
      );

    final headPaint = Paint()..color = gradientColors.last;
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
