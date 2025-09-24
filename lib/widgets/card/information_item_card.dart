import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class InformationItemCard extends StatelessWidget {
  final String label;
  final List<String>? value;
  final VoidCallback? onPressed;
  final bool showIcon;
  final bool isNumber;
  final Widget? rightIcon;
  final Color? textColor;

  const InformationItemCard({
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CoconutTypography.body2_14_Bold.setColor(
                    textColor ?? CoconutColors.black,
                  ),
                ),
                showIcon ? const Spacer() : const SizedBox(width: 32),
                if (value != null)
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: value!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isLast = index == value!.length - 1;

                            return Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.size4),
                              child: Text(
                                item,
                                textAlign: TextAlign.right,
                                style: isNumber
                                    ? CoconutTypography.body2_14_Number
                                    : CoconutTypography.body2_14,
                              ),
                            );
                          }).toList())),
                if (showIcon)
                  rightIcon ??
                      const Icon(Icons.keyboard_arrow_right_rounded,
                          color: CoconutColors.borderGray)
              ],
            )));
  }
}
