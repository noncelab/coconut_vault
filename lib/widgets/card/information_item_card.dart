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
  bool _isTextTooWide(BuildContext context, String leftText, TextStyle leftTextStyle, double maxLeftWidth) {
    final textScaler = MediaQuery.of(context).textScaler;
    final TextPainter leftTextPainter = TextPainter(
      text: TextSpan(text: leftText, style: leftTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler, // 시스템 폰트 크기 반영
    )..layout();

    return leftTextPainter.width > maxLeftWidth;
  }

  @override
  Widget build(BuildContext context) {
    const widthRatio = 0.5;
    final maxLeftWidth = (MediaQuery.of(context).size.width - 90) * widthRatio; // 90: 패딩
    final leftTextStyle = CoconutTypography.body2_14_Bold;
    final isTooWide = _isTextTooWide(context, widget.label, leftTextStyle, maxLeftWidth);

    RegExp exp = RegExp(
      r"^[^(+외]+|\([^)]*\)|\+.*$|외.*$",
    ); // Recipient에서 '(', '+', '외' 구분용 정규식 -> (0.5 BTC), +1 more, 외 1개

    RegExp expSimple = RegExp(r"^[^+외]+|\+.*$|외.*$"); // '+', '외'만 구분용 정규식 -> +1 more, 외 1개

    bool isAmountToken(String token) {
      return token.contains('BTC') || token.contains('sats');
    }

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 24),
        width: MediaQuery.of(context).size.width,
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
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          crossAxisAlignment:
                              widget.value!.length > 1
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end, // recipient만 왼쪽 정렬
                          children:
                              widget.value!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final isLast = index == widget.value!.length - 1;
                                var tokens = exp.allMatches(item).map((m) => m.group(0)!.replaceAll('\n', '')).toList();

                                if (item.isEmpty) {
                                  return Container();
                                }
                                return Container(
                                  padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.size4),
                                  child: Column(
                                    children: [
                                      Text(
                                        tokens[0],
                                        textAlign: TextAlign.end,
                                        style:
                                            widget.isNumber
                                                ? CoconutTypography.body2_14_Number
                                                : CoconutTypography.body2_14,
                                      ),
                                      if (tokens.length > 1)
                                        Container(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            tokens[1],
                                            style:
                                                isAmountToken(tokens[1])
                                                    ? CoconutTypography.body2_14_Number
                                                    : CoconutTypography.body2_14,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
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
                                var tokens =
                                    expSimple.allMatches(item).map((m) => m.group(0)!.replaceAll('\n', '')).toList();

                                if (item.isEmpty) {
                                  return Container();
                                }
                                return Padding(
                                  padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.size4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        tokens[0],
                                        textAlign: TextAlign.end,
                                        style:
                                            widget.isNumber
                                                ? CoconutTypography.body2_14_Number
                                                : CoconutTypography.body2_14,
                                      ),
                                      if (tokens.length > 1)
                                        Container(
                                          alignment: Alignment.centerRight,
                                          child: Text(tokens[1], style: CoconutTypography.body2_14),
                                        ),
                                    ],
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
