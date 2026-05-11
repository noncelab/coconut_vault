import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/fixed_text_scale.dart';
import 'package:flutter/material.dart';

class SelectableOptionCard extends StatelessWidget {
  final String title;
  final String? description;
  final String bottomAssetPath;
  final double? imageScale;
  final double? imageWidth;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool isDisabled;

  const SelectableOptionCard({
    super.key,
    required this.title,
    this.description,
    required this.bottomAssetPath,
    this.imageScale,
    this.imageWidth,
    required this.isSelected,
    required this.onTap,
    this.width = double.infinity,
    required this.height,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShrinkAnimationButton(
      onPressed: onTap,
      defaultColor: CoconutColors.white,
      pressedColor: CoconutColors.gray150,
      borderRadius: 20,
      border: Border.all(color: Colors.transparent, width: 0.0),
      isActive: isDisabled ? false : true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? CoconutColors.gray800 : CoconutColors.gray200,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Image.asset(bottomAssetPath, scale: imageScale, width: imageWidth),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 13,
              child: FixedTextScale(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.black)),
                    if (description != null) ...[
                      CoconutLayout.spacing_50h,
                      Text(description!, style: CoconutTypography.body3_12.setColor(CoconutColors.black)),
                    ],
                  ],
                ),
              ),
            ),
            if (isDisabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: CoconutColors.gray150.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
