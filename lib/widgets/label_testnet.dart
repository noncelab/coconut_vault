import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/cupertino.dart';

class TestnetLabelWidget extends StatelessWidget {
  const TestnetLabelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: CoconutColors.cyanBlue,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Text(
        t.testnet,
        style: CoconutTypography.body2_14.merge(
          const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: CoconutColors.white,
          ),
        ),
      ),
    );
  }
}
