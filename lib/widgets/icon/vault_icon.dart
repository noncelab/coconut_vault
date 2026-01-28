import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 멀티시그 지갑 Border gradient 효과는 vault_icon_small에만 적용
class VaultIcon extends StatelessWidget {
  late final Color backgroundColor;
  late final Color iconColor;
  late final String iconPath;
  late final double size;
  late final String? customIconSource;
  late final VoidCallback? onPressed;
  VaultIcon({
    super.key,
    required int? iconIndex,
    required int? colorIndex,
    this.size = 22,
    this.customIconSource,
    this.onPressed,
  }) {
    backgroundColor =
        customIconSource != null
            ? CoconutColors.gray150
            : colorIndex == null
            ? CoconutColors.gray150
            : CoconutColors.backgroundColorPaletteLight[colorIndex];
    iconColor = colorIndex == null ? CoconutColors.gray500 : CoconutColors.colorPalette[colorIndex];
    iconPath =
        customIconSource != null
            ? customIconSource!
            : iconIndex == null
            ? 'assets/svg/arrow-circle-down.svg'
            : CustomIcons.getPathByIndex(iconIndex);
  }

  @override
  Widget build(BuildContext context) {
    return onPressed != null
        ? ShrinkAnimationButton(onPressed: onPressed!, child: _buildContainer())
        : _buildContainer();
  }

  Widget _buildContainer() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          iconPath,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
