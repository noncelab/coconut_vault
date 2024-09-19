import 'package:flutter/material.dart';

import '../styles.dart';

class MyToast {
  static Widget getToastWidget() {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: MyColors.transparentBlack_30,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("복사 완료", style: Styles.body2),
        ],
      ),
    );

    return toast;
  }
}
