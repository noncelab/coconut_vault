import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class CompleteButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final bool disabled;

  const CompleteButton(
      {super.key, required this.onPressed, required this.label, required this.disabled});

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
            color: widget.disabled ? CoconutColors.black.withOpacity(0.06) : CoconutColors.gray800,
          ),
          child: Text(
            widget.label,
            style: CoconutTypography.body2_14_Bold
                .setColor(widget.disabled ? CoconutColors.secondaryText : CoconutColors.white),
          ),
        ),
      ),
    );
  }
}

@Deprecated('Use ShrinkAnimationButton instead')
class SelectableButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPressed;

  const SelectableButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isPressed = false,
  });

  @override
  State<SelectableButton> createState() => _SelectableButtonState();
}

class _SelectableButtonState extends State<SelectableButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: CoconutBorder.defaultRadius,
          border: Border.all(
            color: CoconutColors.gray800,
          ),
          color: _isTapped
              ? CoconutColors.gray800
              : widget.isPressed
                  ? CoconutColors.gray800
                  : Colors.transparent,
        ),
        child: Center(
            child: Text(
          widget.text,
          style: CoconutTypography.body2_14_Bold.setColor(_isTapped
              ? CoconutColors.white
              : widget.isPressed
                  ? CoconutColors.white
                  : CoconutColors.gray800),
          textAlign: TextAlign.center,
        )),
      ),
    );
  }
}
