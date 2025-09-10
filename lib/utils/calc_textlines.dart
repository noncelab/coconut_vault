import 'package:flutter/cupertino.dart';

/// @Pio
/// UI 렌더링 후 표시될 글자 라인 수를 계산하여 반환합니다.
/// @params {BuildContext} context
/// @params {String} text
/// @params {TextStyle} textStyle
/// @params {double?} width : 표시할 TextBox의 Width
/// @params {double?} padding : 적용된 패딩(horizontal)
/// @returns {int}
int calculateNumberOfLines(
    BuildContext context, String text, TextStyle textStyle, double? width, double? padding) {
  final span = TextSpan(text: text, style: textStyle);
  final tp = TextPainter(
    text: span,
    textDirection: TextDirection.ltr,
    maxLines: null,
  );

  tp.layout(maxWidth: (width ?? MediaQuery.of(context).size.width) - (padding ?? 0));
  return tp.computeLineMetrics().length;
}
