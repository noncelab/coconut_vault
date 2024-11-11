import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';

class InformationRowItem extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onPressed;
  final bool showIcon;
  final bool isNumber;
  final Widget? rightIcon;
  final Color? textColor;

  const InformationRowItem({
    super.key,
    required this.label,
    this.value,
    this.onPressed,
    this.showIcon = false,
    this.isNumber = true,
    this.rightIcon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(label, style: Styles.body2Bold.copyWith(color: textColor)),
                showIcon ? const Spacer() : const SizedBox(width: 32),
                if (value != null)
                  Expanded(
                      child: Text(value!,
                          textAlign: TextAlign.right,
                          style: Styles.body2.merge(
                            TextStyle(
                                fontFamily: isNumber
                                    ? CustomFonts.number.getFontFamily
                                    : CustomFonts.text.getFontFamily),
                          ))),
                if (showIcon)
                  rightIcon ??
                      const Icon(Icons.keyboard_arrow_right_rounded,
                          color: MyColors.borderGrey)
              ],
            )));
  }
}
