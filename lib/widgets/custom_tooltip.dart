import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';

enum TooltipType {
  info('info', 4, 'assets/svg/tooltip/info.svg'),
  normal('normal', 8, 'assets/svg/tooltip/normal.svg'),
  success('success', 3, 'assets/svg/tooltip/success.svg'),
  warning('warning', 2, 'assets/svg/tooltip/warning.svg'),
  error('error', 5, 'assets/svg/tooltip/error.svg');

  const TooltipType(this.code, this.colorIndex, this.svgPath);
  final String code;
  final int colorIndex;
  final String svgPath;

  factory TooltipType.getByCode(String code) {
    return TooltipType.values.firstWhere((value) => value.code == code);
  }
}

class CustomTooltip extends StatefulWidget {
  final RichText richText;
  final TooltipType type;
  final bool showIcon;

  const CustomTooltip(
      {super.key,
      required this.richText,
      this.type = TooltipType.info,
      required this.showIcon});

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  late Color _borderColor;
  late Color _backgroundColor;
  late SvgPicture _icon;

  @override
  void initState() {
    super.initState();
    Color color = ColorPalette[widget.type.colorIndex];
    _borderColor = color.withOpacity(0.7);
    _backgroundColor =
        BackgroundColorPalette[widget.type.colorIndex].withOpacity(0.18);
    _icon = SvgPicture.asset(widget.type.svgPath,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn), width: 18);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: MyColors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(width: 0.4, color: _borderColor)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.showIcon)
                Container(
                  padding: const EdgeInsets.only(right: 8),
                  child: _icon,
                ),
              Expanded(child: widget.richText)
            ])));
  }
}
