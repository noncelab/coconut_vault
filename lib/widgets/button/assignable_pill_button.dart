import 'dart:math' as math;
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';

class AssignablePillButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isAssigned;
  final Widget? iconWidget;
  final String text;
  final Color activeColor;
  final double? width;
  final double? height;
  final bool useAssigningAnimation;
  final bool isDisabled;

  const AssignablePillButton({
    super.key,
    this.onPressed,
    required this.isAssigned,
    this.iconWidget,
    required this.text,
    required this.activeColor,
    this.width,
    this.height = 72,
    this.useAssigningAnimation = true,
    this.isDisabled = false,
  });

  @override
  State<AssignablePillButton> createState() => _AssignablePillButtonState();
}

class _AssignablePillButtonState extends State<AssignablePillButton> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _borderAnimation;
  Animation<double>? _fadeAnimation;

  static const int _bgActiveAlpha = 16;
  static const int _pressedActiveAlpha = 40;
  static const Color _disabledBackgroundColor = CoconutColors.gray150;
  static const Color _disabledTextColor = CoconutColors.gray350;

  @override
  void initState() {
    super.initState();
    if (widget.useAssigningAnimation) {
      _initAnimation();
    }
  }

  void _initAnimation() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    _borderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller!, curve: const Interval(0.0, 0.4, curve: Curves.easeInOut)));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller!, curve: const Interval(0.4, 1.0, curve: Curves.easeInOutSine)));

    if (widget.isAssigned) {
      _controller!.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AssignablePillButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.useAssigningAnimation != oldWidget.useAssigningAnimation) {
      if (widget.useAssigningAnimation) {
        _initAnimation();
      } else {
        _controller?.dispose();
        _controller = null;
      }
    }

    if (widget.useAssigningAnimation && _controller != null) {
      if (widget.isAssigned != oldWidget.isAssigned) {
        if (widget.isAssigned) {
          _controller!.forward();
        } else {
          _controller!.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isDisabled && widget.onPressed != null;
    final innerChild = Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.iconWidget != null) ...[widget.iconWidget!, CoconutLayout.spacing_300w],
          Flexible(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child:
                  widget.useAssigningAnimation && _fadeAnimation != null
                      ? AnimatedBuilder(
                        animation: _fadeAnimation!,
                        builder: (context, _) {
                          final targetTextColor =
                              Color.lerp(CoconutColors.gray900, widget.activeColor, 0.2) ?? widget.activeColor;
                          return Text(
                            widget.text,
                            style: CoconutTypography.body1_16.copyWith(
                              color:
                                  widget.isDisabled
                                      ? _disabledTextColor
                                      : Color.lerp(CoconutColors.gray900, targetTextColor, _fadeAnimation!.value),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          );
                        },
                      )
                      : Text(
                        widget.text,
                        style:
                            widget.isDisabled
                                ? CoconutTypography.body1_16.setColor(_disabledTextColor)
                                : CoconutTypography.body1_16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
            ),
          ),
        ],
      ),
    );

    if (!widget.useAssigningAnimation) {
      final backgroundColor =
          widget.isDisabled
              ? _disabledBackgroundColor
              : widget.isAssigned
              ? widget.activeColor.withAlpha(_bgActiveAlpha)
              : CoconutColors.white;
      final borderColor =
          widget.isDisabled
              ? CoconutColors.gray300
              : widget.isAssigned
              ? widget.activeColor
              : CoconutColors.gray300;
      final buttonDecoration = BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1),
      );

      if (!isInteractive) {
        return Container(decoration: buttonDecoration, child: innerChild);
      }

      return ShrinkAnimationButton(
        onPressed: widget.onPressed!,
        defaultColor: backgroundColor,
        pressedColor: widget.isAssigned ? widget.activeColor.withAlpha(70) : CoconutColors.gray150,
        borderRadius: 100,
        borderWidth: 1,
        border: Border.all(color: borderColor, width: 1),
        child: innerChild,
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final backgroundColor =
            widget.isDisabled
                ? _disabledBackgroundColor
                : Color.lerp(
                      CoconutColors.white,
                      widget.activeColor.withAlpha(_bgActiveAlpha),
                      _fadeAnimation!.value,
                    ) ??
                    CoconutColors.white;

        final buttonBody = CustomPaint(
          painter: PillBorderPainter(
            progress: widget.isDisabled ? 0 : _borderAnimation!.value,
            activeColor: widget.isDisabled ? CoconutColors.gray300 : widget.activeColor,
            defaultColor: CoconutColors.gray300,
          ),
          child: Container(
            decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(100)),
            child: innerChild,
          ),
        );

        if (!isInteractive) {
          return buttonBody;
        }

        return ShrinkAnimationButton(
          onPressed: widget.onPressed!,
          defaultColor: Colors.transparent,
          pressedColor: widget.isAssigned ? widget.activeColor.withAlpha(_pressedActiveAlpha) : CoconutColors.gray150,
          borderRadius: 100,
          borderWidth: 0,
          child: buttonBody,
        );
      },
    );
  }
}

class PillBorderPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color defaultColor;

  PillBorderPainter({required this.progress, required this.activeColor, required this.defaultColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(100));

    final bgPaint =
        Paint()
          ..color = defaultColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, bgPaint);

    if (progress <= 0.0) return;

    final activePaint =
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    final path = Path();
    final centerX = size.width / 2;
    final straightWidth = size.width - size.height;

    path.moveTo(centerX, 0);
    path.lineTo(centerX + straightWidth / 2, 0);
    path.arcTo(Rect.fromLTWH(size.width - size.height, 0, size.height, size.height), -math.pi / 2, math.pi, false);
    path.lineTo(centerX - straightWidth / 2, size.height);
    path.arcTo(Rect.fromLTWH(0, 0, size.height, size.height), math.pi / 2, math.pi, false);
    path.lineTo(centerX, 0);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PillBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.defaultColor != defaultColor;
  }
}
