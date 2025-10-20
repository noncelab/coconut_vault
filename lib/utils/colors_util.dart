import 'dart:ui';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';

class CustomColorHelper {
  static Color getColorByEnum(CustomColor color) {
    switch (color) {
      case CustomColor.purple:
        return CoconutColors.colorPalette[0];
      case CustomColor.apricot:
        return CoconutColors.colorPalette[1];
      case CustomColor.yellow:
        return CoconutColors.colorPalette[2];
      case CustomColor.green:
        return CoconutColors.colorPalette[3];
      case CustomColor.blue:
        return CoconutColors.colorPalette[4];
      case CustomColor.pink:
        return CoconutColors.colorPalette[5];
      case CustomColor.red:
        return CoconutColors.colorPalette[6];
      case CustomColor.orange:
        return CoconutColors.colorPalette[7];
      case CustomColor.lightgrey:
        return CoconutColors.colorPalette[8];
      case CustomColor.mint:
        return CoconutColors.colorPalette[9];
      default:
        return CoconutColors.secondaryText;
    }
  }

  static Color getBackgroundColorByEnum(CustomColor color) {
    switch (color) {
      case CustomColor.purple:
        return CoconutColors.backgroundColorPaletteLight[0];
      case CustomColor.apricot:
        return CoconutColors.backgroundColorPaletteLight[1];
      case CustomColor.yellow:
        return CoconutColors.backgroundColorPaletteLight[2];
      case CustomColor.green:
        return CoconutColors.backgroundColorPaletteLight[3];
      case CustomColor.blue:
        return CoconutColors.backgroundColorPaletteLight[4];
      case CustomColor.pink:
        return CoconutColors.backgroundColorPaletteLight[5];
      case CustomColor.red:
        return CoconutColors.backgroundColorPaletteLight[6];
      case CustomColor.orange:
        return CoconutColors.backgroundColorPaletteLight[7];
      case CustomColor.lightgrey:
        return CoconutColors.backgroundColorPaletteLight[8];
      case CustomColor.mint:
        return CoconutColors.backgroundColorPaletteLight[9];
      default:
        return CoconutColors.white.withValues(alpha: 0.06);
    }
  }

  static int getIntFromColor(CustomColor color) {
    switch (color) {
      case CustomColor.purple:
        return 0;
      case CustomColor.apricot:
        return 1;
      case CustomColor.yellow:
        return 2;
      case CustomColor.green:
        return 3;
      case CustomColor.blue:
        return 4;
      case CustomColor.pink:
        return 5;
      case CustomColor.red:
        return 6;
      case CustomColor.orange:
        return 7;
      case CustomColor.lightgrey:
        return 8;
      case CustomColor.mint:
        return 9;
      default:
        throw Exception('Invalid color enum: $color');
    }
  }

  static Color getColorByIndex(int index) {
    if (index < 0 || index > 9) {
      return CoconutColors.secondaryText;
    }

    return CoconutColors.colorPalette[index % CoconutColors.colorPalette.length];
  }

  static Color getBackgroundColorByIndex(int index) {
    if (index < 0 || index > 9) {
      return CoconutColors.white.withValues(alpha: 0.06);
    }

    return CoconutColors.backgroundColorPaletteLight[index % CoconutColors.colorPalette.length];
  }

  static List<Color> getGradientColors(List<MultisigSigner> list) {
    if (list.isEmpty) {
      return [CoconutColors.borderLightGray];
    }

    Color getColor(MultisigSigner item) {
      return item.innerVaultId != null
          ? CustomColorHelper.getColorByIndex(item.colorIndex ?? 0)
          : CoconutColors.borderLightGray;
    }

    // 2개인 경우
    if (list.length == 2) {
      return [getColor(list[0]), getColor(list[1])];
    }

    return [getColor(list[0]), getColor(list[1]), getColor(list[2])];
  }
}

enum CustomColor { purple, apricot, yellow, green, blue, pink, red, orange, lightgrey, mint }
