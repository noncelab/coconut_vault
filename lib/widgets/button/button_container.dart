import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';

class ButtonContainer extends StatelessWidget {
  final Widget child;

  const ButtonContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: CoconutColors.black.withOpacity(0.06),
        ),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), child: child));
  }
}
