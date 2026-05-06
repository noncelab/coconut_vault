import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TimelineStepIndicator extends StatefulWidget {
  final List<TimelineStepItem> timelineStepItemList;

  const TimelineStepIndicator({super.key, required this.timelineStepItemList});

  @override
  State<TimelineStepIndicator> createState() => _TimelineStepIndicatorState();
}

class _TimelineStepIndicatorState extends State<TimelineStepIndicator> {
  int? _currentIndex;
  int? _animatingConnectorIndex;
  late int _completedUntilIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialCurrentIndex;
    _completedUntilIndex = (_currentIndex ?? _initialCompletedUntilIndex + 1) - 1;
  }

  @override
  void didUpdateWidget(covariant TimelineStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timelineStepItemList != widget.timelineStepItemList) {
      _currentIndex = _initialCurrentIndex;
      _animatingConnectorIndex = null;
      _completedUntilIndex = (_currentIndex ?? _initialCompletedUntilIndex + 1) - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < widget.timelineStepItemList.length; index++)
          _TimelineStepTile(
            item: _itemWithDisplayStatus(index),
            originalStatus: widget.timelineStepItemList[index].status,
            nextOriginalStatus:
                index == widget.timelineStepItemList.length - 1 ? null : widget.timelineStepItemList[index + 1].status,
            isLast: index == widget.timelineStepItemList.length - 1,
            isConnectorAnimating: _animatingConnectorIndex == index,
            onCurrentAnimationCompleted: () => _completeCurrentStep(index),
            onConnectorAnimationCompleted: () => _completeConnectorAnimation(index),
          ),
      ],
    );
  }

  int get _initialCurrentIndex {
    final currentIndex = widget.timelineStepItemList.indexWhere((item) => item.status == TimelineStepStatus.current);
    if (currentIndex >= 0) {
      return currentIndex;
    }

    final firstNonCompletedIndex = widget.timelineStepItemList.indexWhere(
      (item) => item.status != TimelineStepStatus.completed,
    );
    return firstNonCompletedIndex >= 0 ? firstNonCompletedIndex : 0;
  }

  int get _initialCompletedUntilIndex {
    var lastCompletedIndex = -1;
    for (int index = 0; index < widget.timelineStepItemList.length; index++) {
      if (widget.timelineStepItemList[index].status != TimelineStepStatus.completed) {
        break;
      }
      lastCompletedIndex = index;
    }
    return lastCompletedIndex;
  }

  void _completeCurrentStep(int completedIndex) {
    if (_currentIndex != completedIndex || _animatingConnectorIndex != null) {
      return;
    }

    final nextIndex = completedIndex + 1;
    setState(() {
      _completedUntilIndex = completedIndex;
      if (nextIndex >= widget.timelineStepItemList.length) {
        _currentIndex = null;
        return;
      }

      _currentIndex = null;
      _animatingConnectorIndex = completedIndex;
    });
  }

  void _completeConnectorAnimation(int connectorIndex) {
    if (_animatingConnectorIndex != connectorIndex) {
      return;
    }

    final nextIndex = connectorIndex + 1;
    setState(() {
      _animatingConnectorIndex = null;
      _currentIndex = nextIndex;
    });
  }

  TimelineStepItem _itemWithDisplayStatus(int index) {
    final item = widget.timelineStepItemList[index];
    final status =
        index <= _completedUntilIndex
            ? TimelineStepStatus.completed
            : index == _currentIndex
            ? TimelineStepStatus.current
            : item.status;

    return item.copyWith(status: status);
  }
}

class _TimelineStepTile extends StatelessWidget {
  static const double _indicatorColumnWidth = 48;
  static const double _nodeSize = 9;
  static const double _currentNodeOuterSize = 24;
  static const double _lineHeight = 90;

  final TimelineStepItem item;
  final TimelineStepStatus originalStatus;
  final TimelineStepStatus? nextOriginalStatus;
  final bool isLast;
  final bool isConnectorAnimating;
  final VoidCallback onCurrentAnimationCompleted;
  final VoidCallback onConnectorAnimationCompleted;

  const _TimelineStepTile({
    required this.item,
    required this.originalStatus,
    required this.nextOriginalStatus,
    required this.isLast,
    required this.isConnectorAnimating,
    required this.onCurrentAnimationCompleted,
    required this.onConnectorAnimationCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _indicatorColumnWidth,
          child: Column(
            children: [
              _TimelineNode(
                status: item.status,
                nodeSize: _nodeSize,
                currentNodeOuterSize: _currentNodeOuterSize,
                onCurrentAnimationCompleted: onCurrentAnimationCompleted,
              ),
              if (!isLast)
                SizedBox(
                  height: _lineHeight,
                  child: _TimelineConnector(
                    status: item.status,
                    originalStatus: originalStatus,
                    nextOriginalStatus: nextOriginalStatus,
                    isAnimating: isConnectorAnimating,
                    onAnimationCompleted: onConnectorAnimationCompleted,
                  ),
                ),
            ],
          ),
        ),
        CoconutLayout.spacing_400w,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _currentNodeOuterSize,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: _titleStyle,
                    child: Text(item.title),
                  ),
                ),
              ),
              CoconutLayout.spacing_200h,
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: _descriptionStyle,
                child: Text(item.description),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle get _titleStyle {
    final color =
        item.status == TimelineStepStatus.current || item.status == TimelineStepStatus.completed
            ? CoconutColors.black
            : CoconutColors.gray350;
    return CoconutTypography.body2_14.setColor(color);
  }

  TextStyle get _descriptionStyle {
    final color =
        item.status == TimelineStepStatus.current || item.status == TimelineStepStatus.completed
            ? CoconutColors.gray500
            : CoconutColors.gray200;
    return CoconutTypography.body3_12.setColor(color);
  }
}

