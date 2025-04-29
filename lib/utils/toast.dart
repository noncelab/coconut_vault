import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';

import '../styles.dart';

class MyToast {
  static Widget getToastWidget(String? content) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: MyColors.transparentBlack_30,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(content ?? t.copied, style: CoconutTypography.body2_14),
        ],
      ),
    );

    return toast;
  }
}
