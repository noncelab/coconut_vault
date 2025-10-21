import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class CompleteButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final bool disabled;

  const CompleteButton({super.key, required this.onPressed, required this.label, required this.disabled});

  @override
  State<CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<CompleteButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onPressed,
        child: Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: CoconutBorder.boxDecorationRadius,
            color: widget.disabled ? CoconutColors.black.withValues(alpha: 0.06) : CoconutColors.gray800,
          ),
          child: Text(
            widget.label,
            style: CoconutTypography.body2_14_Bold.setColor(
              widget.disabled ? CoconutColors.secondaryText : CoconutColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
