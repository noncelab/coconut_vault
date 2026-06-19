import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final List<MapEntry<String, String>> infoList;

  const InfoBox({super.key, required this.infoList});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: CoconutColors.gray200),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (int index = 0; index < infoList.length; index++) ...[
            if (index > 0) CoconutLayout.spacing_300h,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(infoList[index].key, style: CoconutTypography.body2_14),
                Expanded(
                  child: Text(infoList[index].value, style: CoconutTypography.body2_14_Bold, textAlign: TextAlign.end),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
