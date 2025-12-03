import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

Widget tooltipDescription(String description) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      const Text('•', style: CoconutTypography.body1_16),
      const SizedBox(width: 8),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: CoconutTypography.body2_14.setColor(CoconutColors.black),
            children: _parseDescription(description),
          ),
        ),
      ),
    ],
  );
}

List<TextSpan> _parseDescription(String description) {
  // ** 로 감싸져 있는 문구 볼트체 적용
  List<TextSpan> spans = [];
  description.split("**").asMap().forEach((index, part) {
    spans.add(TextSpan(text: part, style: index.isEven ? CoconutTypography.body2_14 : CoconutTypography.body2_14_Bold));
  });
  return spans;
}

TextSpan em(String text) => TextSpan(text: text, style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.black));
