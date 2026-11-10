import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/text/mfp_text.dart';
import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final List<MapEntry<String, String>> infoList;
  final String? masterFingerprint;

  const InfoBox({super.key, required this.infoList, this.masterFingerprint});

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final info in infoList)
        _buildRow(info.key, Text(info.value, style: CoconutTypography.body2_14_Bold, textAlign: TextAlign.end)),
      if (masterFingerprint != null)
        _buildRow(
          t.mfp,
          Align(
            alignment: Alignment.centerRight,
            child: MfpText(mfp: masterFingerprint!, style: CoconutTypography.body2_14_Bold),
          ),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: CoconutColors.gray200),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[if (index > 0) CoconutLayout.spacing_300h, rows[index]],
        ],
      ),
    );
  }

  Widget _buildRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: CoconutTypography.body2_14), Expanded(child: value)],
    );
  }
}
