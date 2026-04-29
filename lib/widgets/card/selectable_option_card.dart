import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/fixed_text_scale.dart';
import 'package:flutter/material.dart';

class SelectableOptionCard extends StatelessWidget {
  final String title;
  final String? description;
  final String svgAssetPath;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const SelectableOptionCard({
    super.key,
    required this.title,
    this.description,
    required this.svgAssetPath,
    required this.isSelected,
    required this.onTap,
    this.width = double.infinity,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? CoconutColors.gray150 : CoconutColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CoconutColors.gray800 : CoconutColors.gray200,
            width: isSelected ? 1.0 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
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
                      const SizedBox(height: 2),
                      Text(description!, style: CoconutTypography.body3_12.setColor(CoconutColors.black)),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(bottom: 12, right: 12, child: Image.asset(svgAssetPath)),
          ],
        ),
      ),
    );
  }
}
