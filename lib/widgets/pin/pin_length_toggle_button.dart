import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:coconut_design_system/coconut_design_system.dart';

enum PinType {
  number,
  character,
}

class PinTypeToggleButton extends StatelessWidget {
  final PinType currentPinType;
  final VoidCallback onToggle;
  final bool isActive;

  const PinTypeToggleButton({
    super.key,
    required this.currentPinType,
    required this.onToggle,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: CoconutButton(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: Sizes.size12, vertical: Sizes.size8),
          isActive: isActive,
          onPressed: onToggle,
          text: currentPinType == PinType.character
              ? t.pin_setting_screen.number_password_input
              : t.pin_setting_screen.character_password_input,
          pressedBackgroundColor: CoconutColors.gray800,
          backgroundColor: CoconutColors.gray350,
          buttonType: CoconutButtonType.outlined,
          textStyle: CoconutTypography.body2_14.setColor(CoconutColors.black)),
    );
  }
}
