import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class CountdownSpinner extends StatefulWidget {
  final int startSeconds;
  final VoidCallback? onCompleted;

  const CountdownSpinner({super.key, this.startSeconds = 5, this.onCompleted});

  @override
  State<CountdownSpinner> createState() => _CountdownSpinnerState();
}

class _CountdownSpinnerState extends State<CountdownSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentSeconds;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.startSeconds;

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentSeconds == 1) {
          widget.onCompleted?.call();
        } else {
          setState(() {
            _currentSeconds--;
          });
          _controller.forward(from: 0);
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final minSide = size.shortestSide; // 짧은 쪽 기준(항상 원형을 그리도록)
            return SizedBox(
              width: minSide,
              height: minSide,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 1.5,
                    backgroundColor: CoconutColors.white,
                    valueColor: const AlwaysStoppedAnimation(CoconutColors.gray600),
                  );
                },
              ),
            );
          },
        ),
        Text('$_currentSeconds', style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.gray600)),
      ],
    );
  }
}
