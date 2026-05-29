import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';

class TaprootCreationBody extends StatefulWidget {
  static const Duration defaultBottomButtonFadeOutDelay = Duration(milliseconds: 100);

  final FutureOr<void> Function()? onBottomButtonPressed;
  final FutureOr<void> Function()? onBeforeBottomButtonFadeOut;
  final Widget child;
  final Widget? fixedBottomSubWidget;
  final String? bottomButtonText;
  final List<TextSpan> titleLines;
  final Duration bottomButtonFadeOutDelay;
  final bool showBottomButton;
  final bool isError;
  final bool ignoreChildHorizontalPadding;
  final bool showHeader;
  final bool scrollChild;
  final bool runBottomButtonActionWithoutTransition;
  final bool keepHeaderVisibleDuringTransition;
  final bool animateHeader;

  const TaprootCreationBody({
    super.key,
    required this.titleLines,
    required this.child,
    this.onBottomButtonPressed,
    this.onBeforeBottomButtonFadeOut,
    this.fixedBottomSubWidget,
    this.bottomButtonText,
    this.bottomButtonFadeOutDelay = defaultBottomButtonFadeOutDelay,
    this.showBottomButton = true,
    this.isError = false,
    this.ignoreChildHorizontalPadding = false,
    this.showHeader = true,
    this.scrollChild = true,
    this.runBottomButtonActionWithoutTransition = false,
    this.keepHeaderVisibleDuringTransition = false,
    this.animateHeader = true,
  });

  @override
  State<TaprootCreationBody> createState() => _TaprootCreationBodyState();
}

class _TaprootCreationBodyState extends State<TaprootCreationBody> {
  static const Duration _contentFadeInDuration = Duration(milliseconds: 1500);
  static const Duration _contentFadeOutDuration = Duration(milliseconds: 180);
  static const Duration _headerLineFadeInDuration = Duration(milliseconds: 700);
  static const Duration _headerLineFadeOutDuration = Duration(milliseconds: 180);
  static const Duration _headerInitialDelay = Duration(milliseconds: 200);

  bool _isContentVisible = true;
  bool _isContentTransitioning = false;
  bool _isHeaderFadingOut = false;
  bool _isApplyingBottomButtonAction = false;
  bool _isHeaderHiddenForStepUpdate = false;
  int _transitionGeneration = 0;
  late List<TextSpan> _displayedTitleLines;
  late bool _displayedIsError;

  @override
  void initState() {
    super.initState();
    _displayedTitleLines = widget.titleLines;
    _displayedIsError = widget.isError;
  }

  @override
  void didUpdateWidget(covariant TaprootCreationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasHeaderChanged =
        _titleKeyForLines(oldWidget.titleLines) != _titleKeyForLines(widget.titleLines) ||
        oldWidget.isError != widget.isError;
    if (!hasHeaderChanged) {
      return;
    }

    if (_isContentTransitioning) {
      if (_isApplyingBottomButtonAction) {
        _displayedTitleLines = widget.titleLines;
        _displayedIsError = widget.isError;
        _isHeaderHiddenForStepUpdate = true;
        return;
      }

      _transitionGeneration++;
      _displayedTitleLines = widget.titleLines;
      _displayedIsError = widget.isError;
      _isHeaderFadingOut = false;
      _isContentVisible = true;
      _isContentTransitioning = false;
      _isHeaderHiddenForStepUpdate = false;
      return;
    }

    _displayedTitleLines = widget.titleLines;
    _displayedIsError = widget.isError;
    _isHeaderHiddenForStepUpdate = false;
  }

  Future<void> _onBottomButtonPressed() async {
    if (_isContentTransitioning) {
      return;
    }

    final onBottomButtonPressed = widget.onBottomButtonPressed;
    if (onBottomButtonPressed == null) {
      return;
    }

    if (widget.runBottomButtonActionWithoutTransition) {
      onBottomButtonPressed();
      return;
    }

    setState(() {
      _isContentTransitioning = true;
    });
    final transitionGeneration = ++_transitionGeneration;

    try {
      await widget.onBeforeBottomButtonFadeOut?.call();
    } catch (_) {
      if (mounted && transitionGeneration == _transitionGeneration) {
        setState(() {
          _isContentTransitioning = false;
        });
      }
      rethrow;
    }

    await Future<void>.delayed(widget.bottomButtonFadeOutDelay);
    if (!mounted || transitionGeneration != _transitionGeneration) {
      return;
    }

    setState(() {
      _isContentVisible = false;
      _isHeaderFadingOut = !widget.keepHeaderVisibleDuringTransition;
    });

    await Future<void>.delayed(_fadeOutWaitDuration);
    if (!mounted || transitionGeneration != _transitionGeneration) {
      return;
    }

    _isApplyingBottomButtonAction = true;
    try {
      await onBottomButtonPressed();
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      _isApplyingBottomButtonAction = false;
    }
    if (!mounted || transitionGeneration != _transitionGeneration) {
      return;
    }

    setState(() {
      _displayedTitleLines = widget.titleLines;
      _displayedIsError = widget.isError;
      _isHeaderFadingOut = false;
      _isContentVisible = true;
      _isHeaderHiddenForStepUpdate = false;
    });

    await Future<void>.delayed(_fadeInWaitDuration);
    if (!mounted || transitionGeneration != _transitionGeneration) {
      return;
    }

    setState(() {
      _isContentTransitioning = false;
    });
  }

