import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';

class TaprootCreationBody extends StatelessWidget {
  final VoidCallback? onBottomButtonPressed;
  final Widget? subWidget;
  final String? bottomButtonText;
  final String? titleText;
  final bool isError;

  const TaprootCreationBody({
    super.key,
    this.onBottomButtonPressed,
    this.subWidget,
    this.bottomButtonText,
    this.titleText,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [_buildAnimatedHeader(), const SingleChildScrollView(child: Center(child: Text('내용 들어가는 곳')))],
            ),
          ),
        ),
        if (onBottomButtonPressed != null)
          FixedBottomButton(
            onButtonClicked: onBottomButtonPressed!,
            text: bottomButtonText ?? t.next,
            showGradient: false,
            subWidget: subWidget,
          ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    final text = titleText;
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isError) ...[
            const Icon(Icons.warning_amber_rounded, color: CoconutColors.warningText, size: 28).fadeInAnimation(
              key: ValueKey('taproot-creation-header-icon-$text'),
              duration: const Duration(milliseconds: 180),
              delay: const Duration(milliseconds: 160),
            ),
            const SizedBox(height: 10),
          ],
          _buildAnimatedTitleText(text),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitleText(String text) {
    final lines = text.split('\n');
    final textStyle = CoconutTypography.heading4_18_Bold.setColor(
      isError ? CoconutColors.warningText : CoconutColors.black,
    );
    const lineAnimationDuration = Duration(milliseconds: 700);
    const initialDelay = Duration(milliseconds: 200);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < lines.length; index++)
          lines[index].characterFadeInAnimation(
            key: ValueKey('taproot-creation-header-text-$index-$text-$isError'),
            textStyle: textStyle,
            textAlign: TextAlign.center,
            duration: lineAnimationDuration,
            delay: initialDelay + (lineAnimationDuration * index),
            slideDirection: CoconutCharacterFadeSlideDirection.slideDown,
          ),
      ],
    );
  }
}
