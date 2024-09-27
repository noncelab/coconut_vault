import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';

class CompleteButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final bool disabled;

  const CompleteButton(
      {super.key,
      required this.onPressed,
      required this.label,
      required this.disabled});

  @override
  _CompleteButtonState createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<CompleteButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
                margin: const EdgeInsets.only(top: 40),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: MyBorder.boxDecorationRadius,
                  color: widget.disabled
                      ? MyColors.transparentBlack_06
                      : MyColors.darkgrey,
                ),
                child: Text(
                  widget.label,
                  style: Styles.body2Bold.merge(TextStyle(
                      color: widget.disabled
                          ? MyColors.defaultText
                          : MyColors.white)),
                ))));
  }
}

class SelectableButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const SelectableButton({
    super.key,
    required this.text,
    required this.onTap,
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
          color: _isTapped ? MyColors.darkgrey : Colors.transparent,
        ),
        child: Center(
            child: Text(
          widget.text,
          style: Styles.body2.merge(TextStyle(
              fontWeight: FontWeight.bold,
              color: _isTapped ? MyColors.white : MyColors.darkgrey)),
          textAlign: TextAlign.center,
        )),
      ),
    );
  }
}
