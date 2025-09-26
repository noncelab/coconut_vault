import 'package:flutter/material.dart';

class HighLightedText extends StatelessWidget {
  final String data;
  final Color color;
  final double fontSize;

  const HighLightedText(this.data, {super.key, required this.color, this.fontSize = 14});

  Size getTextSize({required String text, required TextStyle style, required BuildContext context}) {
    final Size size =
        (TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textScaleFactor: MediaQuery.of(context).textScaleFactor, // TODO usage 변경
          textDirection: TextDirection.ltr,
        )..layout()).size;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
      fontFamily: 'Pretendard',
    );
    final Size textSize = getTextSize(text: data, style: textStyle, context: context);
    return Stack(
      children: [
        Text(data, style: textStyle),
        Positioned(
          top: textSize.height / 2,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color.withValues(alpha: 0.2)),
            height: textSize.height / 2,
            width: textSize.width,
          ),
        ),
      ],
    );
  }
}
