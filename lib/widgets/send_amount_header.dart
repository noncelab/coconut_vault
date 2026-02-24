import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';

class SendAmountHeader extends StatelessWidget {
  final String amountText;
  final String unitText;
  final int satoshiAmount;
  final VoidCallback? onTap;
  final TextStyle? fiatTextStyle;
  final double topMargin;
  final TextAlign textAlign;
  final String totalCostAmountText;

  const SendAmountHeader({
    super.key,
    required this.amountText,
    required this.unitText,
    required this.satoshiAmount,
    required this.totalCostAmountText,
    this.onTap,
    this.fiatTextStyle,
    this.topMargin = 40,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: topMargin),
          child: Center(
            child: Text.rich(
              TextSpan(
                text: amountText,
                children: <TextSpan>[TextSpan(text: ' $unitText', style: CoconutTypography.heading4_18_Number)],
              ),
              style: CoconutTypography.heading1_32_NumberBold,
              textAlign: textAlign,
              textScaler: const TextScaler.linear(1.0),
            ),
          ),
        ),
        CoconutLayout.spacing_800h,
        Text(
          '${t.psbt_confirmation_screen.total_cost.total(n: '$totalCostAmountText $unitText')}${t.psbt_confirmation_screen.total_cost.sentence}',
          style: CoconutTypography.body3_12_Number.setColor(CoconutColors.gray800),
          textScaler: const TextScaler.linear(1.0),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }
    return GestureDetector(onTap: onTap, child: content);
  }
}
