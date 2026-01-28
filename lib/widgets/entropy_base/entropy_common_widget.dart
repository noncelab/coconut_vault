import 'dart:ui';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_tween_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EntropyPassphraseInput extends StatelessWidget {
  final TextEditingController passphraseController;
  final TextEditingController passphraseConfirmController;
  final FocusNode passphraseFocusNode;
  final FocusNode passphraseConfirmFocusNode;
  final bool passphraseObscured;
  final int step;
  final Function(bool) onPassphraseObscuredChanged;
  final Function() onPassphraseConfirmVisibilityChanged;
  final Function() onPassphraseClear;
  final Function() onPassphraseConfirmClear;

  const EntropyPassphraseInput({
    super.key,
    required this.passphraseController,
    required this.passphraseConfirmController,
    required this.passphraseFocusNode,
    required this.passphraseConfirmFocusNode,
    required this.passphraseObscured,
    required this.step,
    required this.onPassphraseObscuredChanged,
    required this.onPassphraseConfirmVisibilityChanged,
    required this.onPassphraseClear,
    required this.onPassphraseConfirmClear,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Container(
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
        child: Column(
          children: [
            Text(
              t.passphrase_textfield.title,
              style: CoconutTypography.body1_16_Bold.setColor(
                step == 0 ? CoconutColors.warningText : CoconutColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            CoconutLayout.spacing_400h,
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CoconutLayout.spacing_200w,
                Text(
                  passphraseObscured
                      ? t.passphrase_textfield.passphrase_visible
                      : t.passphrase_textfield.passphrase_hidden,
                  style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.black),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => onPassphraseObscuredChanged(!passphraseObscured),
                  icon: Icon(
                    passphraseObscured ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    color: CoconutColors.gray800,
                    size: 20,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                child: _buildPassphraseField(
                  controller: passphraseController,
                  focusNode: passphraseFocusNode,
                  placeholder: t.mnemonic_generate_screen.memorable_passphrase_guide,
                  onClear: onPassphraseClear,
                  obscure: passphraseObscured,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(passphraseConfirmFocusNode);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                child: _buildPassphraseField(
                  controller: passphraseConfirmController,
                  focusNode: passphraseConfirmFocusNode,
                  placeholder: t.mnemonic_generate_screen.passphrase_confirm_guide,
                  onClear: onPassphraseConfirmClear,
                  obscure: passphraseObscured,
                ),
              ),
            ),
            CoconutLayout.spacing_2500h,
          ],
        ),
      ),
    );
  }

  Widget _buildPassphraseField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required VoidCallback onClear,
    bool obscure = false,
    VoidCallback? onEditingComplete,
  }) {
    return CoconutTextField(
      focusNode: focusNode,
      controller: controller,
      placeholderText: placeholder,
      onEditingComplete: onEditingComplete,
      onChanged: (_) {},
      maxLines: 1,
      obscureText: obscure,
      suffix: Row(
        children: [
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/svg/text-field-clear.svg',
                  colorFilter: const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
                ),
              ),
            ),
          CoconutLayout.spacing_200w,
        ],
      ),
      maxLength: 100,
    );
  }
}

class EntropyStepIndicator extends StatelessWidget {
  final bool usePassphrase;
  final int step;
  final Function(int) onStepSelected;

