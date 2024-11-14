// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

abstract class MyColors {
  static const black = Color.fromRGBO(20, 19, 24, 1);
  static const transparentBlack = Color.fromRGBO(0, 0, 0, 0.7);
  static const transparentBlack_03 = Color.fromRGBO(0, 0, 0, 0.03);
  static const transparentBlack_06 = Color.fromRGBO(0, 0, 0, 0.06);
  static const transparentBlack_15 = Color.fromRGBO(0, 0, 0, 0.15);
  static const transparentBlack_30 = Color.fromRGBO(0, 0, 0, 0.3);
  static const transparentBlack_50 = Color.fromRGBO(0, 0, 0, 0.5);
  static const transparentBlack_70 = Color.fromRGBO(0, 0, 0, 0.7);

  static const white = Color.fromRGBO(255, 255, 255, 1);
  static const transparentWhite = Color.fromRGBO(255, 255, 255, 0.2);
  static const transparentWhite_06 = Color.fromRGBO(255, 255, 255, 0.06);
  static const transparentWhite_15 = Color.fromRGBO(255, 255, 255, 0.15);
  static const transparentWhite_20 = Color.fromRGBO(255, 255, 255, 0.2);
  static const transparentWhite_50 = Color.fromRGBO(255, 255, 255, 0.5);
  static const transparentWhite_70 = Color.fromRGBO(255, 255, 255, 0.7);
  static const transparentWhite_90 = Color.fromRGBO(255, 255, 255, 0.9);
  static const transparentWhite_95 = Color.fromRGBO(255, 255, 255, 0.95);

  static const grey = Color.fromRGBO(48, 47, 52, 1);
  static const transparentGrey = Color.fromRGBO(20, 19, 24, 0.15);
  static const lightgrey = Color.fromRGBO(244, 244, 245, 1);
  static const darkgrey = Color.fromRGBO(48, 47, 52, 1);

  static const whiteLilac = Color.fromRGBO(243, 241, 247, 1);
  static const searchbarBackground = Color.fromRGBO(241, 242, 245, 1);
  static const searchbarHint = Color.fromRGBO(154, 158, 168, 1);
  static const searchbarText = Color.fromRGBO(20, 23, 24, 1);

  static const borderGrey = Color.fromRGBO(81, 81, 96, 1);
  static const borderLightgrey = Color.fromRGBO(235, 231, 228, 1);
  static const defaultIcon = Color.fromRGBO(221, 219, 230, 1);
  static const defaultBackground = Color.fromRGBO(255, 255, 255, 0.06);
  static const defaultText = Color.fromRGBO(221, 219, 230, 1);

  static const red = Color.fromRGBO(255, 88, 88, 1.0);
  static const warningText = Color.fromRGBO(206, 91, 111, 1); // color6Red
  static const backgroundActive =
      Color.fromRGBO(145, 179, 242, 0.67); // color4Blue

  static const primary = Color.fromRGBO(222, 255, 88, 1);
  static const secondary = Color.fromRGBO(113, 111, 245, 1.0);

  static const greenyellow = Color.fromRGBO(222, 255, 88, 1);
  static const lightYellow = Color.fromRGBO(255, 255, 224, 1);

  static const warningYellow = Color.fromRGBO(255, 175, 3, 1.0);
  static const warningYellowBackground = Color.fromRGBO(255, 243, 190, 1.0);

  static const oceanBlue = Color.fromRGBO(88, 135, 249, 1);
  static const transparentOceanBlue = Color.fromRGBO(88, 135, 249, 0.7);

  static const skeletonBaseColor = Color.fromARGB(255, 224, 224, 224);
  static const skeletonHighlightColor = Color.fromARGB(255, 245, 245, 245);

  static const cyanblue = Color.fromRGBO(69, 204, 238, 1);

  static const Color dropdownGrey = Color(0xFFEBEBEC);
  static const Color whiteSmoke = Color(0xFFF8F8F8);
  static const Color body2Grey = Color(0xFF706D6D);
  static const Color greyEC = Color(0xFFECECEC);
  static const Color greyE9 = Color(0xFFE9E9E9);
  static const Color grey57 = Color(0xFF575757);
  static const Color grey236 = Color(0xFFECECEC);
  static const Color grey219 = Color(0xFFDBDBDB);
  static const Color black19 = Color(0xFF0F0F0F);

  static const Color divider = Color(0xFFEBEBEB);
  static const Color disabledGrey = Color(0xFF232323);

  static const Color multiSigGradient1 = Color(0xFFB2E774);
  static const Color multiSigGradient2 = Color(0xFF6373EB);
  static const Color multiSigGradient3 = Color(0xFF2ACEC3);
  static const Color linkBlue = Color(0xFF4E83FF);

  static const Color progressbarColorEnabled = Color(0xFF2D2D2D);
  static const Color progressbarColorDisabled = Color(0xFFCFCFCF);
}

// LIGHT MODE
const List<Color> ColorPalette = [
  Color.fromRGBO(163, 100, 217, 1.0), // color0Purple
  Color.fromRGBO(250, 156, 90, 1.0), // color1Apricot
  Color.fromRGBO(254, 204, 47, 1.0), // color2Yellow
  Color.fromRGBO(136, 193, 37, 1.0), // color3Green
  Color.fromRGBO(65, 164, 216, 1.0), // color4Blue
  Color.fromRGBO(238, 101, 121, 1.0), // color5Pink
  Color.fromRGBO(219, 57, 55, 1.0), // color6Red
  Color.fromRGBO(245, 99, 33, 1.0), // color7Orange
  Color.fromRGBO(120, 120, 120, 1.0), // color8Lightgrey
  Color.fromRGBO(51, 191, 184, 1.0), // color9Mint
];

