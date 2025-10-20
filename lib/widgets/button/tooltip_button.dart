import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class TooltipButton extends StatefulWidget {
  final bool isSelected;
  final String text;
  final bool isLeft;
  final GestureTapDownCallback onTapDown;
  final EdgeInsets containerMargin;
  final GlobalKey iconkey;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double? iconSize;
  final bool isIconBold;

  const TooltipButton({
    super.key,
    required this.isSelected,
    required this.text,
    required this.isLeft,
    required this.onTapDown,
    required this.iconkey,
    this.containerMargin = const EdgeInsets.all(4),
    this.textStyle,
    this.iconColor,
    this.iconSize,
    this.isIconBold = false,
  });

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.containerMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: widget.isSelected ? CoconutColors.black.withValues(alpha: 0.5) : Colors.transparent,
      ),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTapDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.text,
                    style:
                        widget.textStyle ??
                        CoconutTypography.body2_14.merge(
                          TextStyle(
                            color: widget.isSelected ? CoconutColors.black : CoconutColors.black.withValues(alpha: 0.3),
                            fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                key: widget.iconkey,
                Icons.info_outline_rounded,
                color:
                    widget.iconColor ??
                    (widget.isSelected ? CoconutColors.black : CoconutColors.black.withValues(alpha: 0.3)),
                size: widget.iconSize ?? 16,
                weight: widget.isIconBold ? FontWeight.bold.value.toDouble() : FontWeight.normal.value.toDouble(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
