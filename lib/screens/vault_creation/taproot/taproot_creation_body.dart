import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';

class TaprootCreationBody extends StatefulWidget {
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
  State<TaprootCreationBody> createState() => _TaprootCreationBodyState();
}

class _TaprootCreationBodyState extends State<TaprootCreationBody> {
  static const Duration _contentFadeOutDuration = Duration(milliseconds: 180);
  static const Duration _contentFadeInDuration = Duration(milliseconds: 520);
  static const Duration _headerLineFadeInDuration = Duration(milliseconds: 700);
  static const Duration _headerLineFadeOutDuration = Duration(milliseconds: 180);
  static const Duration _headerInitialDelay = Duration(milliseconds: 200);
  static const Duration _fadeOutDelay = Duration(milliseconds: 300);

  bool _isContentVisible = true;
  bool _isContentTransitioning = false;
  bool _isHeaderFadingOut = false;
  late String? _displayedTitleText;
  late bool _displayedIsError;

  @override
  void initState() {
    super.initState();
    _displayedTitleText = widget.titleText;
    _displayedIsError = widget.isError;
  }

  @override
  void didUpdateWidget(covariant TaprootCreationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isContentTransitioning) {
      return;
    }

    if (oldWidget.titleText != widget.titleText || oldWidget.isError != widget.isError) {
      _displayedTitleText = widget.titleText;
      _displayedIsError = widget.isError;
    }
  }

  Future<void> _onBottomButtonPressed() async {
    if (_isContentTransitioning) {
      return;
    }

    final onBottomButtonPressed = widget.onBottomButtonPressed;
    if (onBottomButtonPressed == null) {
      return;
    }

    setState(() {
      _isContentTransitioning = true;
    });

    await Future<void>.delayed(_fadeOutDelay);
    if (!mounted) {
      return;
    }

    setState(() {
      _isContentVisible = false;
      _isHeaderFadingOut = true;
    });

    await Future<void>.delayed(_fadeOutWaitDuration);
    if (!mounted) {
      return;
    }

    onBottomButtonPressed();

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    setState(() {
      _displayedTitleText = widget.titleText;
      _displayedIsError = widget.isError;
      _isHeaderFadingOut = false;
      _isContentVisible = true;
    });

    await Future<void>.delayed(_fadeInWaitDuration);
    if (!mounted) {
      return;
    }

    setState(() {
      _isContentTransitioning = false;
    });
  }

  Duration get _fadeOutWaitDuration {
    final lines = _displayedTitleText?.split('\n').length ?? 0;
    final headerDuration = _headerLineFadeOutDuration * lines;
    return headerDuration > _contentFadeOutDuration ? headerDuration : _contentFadeOutDuration;
  }

  Duration get _fadeInWaitDuration {
    final lines = _displayedTitleText?.split('\n').length ?? 0;
    final headerDuration = _headerInitialDelay + (_headerLineFadeInDuration * lines);
    return headerDuration > _contentFadeInDuration ? headerDuration : _contentFadeInDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildAnimatedHeader(),
                AnimatedOpacity(
                  opacity: _isContentVisible ? 1 : 0,
                  duration: _isContentVisible ? _contentFadeInDuration : _contentFadeOutDuration,
                  curve: _isContentVisible ? Curves.easeOut : Curves.easeIn,
                  child: const SingleChildScrollView(child: Center(child: Text('내용 들어가는 곳'))),
                ),
              ],
            ),
          ),
        ),
        if (widget.onBottomButtonPressed != null)
          FixedBottomButton(
            onButtonClicked: _onBottomButtonPressed,
            text: widget.bottomButtonText ?? t.next,
            showGradient: false,
            subWidget: widget.subWidget,
          ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    final text = _displayedTitleText;
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_displayedIsError) ...[_buildAnimatedErrorIcon(text), const SizedBox(height: 10)],
          _buildAnimatedTitleText(text),
        ],
      ),
    );
  }

  Widget _buildAnimatedErrorIcon(String text) {
    const icon = Icon(Icons.warning_amber_rounded, color: CoconutColors.warningText, size: 28);

    if (_isHeaderFadingOut) {
      return icon.fadeOutAnimation(
        key: ValueKey('taproot-creation-header-icon-out-$text'),
        duration: _headerLineFadeOutDuration,
      );
    }

    return icon.fadeInAnimation(
      key: ValueKey('taproot-creation-header-icon-in-$text'),
      duration: const Duration(milliseconds: 180),
      delay: const Duration(milliseconds: 160),
    );
  }

  Widget _buildAnimatedTitleText(String text) {
    final lines = text.split('\n');
    final textStyle = CoconutTypography.heading4_18_Bold.setColor(
      _displayedIsError ? CoconutColors.warningText : CoconutColors.black,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < lines.length; index++) _buildAnimatedTitleLine(lines[index], index, textStyle),
      ],
    );
  }

  Widget _buildAnimatedTitleLine(String line, int index, TextStyle textStyle) {
    if (_isHeaderFadingOut) {
      return line.characterFadeOutAnimation(
        key: ValueKey('taproot-creation-header-text-out-$index-$_displayedTitleText-$_displayedIsError'),
        textStyle: textStyle,
        textAlign: TextAlign.center,
        duration: _headerLineFadeOutDuration,
        delay: _headerLineFadeOutDuration * index,
        slideDirection: CoconutCharacterFadeSlideDirection.slideUp,
      );
    }

    return line.characterFadeInAnimation(
      key: ValueKey('taproot-creation-header-text-in-$index-$_displayedTitleText-$_displayedIsError'),
      textStyle: textStyle,
      textAlign: TextAlign.center,
      duration: _headerLineFadeInDuration,
      delay: _headerInitialDelay + (_headerLineFadeInDuration * index),
      slideDirection: CoconutCharacterFadeSlideDirection.slideDown,
    );
  }
}
