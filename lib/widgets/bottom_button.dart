import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const BottomButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      borderRadius: BorderRadius.circular(24),
      color: Colors.black,
      onPressed: onPressed,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, // 기기 너비의 80%
        height: 40,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