class _TimelineNode extends StatelessWidget {
  final TimelineStepStatus status;
  final double nodeSize;
  final double currentNodeOuterSize;
  final VoidCallback onCurrentAnimationCompleted;

  const _TimelineNode({
    required this.status,
    required this.nodeSize,
    required this.currentNodeOuterSize,
    required this.onCurrentAnimationCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: currentNodeOuterSize,
      height: currentNodeOuterSize,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween<double>(begin: 0.72, end: 1).animate(animation), child: child),
          );
        },
        child: _buildNodeContent(),
      ),
    );
  }

  Widget _buildNodeContent() {
    if (status == TimelineStepStatus.current) {
      return KeyedSubtree(
        key: const ValueKey(TimelineStepStatus.current),
        child: _TimelineCurrentLottie(onCompleted: onCurrentAnimationCompleted),
      );
    }

    if (status == TimelineStepStatus.completed) {
      return const KeyedSubtree(key: ValueKey(TimelineStepStatus.completed), child: _TimelineCompletedLottie());
    }

    return Center(
      key: ValueKey(status),
      child: Center(
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: const BoxDecoration(color: CoconutColors.gray300, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _TimelineCompletedLottie extends StatefulWidget {
  const _TimelineCompletedLottie();

  @override
  State<_TimelineCompletedLottie> createState() => _TimelineCompletedLottieState();
}

class _TimelineCompletedLottieState extends State<_TimelineCompletedLottie> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/dot-ripple-twice.json',
      controller: _controller,
      repeat: false,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        _controller
          ..duration = composition.duration
          ..value = 1;
      },
    );
  }
}

class _TimelineCurrentLottie extends StatefulWidget {
  final VoidCallback onCompleted;

  const _TimelineCurrentLottie({required this.onCompleted});

  @override
  State<_TimelineCurrentLottie> createState() => _TimelineCurrentLottieState();
}

class _TimelineCurrentLottieState extends State<_TimelineCurrentLottie> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)..addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/dot-ripple-twice.json',
      controller: _controller,
      repeat: false,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        _controller
          ..duration = composition.duration
          ..forward(from: 0);
      },
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final TimelineStepStatus status;
  final TimelineStepStatus originalStatus;
  final TimelineStepStatus? nextOriginalStatus;
  final bool isAnimating;
  final VoidCallback onAnimationCompleted;

  const _TimelineConnector({
    required this.status,
    required this.originalStatus,
    required this.nextOriginalStatus,
    required this.isAnimating,
    required this.onAnimationCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDashed = originalStatus == TimelineStepStatus.future || nextOriginalStatus == TimelineStepStatus.future;
    final isCompleted = status == TimelineStepStatus.completed;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isAnimating || isCompleted ? 1 : 0),
      duration: isAnimating ? const Duration(milliseconds: 650) : Duration.zero,
      curve: Curves.easeInOut,
      onEnd: isAnimating ? onAnimationCompleted : null,
      builder: (context, progress, child) {
        return CustomPaint(
          painter: _TimelineConnectorPainter(
            baseColor: CoconutColors.gray300,
            progressColor: CoconutColors.gray800,
            progress: progress,
            isDashed: isDashed,
          ),
          child: child,
        );
      },
      child: const SizedBox(width: 24, height: double.infinity),
    );
  }
}

class _TimelineConnectorPainter extends CustomPainter {
  final Color baseColor;
  final Color progressColor;
  final double progress;
  final bool isDashed;

  const _TimelineConnectorPainter({
    required this.baseColor,
    required this.progressColor,
    required this.progress,
    required this.isDashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = baseColor
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
    final centerX = size.width / 2;

    if (!isDashed) {
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
    } else {
      _drawDashedLine(canvas, paint, centerX, size.height);
    }

    if (progress <= 0) {
      return;
    }

    final progressPaint =
        Paint()
          ..color = progressColor
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
    final progressHeight = size.height * progress.clamp(0, 1);
    if (!isDashed) {
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, progressHeight), progressPaint);
      return;
    }

    _drawDashedLine(canvas, progressPaint, centerX, progressHeight);
  }

  void _drawDashedLine(Canvas canvas, Paint paint, double centerX, double height) {
    const dashHeight = 5.0;
    const dashSpace = 6.0;
    double startY = 0;
    while (startY < height) {
      final endY = startY + dashHeight > height ? height : startY + dashHeight;
      canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineConnectorPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progress != progress ||
        oldDelegate.isDashed != isDashed;
  }
}

class TimelineStepItem {
  final String title;
  final String description;
  final TimelineStepStatus status;

  const TimelineStepItem({required this.title, required this.description, required this.status});

  TimelineStepItem copyWith({TimelineStepStatus? status}) {
    return TimelineStepItem(title: title, description: description, status: status ?? this.status);
  }
}

enum TimelineStepStatus { completed, current, upcoming, future }
