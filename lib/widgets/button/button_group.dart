import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/button/button_container.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';

class ButtonGroup extends StatelessWidget {
  final List<SingleButton> buttons;

  const ButtonGroup({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    List<Widget> buttonListWithDividers = [];

    for (int i = 0; i < buttons.length; i++) {
      buttonListWithDividers.add(buttons[i]);
      if (i < buttons.length - 1) {
        buttonListWithDividers.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(
              color: CoconutColors.black.withOpacity(0.06),
              height: 1,
            ),
          ),
        );
      }
    }

    return ButtonContainer(
        child: Column(
      children: buttonListWithDividers,
    ));
  }
}
