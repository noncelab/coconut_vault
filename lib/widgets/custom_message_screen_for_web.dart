import 'package:flutter/material.dart';

import 'message_screen_for_web.dart';

class CustomMessageScreenForWeb extends StatelessWidget {
  final String message;
  const CustomMessageScreenForWeb({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MessageScreenForWeb(
          message: '$message...\n웹 브라우저에서 1분 이상 걸릴 수 있으니 기다려 주세요'),
    );
  }
}
