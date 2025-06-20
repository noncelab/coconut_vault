import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
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
        buttonListWithDividers.add(_buildDivider());
      }
    }
    return Column(
      children: buttonListWithDividers,
    );
  }

  Widget _buildDivider() {
    return SizedBox(
      height: 1,
      child: Row(
        children: [
          Container(width: Sizes.size20, color: CoconutColors.black.withOpacity(0.06)),
          Expanded(
            child: Container(
              color: CoconutColors.gray300,
            ),
          ),
          Container(width: Sizes.size20, color: CoconutColors.black.withOpacity(0.06)),
        ],
      ),
    );
  }
}
