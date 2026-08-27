import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomTooltip {
  /// QR 스캐너와 같이 뒷 배경이 어두운 경우 paddingTop을 20으로 설정해야 합니다.
  static Widget buildInfoTooltip(
    BuildContext context, {
    required RichText richText,
    bool isBackgroundWhite = true,
    double paddingTop = 4,
    Color? backgroundColor,
    Color? borderColor,
    EdgeInsets? padding,
    bool showIcon = true,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.only(top: paddingTop, left: 16, right: 16),
      child: CoconutToolTip(
        backgroundColor: backgroundColor ?? (isBackgroundWhite ? CoconutColors.gray150 : CoconutColors.gray100),
        borderColor: borderColor ?? (isBackgroundWhite ? Colors.transparent : CoconutColors.gray400),
        showIcon: showIcon,
        icon:
            showIcon
                ? SvgPicture.asset(
                  'assets/svg/circle-info.svg',
                  width: 20,
                  colorFilter: const ColorFilter.mode(CoconutColors.black, BlendMode.srcIn),
                )
                : null,
        tooltipType: CoconutTooltipType.fixed,
        richText: richText,
      ),
    );
  }
}
