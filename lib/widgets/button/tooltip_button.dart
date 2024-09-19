import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';

class TooltipButton extends StatefulWidget {
  final bool isSelected;
  final String text;
  final bool isLeft;
  final VoidCallback onTap;
  final GestureTapDownCallback onTapDown;
  final EdgeInsets containerMargin;
  final GlobalKey iconkey;

  const TooltipButton({
    super.key,
    required this.isSelected,
    required this.text,
    required this.isLeft,
    required this.onTap,
    required this.onTapDown,
    required this.iconkey,
    this.containerMargin = const EdgeInsets.all(4),
  });

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: widget.containerMargin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: widget.isSelected
              ? MyColors.transparentBlack_50
              : Colors.transparent,
        ),
        child: Center(
          child: GestureDetector(
            onTapDown: widget.onTapDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.text,
                  style: Styles.label.merge(
                    TextStyle(
                      color: widget.isSelected
                          ? MyColors.black
                          : MyColors.transparentBlack_30,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  key: widget.iconkey,
                  Icons.info_outline_rounded,
                  color: widget.isSelected
                      ? MyColors.black
                      : MyColors.transparentBlack_30,
                  size: 16,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
