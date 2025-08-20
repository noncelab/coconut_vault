import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:math' as math;

class VaultItemIcon extends StatelessWidget {
  final int colorIndex;
  final int iconIndex;
  final List<Color>? gradientColors;

  const VaultItemIcon({
    super.key,
    this.colorIndex = 0,
    this.iconIndex = 0,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: const GradientRotation(math.pi / 10))
            : null,
        border: gradientColors == null
            ? Border.all(
                color: CoconutColors.backgroundColorPaletteLight[colorIndex],
              )
            : null,
      ),
      child: Container(
        margin: EdgeInsets.all(gradientColors != null ? 1.5 : 0),
        decoration: BoxDecoration(
          color: CoconutColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: CoconutColors.backgroundColorPaletteLight[colorIndex],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              bottom: 6,
              child: SvgPicture.asset(
                CustomIcons.getPathByIndex(iconIndex),
                colorFilter: ColorFilter.mode(
                  CoconutColors.colorPalette[colorIndex],
                  BlendMode.srcIn,
                ),
                width: 18.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
