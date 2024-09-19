import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(
              color:
                  MyColors.transparentBlack_06, // Adjust this color as needed
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
