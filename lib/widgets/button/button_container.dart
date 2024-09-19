import 'package:flutter/cupertino.dart';
import 'package:coconut_vault/styles.dart';

class ButtonContainer extends StatelessWidget {
  final Widget child;

  const ButtonContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: MyColors.transparentBlack_06,
        ),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: child));
  }
}
