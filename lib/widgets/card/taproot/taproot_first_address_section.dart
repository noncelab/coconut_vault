import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/card/address_card.dart';
import 'package:flutter/material.dart';

class TaprootFirstAddressSection extends StatelessWidget {
  const TaprootFirstAddressSection({
    super.key,
    required this.address,
    required this.derivationPath,
    required this.onPressed,
    this.description,
  });

  final String address;
  final String derivationPath;
  final VoidCallback onPressed;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.taproot.common.first_address, style: CoconutTypography.body2_14_Bold),
        if (description != null) Text(description!, style: CoconutTypography.body3_12.setColor(CoconutColors.gray400)),
        CoconutLayout.spacing_200h,
        AddressCard(
          onPressed: onPressed,
          address: address,
          derivationPath: derivationPath,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ],
    );
  }
}
