import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/indicator/gradient_progress_indicator.dart';
import 'package:flutter/material.dart';

class PercentProgressIndicator extends StatefulWidget {
  const PercentProgressIndicator(
      {super.key,
      required this.progressController,
      this.radius,
      this.gradientColors,
      this.strokeWidth,
      this.textColor});

  final AnimationController progressController;
  final double? radius;
  final List<Color>? gradientColors;
  final double? strokeWidth;
  final Color? textColor;

  @override
  State<PercentProgressIndicator> createState() => _PercentProgressIndicatorState();
}

class _PercentProgressIndicatorState extends State<PercentProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GradientCircularProgressIndicator(
          radius: widget.radius ?? 90,
          gradientColors: widget.gradientColors ??
              const [
                CoconutColors.white,
                Color.fromARGB(255, 164, 214, 250),
              ],
          strokeWidth: widget.strokeWidth ?? 36.0,
          progress: widget.progressController.value > 0 ? widget.progressController.value : 0.01,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (widget.progressController.value * 100).toStringAsFixed(0),
              style: CoconutTypography.heading1_32_Bold
                  .setColor(widget.textColor ?? CoconutColors.black)
                  .merge(const TextStyle(fontWeight: FontWeight.w900)),
            ),
            CoconutLayout.spacing_100w,
            Text(
              '%',
              style:
                  CoconutTypography.body1_16_Bold.setColor(widget.textColor ?? CoconutColors.black),
            ),
          ],
        ),
      ],
    );
  }
}
