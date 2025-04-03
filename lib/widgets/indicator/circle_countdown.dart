import 'dart:async';
import 'package:flutter/material.dart';

class CircleCountdown extends StatefulWidget {
  final int startSeconds;
  final VoidCallback? onCompleted;

  const CircleCountdown({
    super.key,
    this.startSeconds = 5,
    this.onCompleted,
  });

  @override
  State<CircleCountdown> createState() => _CircleCountdownState();
}

class _CircleCountdownState extends State<CircleCountdown>
    with SingleTickerProviderStateMixin {
  late int _currentSeconds;
  Timer? _timer;
  double _progress = 1.0;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.startSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds <= 1) {
        timer.cancel();
        widget.onCompleted?.call();
      }
      setState(() {
        _currentSeconds--;
        _progress = _currentSeconds / widget.startSeconds;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: _progress,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        Text(
          '$_currentSeconds',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