const List<Color> BackgroundColorPalette = [
  Color.fromRGBO(163, 100, 217, 0.13), // color0Purple
  Color.fromRGBO(250, 156, 90, 0.13), // color1Apricot
  Color.fromRGBO(254, 204, 47, 0.13), // color2Yellow
  Color.fromRGBO(178, 193, 37, 0.13), // color3Green
  Color.fromRGBO(65, 164, 216, 0.1), // color4Blue
  Color.fromRGBO(238, 101, 121, 0.12), // color5Pink
  Color.fromRGBO(219, 57, 55, 0.13), // color6Red
  Color.fromRGBO(245, 99, 33, 0.13), // color7Orange
  Color.fromRGBO(101, 101, 101, 0.1), // color8Lightgrey
  Color.fromRGBO(51, 191, 184, 0.1), // color9Mint
];

enum CustomFonts { number, text }

extension FontsExtension on CustomFonts {
  String get getFontFamily {
    switch (this) {
      case CustomFonts.number:
        return 'SpaceGrotesk';
      case CustomFonts.text:
        return 'Pretendard';
      default:
        return 'Pretendard';
    }
  }
}

abstract class Styles {
  static const _fontNumber = 'SpaceGrotesk';
  static const _fontText = 'Pretendard';

  static const TextStyle h1 = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 32,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w700);

  static const TextStyle h2 = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 28,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w700);

  static const TextStyle h3 = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 18,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.1);

  static const TextStyle appbarTitle = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 18,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w500);

  static const TextStyle label = TextStyle(
      fontFamily: _fontText,
      color: MyColors.transparentBlack_70,
      fontSize: 14,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w500);

  static const TextStyle label2 = TextStyle(
      fontFamily: _fontText,
      color: MyColors.transparentBlack_70,
      fontSize: 11,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w500);

  static const TextStyle subLabel = TextStyle(
      fontFamily: _fontText,
      color: MyColors.transparentBlack_70,
      fontSize: 14,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle body1 = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 16,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle body1Bold = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 16,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.bold);

  static const TextStyle body2 = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 14,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle body2Bold = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 14,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.bold);

  static const TextStyle body2Grey = TextStyle(
      fontFamily: _fontText,
      color: MyColors.transparentBlack_30,
      fontSize: 14,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle unit1 = TextStyle(
      fontFamily: _fontNumber,
      color: MyColors.transparentBlack_70,
      fontSize: 24,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle unit2 = TextStyle(
      fontFamily: _fontNumber,
      color: MyColors.transparentBlack_70,
      fontSize: 20,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle warning = TextStyle(
      fontFamily: _fontText,
      color: MyColors.warningText,
      fontSize: 12,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle navHeader = TextStyle(
      fontFamily: _fontText,
      color: Color.fromRGBO(255, 255, 255, 1),
      fontSize: 16,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w500);

  static const TextStyle whiteButtonTitle = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 16,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle CTAButtonTitle = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 16,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.bold);

  static const TextStyle blackButtonTitle = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 14,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle caption = TextStyle(
      fontFamily: _fontText,
      color: MyColors.darkgrey,
      fontSize: 12,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle title5 = TextStyle(
      fontFamily: _fontText,
      color: MyColors.black,
      fontSize: 20,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600);

  static const TextStyle balance1 = TextStyle(
      fontFamily: _fontNumber,
      color: MyColors.black,
      fontSize: 36,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600);

  static const TextStyle balance2 = TextStyle(
      fontFamily: _fontNumber,
      color: MyColors.black,
      fontSize: 14,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400);

  static const TextStyle fee = TextStyle(
      fontFamily: _fontNumber,
      color: MyColors.black,
      fontSize: 22,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600);

  static const TextStyle unit = TextStyle(
    fontFamily: _fontNumber,
    color: MyColors.black,
    fontSize: 18,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headerButtonLabel = TextStyle(
    fontFamily: _fontText,
    color: MyColors.darkgrey,
    fontSize: 11,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
}

abstract class MyBorder {
  static final BorderRadius defaultRadius = BorderRadius.circular(24);
  static final BorderRadius boxDecorationRadius = BorderRadius.circular(8);
}

class Paddings {
  static const EdgeInsets container =
      EdgeInsets.symmetric(horizontal: 10, vertical: 20);
  static const EdgeInsets widgetContainer =
      EdgeInsets.symmetric(horizontal: 24, vertical: 20);
}

class BoxDecorations {
  static BoxDecoration shadowBoxDecoration = BoxDecoration(
    borderRadius: MyBorder.boxDecorationRadius,
    color: Colors.white,
    boxShadow: const [
      BoxShadow(
        color: MyColors.transparentBlack_06,
        spreadRadius: 4,
        blurRadius: 20,
      ),
    ],
  );

  static BoxDecoration boxDecorationWhite = BoxDecoration(
    borderRadius: MyBorder.boxDecorationRadius,
    color: MyColors.transparentWhite_06,
  );

  static BoxDecoration boxDecorationGrey = BoxDecoration(
    borderRadius: MyBorder.defaultRadius,
    color: MyColors.transparentBlack_06,
  );
}
