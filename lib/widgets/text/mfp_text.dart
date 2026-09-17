import 'package:flutter/material.dart';

/// 8자리 master fingerprint를 4자리씩 끊어 가운데 약간의 간격을 두고 보여주는 위젯.
///
/// [style]은 각 글자 그룹에 모두 적용되며, 생략 시 상위 [DefaultTextStyle]을 따릅니다.
/// [gap]은 두 그룹 사이의 수평 간격입니다.
class MfpText extends StatelessWidget {
  final String mfp;
  final TextStyle? style;
  final double gap;

  const MfpText({super.key, required this.mfp, this.style, this.gap = 4.0});

  @override
  Widget build(BuildContext context) {
    final first = mfp.length >= 4 ? mfp.substring(0, 4) : mfp;
    final second = mfp.length > 4 ? mfp.substring(4) : '';

    return Text.rich(
      TextSpan(children: [TextSpan(text: first), WidgetSpan(child: SizedBox(width: gap)), TextSpan(text: second)]),
      style: style,
    );
  }
}
