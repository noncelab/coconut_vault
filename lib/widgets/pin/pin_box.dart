import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PinBox extends StatelessWidget {
  final bool isSet;
  final bool disabled;

  const PinBox({super.key, required this.isSet, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: disabled ? CoconutColors.black.withValues(alpha: 0.15) : CoconutColors.black.withValues(alpha: 0.06),
      ),
      child:
          isSet
              ? Padding(
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/svg/coconut-${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.svg',
                  colorFilter: ColorFilter.mode(
                    disabled ? CoconutColors.black.withValues(alpha: 0.06) : CoconutColors.gray800,
                    BlendMode.srcIn,
                  ),
                ),
              )
              : null,
    );
  }
}
