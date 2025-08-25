import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class ButtonGroup extends StatelessWidget {
  final List<Widget> buttons;

  const ButtonGroup({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    List<Widget> buttonListWithDividers = [];

    for (int i = 0; i < buttons.length; i++) {
      buttonListWithDividers.add(buttons[i]);
      if (i < buttons.length - 1) {
        buttonListWithDividers.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Sizes.size20),
            child: Divider(
              color: CoconutColors.gray300,
              height: 1,
            ),
          ),
        );
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: CoconutColors.gray200,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: buttonListWithDividers,
      ),
    );
  }
}
