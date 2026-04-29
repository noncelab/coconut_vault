import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/fixed_text_scale.dart';
import 'package:flutter/material.dart';

class SelectableOptionCard extends StatefulWidget {
  final String title;
  final String? description;
  final String pngAssetPath;
  final VoidCallback onTap;
  final double width;
  final double height;

  const SelectableOptionCard({
    super.key,
    required this.title,
    this.description,
    required this.pngAssetPath,
    required this.onTap,
    this.width = double.infinity,
    required this.height,
  });

  @override
  State<SelectableOptionCard> createState() => _SelectableOptionCardState();
}

class _SelectableOptionCardState extends State<SelectableOptionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _isPressed ? CoconutColors.gray150 : CoconutColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isPressed ? CoconutColors.gray800 : CoconutColors.gray200, width: 1.0),
        ),
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            Positioned(bottom: 12, right: 12, child: Image.asset(widget.pngAssetPath)),
            Positioned(
              top: 20,
              left: 20,
              right: 13,
              child: FixedTextScale(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title, style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.black)),
                    if (widget.description != null) ...[
                      CoconutLayout.spacing_50h,
                      Text(widget.description!, style: CoconutTypography.body3_12.setColor(CoconutColors.black)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
