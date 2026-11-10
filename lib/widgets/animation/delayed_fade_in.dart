import 'dart:async';

import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:flutter/material.dart';

class DelayedFadeIn extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final Widget child;

  const DelayedFadeIn({
    super.key,
    required this.delay,
    this.duration = const Duration(milliseconds: 400),
    required this.child,
  });

  @override
  State<DelayedFadeIn> createState() => _DelayedFadeInState();
}

class _DelayedFadeInState extends State<DelayedFadeIn> {
  Timer? _timer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay <= Duration.zero) {
      _isVisible = true;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }
    return widget.child.fadeInAnimation(duration: widget.duration);
  }
}
