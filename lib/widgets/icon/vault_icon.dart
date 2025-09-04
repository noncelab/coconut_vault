import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 멀티시그 지갑 Border gradient 효과는 vault_icon_small에만 적용
class VaultIcon extends StatelessWidget {
  late final Color backgroundColor;
  late final Color iconColor;
  late final String iconPath;
  late final double size;
  VaultIcon({super.key, required int? iconIndex, required int? colorIndex, this.size = 22}) {
    backgroundColor = colorIndex == null
        ? CoconutColors.gray150
        : CoconutColors.backgroundColorPaletteLight[colorIndex];
    iconColor = colorIndex == null ? CoconutColors.gray500 : CoconutColors.colorPalette[colorIndex];
    iconPath =
        iconIndex == null ? 'assets/svg/import-bsms.svg' : CustomIcons.getPathByIndex(iconIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SvgPicture.asset(
        iconPath,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        width: size,
      ),
    );
  }
}
