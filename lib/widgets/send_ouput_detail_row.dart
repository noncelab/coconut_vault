import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:flutter/material.dart';

class SendOutputDetailRow extends StatelessWidget {
  final String label;
  final String address;
  final int amountSats;
  final bool isChange;
  final BitcoinUnit currentUnit;

  const SendOutputDetailRow({
    super.key,
    required this.label,
    required this.address,
    required this.amountSats,
    required this.isChange,
    required this.currentUnit,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = currentUnit.displayBitcoinAmount(amountSats, withUnit: true);
    final valueColor = isChange ? CoconutColors.cyan : CoconutColors.gray900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(label, style: CoconutTypography.body2_14.setColor(CoconutColors.gray700)),
          ),
        ),
        CoconutLayout.spacing_300w,
        Flexible(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: address),
                    TextSpan(
                      text: ' | ',
                      style: CoconutTypography.body3_12_NumberBold.copyWith(color: CoconutColors.gray350),
                    ),
                    TextSpan(text: amountText),
                  ],
                ),
                textAlign: TextAlign.right,
                style: CoconutTypography.body3_12_NumberBold.copyWith(color: valueColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
