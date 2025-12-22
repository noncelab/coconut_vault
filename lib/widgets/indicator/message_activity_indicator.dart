import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageActivityIndicator extends StatelessWidget {
  final String? message;
  final bool isCupertinoIndicator;
  final EdgeInsets? padding;

  const MessageActivityIndicator({super.key, this.message, this.isCupertinoIndicator = false, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: CoconutBorder.defaultRadius,
        color: message != null ? CoconutColors.white : null,
      ),
      width: MediaQuery.of(context).size.width / 2,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          isCupertinoIndicator
              ? const CupertinoActivityIndicator(color: CoconutColors.black, radius: 24)
              : const CircularProgressIndicator(color: CoconutColors.gray800),
          Visibility(
            visible: message != null,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 20),
              child: Text(message ?? '', style: CoconutTypography.body1_16, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
