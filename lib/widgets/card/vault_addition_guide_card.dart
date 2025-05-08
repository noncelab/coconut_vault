import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/dashed_border_painter.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

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
        pressedColor: CoconutColors.gray150,
        defaultColor: CoconutColors.gray100,
        child: CustomPaint(
          painter: DashedBorderPainter(
            dashSpace: 4.0,
            dashWidth: 4.0,
            borderRadius: 22,
            color: CoconutColors.gray400,
          ),
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            padding: const EdgeInsets.symmetric(vertical: 42),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/svg/wallet-plus.svg',
                  colorFilter: const ColorFilter.mode(
                    CoconutColors.gray700,
                    BlendMode.srcIn,
                  ),
                ),
                CoconutLayout.spacing_100w,
                Text(
                  t.vault_list_tab.add_wallet,
                  style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.gray700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
