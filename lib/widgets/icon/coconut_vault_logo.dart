import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/icon_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 코코넛 볼트 브랜드 마크. 네트워크(mainnet/regtest)에 따라 마크와 색상이 달라짐.
class CoconutVaultLogo extends StatelessWidget {
  final double size;

  const CoconutVaultLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isTestnet = NetworkType.currentNetworkType.isTestnet;
    final logo = SvgPicture.asset(
      isTestnet ? kCoconutVaultRegtestIconPath : kCoconutVaultIconPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(isTestnet ? CoconutColors.black : Colors.white, BlendMode.srcIn),
    );

    if (isTestnet) {
      return logo;
    }

    return ShaderMask(
      shaderCallback: (bounds) => kCoconutMainnetLogoGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: logo,
    );
  }
}
