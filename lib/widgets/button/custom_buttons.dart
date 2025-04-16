import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CompleteButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final bool disabled;

  const CompleteButton(
      {super.key, required this.onPressed, required this.label, required this.disabled});

  @override
  _CompleteButtonState createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<CompleteButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: GestureDetector(
            onTap: widget.disabled ? null : widget.onPressed,
            child: Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: MyBorder.boxDecorationRadius,
                  color: widget.disabled ? MyColors.transparentBlack_06 : MyColors.darkgrey,
                ),
                child: Text(
                  widget.label,
                  style: Styles.body2Bold.merge(
                      TextStyle(color: widget.disabled ? MyColors.defaultText : MyColors.white)),
                ))));
  }
}

class SelectableButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPressed;

  const SelectableButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isPressed = false,
  });

  @override
  _SelectableButtonState createState() => _SelectableButtonState();
}

class _SelectableButtonState extends State<SelectableButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: MyBorder.defaultRadius,
          border: Border.all(
            color: MyColors.darkgrey,
          ),
          color: _isTapped
              ? MyColors.darkgrey
              : widget.isPressed
                  ? MyColors.darkgrey
                  : Colors.transparent,
        ),
        child: Center(
            child: Text(
          widget.text,
          style: Styles.body2.merge(TextStyle(
              fontWeight: FontWeight.bold,
              color: _isTapped
                  ? MyColors.white
                  : widget.isPressed
                      ? MyColors.white
                      : MyColors.darkgrey)),
          textAlign: TextAlign.center,
        )),
      ),
    );
  }
}

class CountingRowButton extends StatefulWidget {
  final VoidCallback onMinusPressed;
  final VoidCallback onPlusPressed;
  final bool isMinusButtonDisabled;
  final bool isPlusButtonDisabled;
  final String countText;

  const CountingRowButton({
    super.key,
    required this.onMinusPressed,
    required this.onPlusPressed,
    required this.countText,
    this.isMinusButtonDisabled = false,
    this.isPlusButtonDisabled = false,
  });

  @override
  _CountingRowButtonState createState() => _CountingRowButtonState();
}

class _CountingRowButtonState extends State<CountingRowButton> {
  bool isMinusTapDown = false;
  bool isPlusTapDown = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: MyColors.transparentBlack_03,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTapDown: (_) {
              if (widget.isMinusButtonDisabled) return;
              setState(() {
                isMinusTapDown = true;
              });
            },
            onTapCancel: () {
              setState(() {
                isMinusTapDown = false;
              });
            },
            onTapUp: (_) {
              setState(() {
                isMinusTapDown = false;
              });
              widget.onMinusPressed();
            },
            child: Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMinusTapDown ? MyColors.dropdownGrey : Colors.transparent,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/minus.svg',
                  width: 20,
                  colorFilter: widget.isMinusButtonDisabled
                      ? const ColorFilter.mode(
                          MyColors.defaultIcon,
                          BlendMode.srcIn,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: MyColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: MyColors.transparentBlack_15,
                  offset: Offset(0, 0),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.countText,
                style: Styles.h1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTapDown: (_) {
              if (widget.isPlusButtonDisabled) return;
              setState(() {
                isPlusTapDown = true;
              });
            },
            onTapCancel: () {
              setState(() {
                isPlusTapDown = false;
              });
            },
            onTapUp: (_) {
              setState(() {
                isPlusTapDown = false;
              });
              widget.onPlusPressed();
            },
            child: Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlusTapDown ? MyColors.dropdownGrey : Colors.transparent,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/plus.svg',
                  width: 20,
                  colorFilter: widget.isPlusButtonDisabled
                      ? const ColorFilter.mode(
                          MyColors.defaultIcon,
                          BlendMode.srcIn,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