  const EntropyStepIndicator({
    super.key,
    required this.usePassphrase,
    required this.step,
    required this.onStepSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      visible: usePassphrase,
      child: Column(
        children: [
          CoconutLayout.spacing_500h,
          Stack(
            children: [
              const SizedBox(
                height: 50,
                width: 120,
                child: Center(
                  child: DottedDivider(
                    height: 2.0,
                    width: 100,
                    dashWidth: 2.0,
                    dashSpace: 4.0,
                    color: CoconutColors.gray400,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: NumberWidget(number: 1, selected: step == 0, onSelected: () => onStepSelected(0)),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: NumberWidget(number: 2, selected: step == 1, onSelected: () => onStepSelected(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NumberWidget extends StatefulWidget {
  final int number;
  final bool selected;
  final Function() onSelected;

  const NumberWidget({super.key, required this.number, required this.selected, required this.onSelected});

  @override
  State<NumberWidget> createState() => _NumberWidgetState();
}

class _NumberWidgetState extends State<NumberWidget> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = CoconutColors.gray800;
    Color iconColor = CoconutColors.white;
    bool isFirst = widget.number == 1;
    return GestureDetector(
      onTap: widget.onSelected,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(left: isFirst ? 8 : 16, right: isFirst ? 16 : 8, top: 8, bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: widget.selected ? bgColor : CoconutColors.gray400,
            border: widget.selected ? Border.all(color: CoconutColors.gray800) : null,
            shape: BoxShape.circle,
          ),
          width: widget.selected ? 28 : 12,
          child:
              widget.selected
                  ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(widget.selected ? 8 : 6),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                        child: Text(
                          widget.number.toString(),
                          style: CoconutTypography.body3_12_Number.setColor(iconColor),
                        ),
                      ),
                    ),
                  )
                  : Container(),
        ),
      ),
    );
  }
}

class DottedDivider extends StatelessWidget {
  final double height;
  final double width;
  final double dashWidth;
  final double dashSpace;
  final Color color;

  const DottedDivider({
    super.key,
    this.height = 1.0,
    this.width = double.infinity,
    this.dashWidth = 2.0,
    this.dashSpace = 2.0,
    this.color = CoconutColors.gray500,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: CustomPaint(
        size: Size(width, height),
        painter: DottedLinePainter(dashWidth: dashWidth, dashSpace: dashSpace, color: color),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final double dashWidth;
  final double dashSpace;
  final Color color;

  DottedLinePainter({required this.dashWidth, required this.dashSpace, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2), Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class EntropyBottomButtons extends StatelessWidget {
  final bool isRightButtonActive;
  final String leftText;
  final String rightText;
  final VoidCallback onLeftButtonPressed;
  final VoidCallback onRightButtonPressed;
  final Widget? subWidget;

  const EntropyBottomButtons({
    super.key,
    required this.isRightButtonActive,
    required this.leftText,
    required this.rightText,
    required this.onLeftButtonPressed,
    required this.onRightButtonPressed,
    this.subWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FixedBottomTweenButton(
      showGradient: false,
      leftButtonRatio: 0.35,
      leftButtonClicked: onLeftButtonPressed,
      rightButtonClicked: onRightButtonPressed,
      isRightButtonActive: isRightButtonActive,
      leftText: leftText,
      rightText: rightText,
      subWidget: subWidget,
      rightButtonBorderColor: isRightButtonActive ? CoconutColors.black : CoconutColors.gray150,
    );
  }
}

class WordsLengthSelection extends StatefulWidget {
  final void Function(int) onSelected;

  const WordsLengthSelection({super.key, required this.onSelected});

  @override
  State<WordsLengthSelection> createState() => _WordsLengthSelectionState();
}

class _WordsLengthSelectionState extends State<WordsLengthSelection> {
  int selectedWordsCount = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
      child: Column(
        children: [
          Text(t.mnemonic_generate_screen.select_word_length, style: CoconutTypography.body1_16_Bold),
          CoconutLayout.spacing_800h,
          Row(
            children: [
              _buildWordCountButton(t.mnemonic_generate_screen.twelve),
              CoconutLayout.spacing_200w,
              _buildWordCountButton(t.mnemonic_generate_screen.twenty_four),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordCountButton(String text) {
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray500.withValues(alpha: 0.15),
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: Text(text, style: CoconutTypography.body1_16_Bold)),
      ),
      onPressed: () {
        setState(() {
          selectedWordsCount = text == t.mnemonic_generate_screen.twelve ? 12 : 24;
        });
        widget.onSelected(selectedWordsCount);
      },
    );
  }
}

class PassphraseSelection extends StatefulWidget {
  final void Function(bool) onSelected;

  const PassphraseSelection({super.key, required this.onSelected});

  @override
  State<PassphraseSelection> createState() => _PassphraseSelectionState();
}

class _PassphraseSelectionState extends State<PassphraseSelection> {
  bool usePassphrase = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
      child: Column(
        children: [
          Text(
            t.mnemonic_generate_screen.use_passphrase,
            style: CoconutTypography.body1_16_Bold,
            textAlign: TextAlign.center,
          ),
          CoconutLayout.spacing_800h,
          Row(
            children: [_buildPassphraseUseButton(t.no), CoconutLayout.spacing_200w, _buildPassphraseUseButton(t.yes)],
          ),
        ],
      ),
    );
  }

  Widget _buildPassphraseUseButton(String text) {
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray500.withValues(alpha: 0.15),
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: Text(text, style: CoconutTypography.body1_16_Bold)),
      ),
      onPressed: () {
        setState(() {
          usePassphrase = text == t.no ? false : true;
        });
        widget.onSelected(usePassphrase);
      },
    );
  }
}

enum EntropyBitsOption { dice, coinflip }

class BinaryGrid extends StatelessWidget {
  final int totalCount;
  final List<int> inputs;
  final ScrollController scrollController;
  final bool showProgress;
  final EntropyBitsOption option;

  const BinaryGrid({
    super.key,
    required this.totalCount,
    required this.inputs,
    required this.scrollController,
    required this.option,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoconutLayout.spacing_200h,
          Text(
            '${t.view_all}${showProgress ? '(${inputs.length}/$totalCount)' : ''}',
            style: CoconutTypography.body2_14_Bold,
          ),
          CustomTooltip.buildInfoTooltip(
            context,
            richText: RichText(
              text: TextSpan(
                style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
                children: [
                  TextSpan(text: t.entropy_bits_bottom_sheet.iancoleman_guide),
                  TextSpan(
                    text:
                        option == EntropyBitsOption.dice
                            ? t.entropy_bits_bottom_sheet.options.dice
                            : t.entropy_bits_bottom_sheet.options.binary,
                    style: CoconutTypography.body2_14_Bold.copyWith(height: 1.3, color: CoconutColors.black),
                  ),
                  TextSpan(text: t.entropy_bits_bottom_sheet.select_option),
                ],
              ),
            ),
          ),
          CoconutLayout.spacing_400h,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: GridView.count(
                  controller: scrollController,
                  scrollDirection: Axis.vertical,
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  padding: const EdgeInsets.only(bottom: 30),
                  children: List.generate(totalCount, (index) {
                    return _buildGridItem(index < inputs.length ? inputs[index] : null, index);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(int? bit, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CoconutColors.black.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (index + 1).toString(),
              style: CoconutTypography.body3_12_Number.setColor(CoconutColors.black.withValues(alpha: 0.3)),
            ),
            Expanded(
              child: Text(
                bit == null ? '' : bit.toString(),
                style: CoconutTypography.heading4_18_NumberBold.setColor(CoconutColors.black.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntropyProgressBar extends StatelessWidget {
  final bool visible;
  final int total;
  final int current;

  const EntropyProgressBar({super.key, required this.visible, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Visibility(
        visible: visible,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        maintainInteractivity: true,
        child: Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Stack(
            children: [
              ClipRRect(child: Container(height: 6, color: CoconutColors.black.withValues(alpha: 0.06))),
              ClipRRect(
                borderRadius:
                    current / total == 1
                        ? BorderRadius.zero
                        : const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 6,
                  width: MediaQuery.of(context).size.width * (current / total),
                  color: CoconutColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// MnemonicList를 가리기 위해 사용하는 위젯
class WarningWidget extends StatefulWidget {
  final bool visible;
  final bool isBackgroundBlur;
  final VoidCallback? onWarningDismissed;
  final String? title;
  final Widget? description;
  final String? buttonText;

  const WarningWidget({
    super.key,
    this.visible = true,
    this.isBackgroundBlur = true,
    this.onWarningDismissed,
    this.title,
    this.description,
    this.buttonText,
  });

  @override
  State<WarningWidget> createState() => _WarningWidgetState();
}

class _WarningWidgetState extends State<WarningWidget> {
  late bool _visible;
  late String _title;
  late Widget _description;
  late String _buttonText;

  @override
  void initState() {
    super.initState();
    _visible = widget.visible;
    _title = widget.title ?? t.mnemonic_view_screen.warning_title;
    _description =
        widget.description == null
            ? Text(
              t.mnemonic_view_screen.warning_guide,
              style: CoconutTypography.heading4_18.setColor(CoconutColors.white),
              textAlign: TextAlign.center,
            )
            : widget.description!;
    _buttonText = widget.buttonText ?? t.mnemonic_view_screen.warning_btn;
  }

  @override
  Widget build(BuildContext context) {
    final child = Align(
      alignment: const Alignment(0, -0.2),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: CoconutColors.hotPink),
        padding: const EdgeInsets.only(top: 28, left: 24, right: 24, bottom: 20),
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/svg/triangle-warning.svg',
                width: 32,
                colorFilter: const ColorFilter.mode(CoconutColors.white, BlendMode.srcIn),
              ),
              CoconutLayout.spacing_300h,
              Text(
                _title,
                style: CoconutTypography.heading3_21_Bold.setColor(CoconutColors.white),
                textAlign: TextAlign.center,
              ),
              CoconutLayout.spacing_400h,
              _description,
              CoconutLayout.spacing_600h,
              ShrinkAnimationButton(
                borderRadius: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  width: double.infinity,
                  child: Text(
                    _buttonText,
                    style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.hotPink),
                    textAlign: TextAlign.center,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _visible = false;
                  });
                  widget.onWarningDismissed?.call();
                },
              ),
              CoconutLayout.spacing_300h,
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Visibility(
        visible: _visible,
        child: ClipRRect(
          child: Center(
            child: SingleChildScrollView(
              child:
                  widget.isBackgroundBlur
                      ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: child)
                      : child,
            ),
          ),
        ),
      ),
    );
  }
}
