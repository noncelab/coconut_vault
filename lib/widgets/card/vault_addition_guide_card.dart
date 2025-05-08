import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/dashed_border_painter.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/cupertino.dart';

class VaultAdditionGuideCard extends StatefulWidget {
  final VoidCallback onPressed;

  const VaultAdditionGuideCard({
    super.key,
    required this.onPressed,
  });

  @override
  State<VaultAdditionGuideCard> createState() => _VaultAdditionGuideCardState();
}

class _VaultAdditionGuideCardState extends State<VaultAdditionGuideCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CoconutLayout.defaultPadding),
      child: ShrinkAnimationButton(
        borderRadius: 24,
        onPressed: widget.onPressed,
        pressedColor: CoconutColors.gray200,
        child: CustomPaint(
          painter: DashedBorderPainter(
            dashSpace: 4.0,
            dashWidth: 4.0,
            color: CoconutColors.gray400,
          ),
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            padding: const EdgeInsets.symmetric(vertical: 42),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.vault_list_tab.add_wallet,
                  style: CoconutTypography.body2_14_Bold,
                ),
                CoconutLayout.spacing_200h,
                Text(
                  t.vault_list_tab.top_right_icon,
                  style: CoconutTypography.body3_12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
