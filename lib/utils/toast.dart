import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class MyToast {
  static Widget getToastWidget(String content) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: CoconutColors.gray200,
        boxShadow: [
          BoxShadow(
            color: CoconutColors.gray200.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(-2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(content, style: CoconutTypography.body2_14.setColor(CoconutColors.black)),
        ],
      ),
    );

    return toast;
  }
}
