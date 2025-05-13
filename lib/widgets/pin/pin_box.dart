import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';

class PinBox extends StatelessWidget {
  final bool isSet;
  final bool disabled;

  const PinBox({super.key, required this.isSet, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: disabled ? MyColors.transparentBlack_15 : MyColors.transparentBlack_06,
        ),
        child: isSet
            ? Padding(
                padding: const EdgeInsets.all(Sizes.size12),
                child: SvgPicture.asset(
                  'assets/svg/coconut-${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.svg',
                  colorFilter: ColorFilter.mode(
                      disabled ? MyColors.transparentBlack_06 : MyColors.black, BlendMode.srcIn),
                ),
              )
            : null);
  }
}
