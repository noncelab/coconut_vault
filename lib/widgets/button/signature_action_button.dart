import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class SignatureActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isEnabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const SignatureActionButton({
    super.key,
    required this.text,
    this.onTap,
    this.isEnabled = true,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: _getBorderColor(),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: CoconutTypography.body3_12.setColor(_getTextColor()),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!isEnabled) {
      return CoconutColors.gray100;
    }

    return CoconutColors.white;
  }

  Color _getBorderColor() {
    if (!isEnabled) {
      return CoconutColors.gray300;
    }

    return CoconutColors.gray900;
  }

  Color _getTextColor() {
    if (!isEnabled) {
      return CoconutColors.gray400;
    }

    return CoconutColors.gray900;
  }
}
