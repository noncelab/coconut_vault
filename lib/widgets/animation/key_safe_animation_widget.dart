import 'dart:async';
import 'dart:collection';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/providers/view_model/mutlisig_quorum_selection_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class KeySafeAnimationWidget extends StatefulWidget {
  final int requiredCount;
  final int totalCount;
  final int buttonClickedCount;

  const KeySafeAnimationWidget({
    super.key,
    required this.requiredCount,
    required this.totalCount,
    required this.buttonClickedCount,
  });

  @override
  State<KeySafeAnimationWidget> createState() => _KeySafeAnimationWidgetState();
}

class _KeySafeAnimationWidgetState extends State<KeySafeAnimationWidget> {
  final Queue _progressQueue = Queue<QueueDataClass>();
  final Duration _duration = const Duration(milliseconds: 1000);
  double _animatedOpacityValue = 0.0;
  double _progressValue_1 = 0;
  double _progressValue_2 = 0;
  double _progressValue_3 = 0;
  bool _keyActive_1 = false;
  bool _keyActive_2 = false;
  bool _keyActive_3 = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      _keyActive_1
                          ? SvgPicture.asset('assets/svg/key-icon.svg', width: 20)
                          : SvgPicture.asset(
                              'assets/svg/key-icon.svg',
                              width: 20,
                              colorFilter: const ColorFilter.mode(CoconutColors.gray350, BlendMode.srcIn),
                            ),
                      const SizedBox(width: 30),
                      Expanded(child: _buildProgressBar(0)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Visibility(
                    visible: widget.totalCount == 3,
                    child: Row(
                      children: [
                        _keyActive_2
                            ? SvgPicture.asset('assets/svg/key-icon.svg', width: 20)
                            : SvgPicture.asset(
                                'assets/svg/key-icon.svg',
                                width: 20,
                                colorFilter: const ColorFilter.mode(CoconutColors.gray350, BlendMode.srcIn),
                              ),
                        const SizedBox(width: 30),
                        Expanded(child: _buildProgressBar(1)),
                      ],
                    ),
                  ),
                  widget.totalCount == 3 ? const SizedBox(height: 24) : Container(),
                  Row(
                    children: [
                      _keyActive_3
                          ? SvgPicture.asset('assets/svg/key-icon.svg', width: 20)
                          : SvgPicture.asset(
                              'assets/svg/key-icon.svg',
                              width: 20,
                              colorFilter: const ColorFilter.mode(CoconutColors.gray350, BlendMode.srcIn),
                            ),
                      const SizedBox(width: 30),
                      Expanded(child: _buildProgressBar(2)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            _animatedOpacityValue == 1
                ? SvgPicture.asset('assets/svg/safe-bit.svg', width: 50)
                : SvgPicture.asset('assets/svg/safe.svg', width: 50),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant KeySafeAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // buttonClickedCount가 변경된 경우 애니메이션 초기화
    if (widget.buttonClickedCount != oldWidget.buttonClickedCount) {
      stopAnimationProgress();
      startAnimationProgress(widget.totalCount, widget.requiredCount, widget.buttonClickedCount);
    }
  }

  @override
  void initState() {
    super.initState();
    startAnimationProgress(widget.totalCount, widget.requiredCount, widget.buttonClickedCount);
  }

  void startAnimationProgress(int n, int m, int buttonCountAtStart) async {
    stopAnimationProgress();
    _progressQueue.add(QueueDataClass(count: widget.buttonClickedCount, entity: _getQueueEntity(n, m)));

    final animationSteps = _getAnimationSteps(n, m);

    for (final step in animationSteps) {
      if (!_canRunCurrentProgress(buttonCountAtStart, _getQueueEntity(n, m))) return;

      if (step.type == AnimationStepType.activateKey) {
        _activeKey(step.keyIndex!);
      } else if (step.type == AnimationStepType.runProgress) {
        _runProgress(step.keyIndex!, _getQueueEntity(n, m));
      } else if (step.type == AnimationStepType.changeOpacity) {
        _changeOpacityValue(step.opacityValue!);
      } else if (step.type == AnimationStepType.delay) {
        await Future.delayed(step.duration!);
      }
    }
  }

  List<AnimationStep> _getAnimationSteps(int n, int m) {
    if (n == 2 && m == 1) {
      return [
        AnimationStep.activateKey(1),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(1),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
        AnimationStep.delay(const Duration(milliseconds: 2000)),
        AnimationStep.changeOpacity(false),
        AnimationStep.activateKey(3),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(3),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
      ];
    } else if (n == 2 && m == 2) {
      return [
        AnimationStep.activateKey(1),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(1),
        AnimationStep.delay(_duration),
        AnimationStep.activateKey(3),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(3),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
      ];
    } else if (n == 3 && m == 1) {
      return [
        AnimationStep.activateKey(1),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(1),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
        AnimationStep.delay(const Duration(milliseconds: 2000)),
        AnimationStep.changeOpacity(false),
        AnimationStep.activateKey(2),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(2),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
        AnimationStep.delay(const Duration(milliseconds: 2000)),
        AnimationStep.changeOpacity(false),
        AnimationStep.activateKey(3),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(3),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
      ];
    } else if (n == 3 && m == 2) {
      return [
        AnimationStep.activateKey(1),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(1),
        AnimationStep.delay(_duration),
        AnimationStep.activateKey(2),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(2),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
        AnimationStep.delay(const Duration(milliseconds: 1000)),
        AnimationStep.changeOpacity(false),
        AnimationStep.activateKey(1),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(1),
        AnimationStep.delay(_duration),
        AnimationStep.activateKey(3),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(3),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
        AnimationStep.delay(const Duration(milliseconds: 2000)),
        AnimationStep.changeOpacity(false),
        AnimationStep.activateKey(2),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(2),
        AnimationStep.delay(_duration),
        AnimationStep.activateKey(3),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(3),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
      ];
    } else if (n == 3 && m == 3) {
      return [
        AnimationStep.activateKey(1),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(1),
        AnimationStep.delay(_duration),
        AnimationStep.activateKey(2),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(2),
        AnimationStep.delay(_duration),
        AnimationStep.activateKey(3),
        AnimationStep.delay(_duration),
        AnimationStep.runProgress(3),
        AnimationStep.delay(_duration),
        AnimationStep.changeOpacity(true),
      ];
    }

    return [];
  }

  void stopAnimationProgress() {
    _progressQueue.clear();
    setState(() {
      _keyActive_1 = false;
      _keyActive_2 = false;
      _keyActive_3 = false;
      _animatedOpacityValue = 0.0;
      _progressValue_1 = 0.0;

      _progressValue_2 = 0.0;
      _progressValue_3 = 0.0;
    });
  }

  void _activeKey(int num) {
    setState(() {
      if (num == 1) {
        _keyActive_1 = true;
      } else if (num == 2) {
        _keyActive_2 = true;
      } else if (num == 3) {
        _keyActive_3 = true;
      }
    });
  }

  Widget _buildProgressBar(int key) {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        borderRadius: BorderRadius.circular(12),
        value: key == 0
            ? _progressValue_1
            : key == 1
                ? _progressValue_2
                : _progressValue_3,
        color: CoconutColors.gray800,
        backgroundColor: CoconutColors.gray350,
      ),
    );
  }

  bool _canRunCurrentProgress(int buttonCountAtStart, QueueEntity entity) {
    if (!mounted ||
        _progressQueue.isEmpty ||
        buttonCountAtStart != widget.buttonClickedCount ||
        entity != _progressQueue.last.entity) {
      return false;
    }
    return true;
  }

  void _changeOpacityValue(bool value) {
    if (!mounted) return;
    setState(() {
      if (!value) {
        _animatedOpacityValue = 0;
        _keyActive_1 = false;
        _keyActive_2 = false;
        _keyActive_3 = false;

        _progressValue_1 = 0;
        _progressValue_2 = 0;
        _progressValue_3 = 0;
      } else {
        _animatedOpacityValue = value ? 1 : 0;
      }
    });
  }

  QueueEntity _getQueueEntity(int n, int m) {
    // 로직에 따라 올바른 QueueEntity를 반환
    if (n == 2 && m == 1) return QueueEntity.n2m1;
    if (n == 2 && m == 2) return QueueEntity.n2m2;
    if (n == 3 && m == 1) return QueueEntity.n3m1;
    if (n == 3 && m == 2) return QueueEntity.n3m2;
    return QueueEntity.n3m3;
  }

  void _runProgress(int num, QueueEntity queueEntity) {
    if (_progressQueue.isEmpty ||
        _progressQueue.last.entity != queueEntity && _progressQueue.last.count != widget.buttonClickedCount) {
      stopAnimationProgress();
      return;
    }
    switch (num) {
      case 1:
        {
          Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (_progressQueue.isEmpty ||
                (_progressQueue.last.entity != queueEntity && _progressQueue.last.count != widget.buttonClickedCount)) {
              timer.cancel();
              return;
            }
            if (_progressValue_1 >= 1.0) {
              timer.cancel();
            } else {
              if (!mounted) return;
              setState(() {
                _progressValue_1 += 0.01;
              });
            }
          });
          break;
        }
      case 2:
        {
          Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (_progressQueue.isEmpty ||
                _progressQueue.last.entity != queueEntity ||
                _progressQueue.last.count != widget.buttonClickedCount) {
              timer.cancel();
              return;
            }
            if (_progressValue_2 >= 1.0) {
              timer.cancel();
            } else {
              if (!mounted) return;
              setState(() {
                _progressValue_2 += 0.01;
              });
            }
          });
          break;
        }
      case 3:
        {
          Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (_progressQueue.isEmpty ||
                _progressQueue.last.entity != queueEntity ||
                _progressQueue.last.count != widget.buttonClickedCount) {
              timer.cancel();
              return;
            }
            if (_progressValue_3 >= 1.0) {
              timer.cancel();
            } else {
              if (!mounted) return;
              setState(() {
                _progressValue_3 += 0.01;
              });
            }
          });
          break;
        }
    }
  }
}

class AnimationStep {
  final AnimationStepType type;
  final int? keyIndex;
  final bool? opacityValue;
  final Duration? duration;

  const AnimationStep._({required this.type, this.keyIndex, this.opacityValue, this.duration});

  factory AnimationStep.activateKey(int keyIndex) =>
      AnimationStep._(type: AnimationStepType.activateKey, keyIndex: keyIndex);

  factory AnimationStep.runProgress(int keyIndex) =>
      AnimationStep._(type: AnimationStepType.runProgress, keyIndex: keyIndex);

  factory AnimationStep.changeOpacity(bool value) =>
      AnimationStep._(type: AnimationStepType.changeOpacity, opacityValue: value);

  factory AnimationStep.delay(Duration duration) => AnimationStep._(type: AnimationStepType.delay, duration: duration);
}

enum AnimationStepType { activateKey, runProgress, changeOpacity, delay }