  Duration get _fadeOutWaitDuration {
    if (widget.keepHeaderVisibleDuringTransition) {
      return _contentFadeOutDuration;
    }

    final lines = _displayedTitleLines.length;
    final headerDuration = _headerLineFadeOutDuration * lines;
    return headerDuration > _contentFadeOutDuration ? headerDuration : _contentFadeOutDuration;
  }

  Duration get _fadeInWaitDuration {
    if (widget.keepHeaderVisibleDuringTransition) {
      return _contentFadeInDuration;
    }

    final lines = _displayedTitleLines.length;
    final headerDuration = _headerInitialDelay + (_headerLineFadeInDuration * lines);
    return headerDuration > _contentFadeInDuration ? headerDuration : _contentFadeInDuration;
  }

  @override
  Widget build(BuildContext context) {
    final showBottomButton = widget.showBottomButton && !_isContentTransitioning;

    return Stack(
      children: [
        Positioned.fill(child: widget.scrollChild ? _buildScrollableContent() : _buildFixedContent()),
        if (widget.onBottomButtonPressed != null)
          AnimatedOpacity(
            opacity: showBottomButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !showBottomButton,
              child: FixedBottomButton(
                onButtonClicked: _onBottomButtonPressed,
                text: widget.bottomButtonText ?? t.next,
                showGradient: false,
                subWidget: widget.fixedBottomSubWidget,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (widget.showHeader)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildAnimatedHeader()),
          Padding(
            padding: widget.ignoreChildHorizontalPadding ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedOpacity(
              opacity: _isContentVisible ? 1 : 0,
              duration: _isContentVisible ? _contentFadeInDuration : _contentFadeOutDuration,
              curve: _isContentVisible ? Curves.easeOut : Curves.easeIn,
              child: widget.child,
            ),
          ),
          if (widget.onBottomButtonPressed != null) const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildFixedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildAnimatedHeader()),
        Expanded(
          child: Padding(
            padding: widget.ignoreChildHorizontalPadding ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedOpacity(
              opacity: _isContentVisible ? 1 : 0,
              duration: _isContentVisible ? _contentFadeInDuration : _contentFadeOutDuration,
              curve: _isContentVisible ? Curves.easeOut : Curves.easeIn,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    final lines = _displayedTitleLines;
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final titleKey = _titleKeyForLines(lines);
    final header = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 34,
              child:
                  _displayedIsError
                      ? Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildAnimatedErrorIcon(titleKey)],
                      )
                      : null,
            ),
            _buildAnimatedTitleText(lines, titleKey),
          ],
        ),
      ),
    );

    if (_isHeaderHiddenForStepUpdate) {
      return Opacity(opacity: 0, child: header);
    }

    return header;
  }

  Widget _buildAnimatedErrorIcon(String text) {
    const icon = Icon(Icons.warning_amber_rounded, color: CoconutColors.warningText, size: 28);

    if (!widget.animateHeader) {
      return icon;
    }

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

  Widget _buildAnimatedTitleText(List<TextSpan> lines, String titleKey) {
    final textStyle = CoconutTypography.heading3_21_Bold.setColor(
      _displayedIsError ? CoconutColors.warningText : CoconutColors.black,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < lines.length; index++)
          _buildAnimatedTitleLine(lines[index], index, textStyle, titleKey),
      ],
    );
  }

  Widget _buildAnimatedTitleLine(TextSpan line, int index, TextStyle defaultTextStyle, String titleKey) {
    final text = line.toPlainText();
    final textStyle = defaultTextStyle.merge(line.style);

    if (!widget.animateHeader) {
      return Text.rich(TextSpan(text: text, style: textStyle), textAlign: TextAlign.center);
    }

    if (_isHeaderFadingOut) {
      return text.characterFadeOutAnimation(
        key: ValueKey('taproot-creation-header-text-out-$index-$titleKey-$_displayedIsError'),
        textStyle: textStyle,
        textAlign: TextAlign.center,
        duration: _headerLineFadeOutDuration,
        delay: _headerLineFadeOutDuration * index,
        slideDirection: CoconutCharacterFadeSlideDirection.slideUp,
      );
    }

    return text.characterFadeInAnimation(
      key: ValueKey('taproot-creation-header-text-in-$index-$titleKey-$_displayedIsError'),
      textStyle: textStyle,
      textAlign: TextAlign.center,
      duration: _headerLineFadeInDuration,
      delay: _headerInitialDelay + (_headerLineFadeInDuration * index),
      slideDirection: CoconutCharacterFadeSlideDirection.slideDown,
    );
  }

  String _titleKeyForLines(List<TextSpan> lines) {
    return lines.map((line) => line.toPlainText()).join('|');
  }
}
