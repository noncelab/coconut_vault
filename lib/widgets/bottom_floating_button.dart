import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';

class BottomFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const BottomFloatingButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      height: 50,
      child: CupertinoButton(
        borderRadius: BorderRadius.circular(24),
        color: CoconutColors.gray700,
        onPressed: onPressed,
        padding: const EdgeInsets.all(0),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: CoconutColors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
