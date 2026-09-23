import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/build_config.dart';
import 'package:coconut_vault/constants/icon_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 코코넛 볼트 브랜드 마크. 네트워크(mainnet/regtest)에 따라 마크와 색상이 달라짐.
class CoconutVaultLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const CoconutVaultLogo({super.key, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    if (kIsLiteBuild) {
      return _buildLogo(kLiteIconPath, color);
    }

    final isTestnet = NetworkType.currentNetworkType.isTestnet;
    final iconPath = isTestnet ? kCoconutVaultRegtestIconPath : kCoconutVaultIconPath;

    if (color != null) {
      return _buildLogo(iconPath, color);
    }

    if (isTestnet) {
      return _buildLogo(iconPath, CoconutColors.black);
    }

    return ShaderMask(
      shaderCallback: (bounds) => kCoconutMainnetLogoGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: _buildLogo(iconPath, Colors.white),
    );
  }

  Widget _buildLogo(String iconPath, Color? color) {
    return SvgPicture.asset(
      iconPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
