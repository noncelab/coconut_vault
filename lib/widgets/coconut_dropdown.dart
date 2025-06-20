import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class CoconutDropdown extends StatefulWidget {
  final List<String> buttons;
  final Function onTapButton;
  final int dividerIndex;
  const CoconutDropdown(
      {super.key, required this.buttons, required this.onTapButton, this.dividerIndex = 0});

  @override
  State<CoconutDropdown> createState() => _CoconutDropdownState();
}

class _CoconutDropdownState extends State<CoconutDropdown> {
  int _selectedIndex = 0;
  final buttonHeight = 44.0;

  @override
  void initState() {
    _selectedIndex = widget.buttons.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // frosted_appbar height + status bar height - margin
    final status = MediaQuery.of(context).padding.top;
    final topMargin = (84 + status) - (status / 2);

    return Container(
      margin: EdgeInsets.only(top: topMargin, right: 20),
      width: 152,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: CoconutColors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 16,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.buttons.length, (index) {
          return _button(
            widget.buttons[index],
            index,
            dividerHeight: widget.dividerIndex > 0 && widget.dividerIndex == index + 1 ? 5 : 1,
            isFirst: index == 0,
            isLast: index == widget.buttons.length - 1,
          );
        }),
      ),
    );
  }

  Widget _button(String title, int index,
      {double dividerHeight = 1, bool isFirst = false, bool isLast = false}) {
    return Column(
      children: [
        InkWell(
          onTapDown: (_) {
            setState(() {
              _selectedIndex = index;
            });
          },
          onTapCancel: () {
            setState(() {
              _selectedIndex = widget.buttons.length;
            });
          },
          onTap: () {
            widget.onTapButton.call(index);
          },
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Container(
            width: double.maxFinite,
            height: isFirst || isLast ? buttonHeight + 4 : buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              borderRadius: isFirst
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(16), topRight: Radius.circular(16))
                  : isLast
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                      : null,
              color: _selectedIndex == index ? CoconutColors.gray150 : CoconutColors.white,
            ),
            child: Text(
              title,
              style: CoconutTypography.body2_14.merge(
                const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        if (!isLast) Container(height: dividerHeight, color: CoconutColors.gray200),
      ],
    );
  }
}
