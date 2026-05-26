import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:flutter/material.dart';

class CharacterFadeInText extends StatelessWidget {
  final String text;
  final String animationKey;
  final Duration duration;
  final Duration delay;
  final TextStyle textStyle;

  const CharacterFadeInText({
    super.key,
    required this.text,
    required this.animationKey,
    required this.duration,
    required this.delay,
    this.textStyle = CoconutTypography.body1_16,
  });

  @override
  Widget build(BuildContext context) {
    return text.characterFadeInAnimation(
      key: ValueKey(animationKey),
      duration: duration,
      delay: delay,
      textStyle: textStyle,
    );
  }
}
