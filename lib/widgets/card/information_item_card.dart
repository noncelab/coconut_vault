import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class InformationItemCard extends StatefulWidget {
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
  State<InformationItemCard> createState() => _InformationItemCardState();
}

class _InformationItemCardState extends State<InformationItemCard> {
  bool _isTextTooWide(String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    debugPrint('textPainter.width @@@@@@@@ ${textPainter.width}');
    debugPrint('maxWidth @@@@@@@@ $maxWidth');

    return textPainter.width > maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.3;
    final baseStyle = CoconutTypography.body2_14_Bold;
    final isTooWide = _isTextTooWide(widget.label, baseStyle, maxWidth);
    debugPrint('isTooWide @@@@@@@@ $isTooWide');
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child:
            isTooWide
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: CoconutTypography.body2_14_Bold.setColor(widget.textColor ?? CoconutColors.black),
                    ),
                    if (widget.value != null) ...[
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            widget.value!.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isLast = index == widget.value!.length - 1;

                              return Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.size4),
                                child: Text(
                                  item,
                                  textAlign: TextAlign.left,
                                  style:
                                      widget.isNumber ? CoconutTypography.body2_14_Number : CoconutTypography.body2_14,
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                    if (widget.showIcon)
                      Align(
                        alignment: Alignment.centerRight,
                        child:
                            widget.rightIcon ??
                            const Icon(Icons.keyboard_arrow_right_rounded, color: CoconutColors.borderGray),
                      ),
                  ],
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: CoconutTypography.body2_14_Bold.setColor(widget.textColor ?? CoconutColors.black),
                    ),
                    widget.showIcon ? const Spacer() : const SizedBox(width: 32),
                    if (widget.value != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children:
                              widget.value!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final isLast = index == widget.value!.length - 1;

                                return Padding(
                                  padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.size4),
                                  child: Text(
                                    item,
                                    textAlign: TextAlign.right,
                                    style:
                                        widget.isNumber
                                            ? CoconutTypography.body2_14_Number
                                            : CoconutTypography.body2_14,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    if (widget.showIcon)
                      widget.rightIcon ??
                          const Icon(Icons.keyboard_arrow_right_rounded, color: CoconutColors.borderGray),
                  ],
                ),
      ),
    );
  }
}
