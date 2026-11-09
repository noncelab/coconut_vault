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

  /// Shown above the amount when set.
  final String? title;

  /// Replaces the total cost line when set.
  final String? note;

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
    this.title,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.only(top: topMargin),
            child: Text(
              title!,
              style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.gray800),
              textScaler: const TextScaler.linear(1.0),
            ),
          ),
        Container(
          margin: EdgeInsets.only(top: title != null ? 8 : topMargin),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            note ??
                '${t.psbt_confirmation_screen.total_cost.total(n: '$totalCostAmountText $unitText')}${t.psbt_confirmation_screen.total_cost.sentence}',
            style: CoconutTypography.body3_12_Number.setColor(CoconutColors.gray800),
            textAlign: TextAlign.center,
            textScaler: const TextScaler.linear(1.0),
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }
    return GestureDetector(onTap: onTap, child: content);
  }
}
