import 'dart:async';
import 'dart:collection';

import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SelectKeyOptionsScreen extends StatefulWidget {
  const SelectKeyOptionsScreen({super.key});

  @override
  State<SelectKeyOptionsScreen> createState() => _SelectKeyOptionsScreenState();
}

class _SelectKeyOptionsScreenState extends State<SelectKeyOptionsScreen> {
  late int mCount; // 필요한 서명 수
  late int nCount; // 전체 키의 수
  bool nextButtonEnabled = false;

  /// 하단 애니메이션 관련 변수
  double animatedOpacityValue = 0.0;
  bool keyActive_1 = false;
  bool keyActive_2 = false;
  bool keyActive_3 = false;
  double progressValue_1 = 0.0;
  double progressValue_2 = 0.0;
  double progressValue_3 = 0.0;
  Timer? _progressTimer_1;
  Timer? _progressTimer_2;
  Timer? _progressTimer_3;
  bool isProgressCanceled = false;
  Queue progressQueue = Queue<QueueEntity>();

  @override
  void initState() {
    super.initState();
    mCount = 1;
    nCount = 2;
    progressQueue.add(QueueEntity.n2m1);
    _startProgress(nCount, mCount);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          nextButtonEnabled = true;
        });
      }
    });
  }

  @override
  void dispose() {
    progressQueue.clear();
    _progressTimer_1?.cancel();
    _progressTimer_2?.cancel();
    _progressTimer_3?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 현재의 라우트 경로를 가져옴
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    debugPrint('currentRoute: $currentRoute');
    if (currentRoute != null &&
        currentRoute.startsWith('/select-key-options')) {
      // _startProgress(nCount, mCount);
    }
  }

  void _stopProgress() {
    progressQueue.clear();
    _progressTimer_1?.cancel();
    _progressTimer_2?.cancel();
    _progressTimer_3?.cancel();
    if (mounted) {
      setState(() {
        keyActive_1 = false;
        keyActive_2 = false;
        keyActive_3 = false;
        animatedOpacityValue = 0.0;
        progressValue_1 = 0.0;
        progressValue_2 = 0.0;
        progressValue_3 = 0.0;
      });
    }
  }

  bool _checkNextButtonActiveState() {
    if (!nextButtonEnabled) return false;
    if (mCount > 0 && mCount <= nCount && nCount > 1 && nCount <= 3) {
      return true;
    }
    return false;
  }

  void onCountButtonClicked(ChangeCountButtonType buttonType) {
    if (!nextButtonEnabled) {
      setState(() {
        nextButtonEnabled = true;
      });
    }
    switch (buttonType) {
      case ChangeCountButtonType.mCountMinus:
        {
          if (mCount == 1) return;
          setState(() {
            mCount--;
          });

          changeKeyCounts();
          break;
        }
      case ChangeCountButtonType.mCountPlus:
        {
          if (mCount == nCount) return;
          setState(() {
            mCount++;
          });

          changeKeyCounts();
          break;
        }

      case ChangeCountButtonType.nCountMinus:
        {
          if (nCount == 2) return;
          setState(() {
            if (nCount == mCount) {
              mCount--;
            }
            nCount--;
          });

          changeKeyCounts();
          break;
        }
      case ChangeCountButtonType.nCountPlus:
        {
          if (nCount == 3) return;
          setState(() {
            nCount++;
          });

          changeKeyCounts();
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.buildWithNext(
        title: '다중 서명 지갑',
        context: context,
        onNextPressed: () {
          _stopProgress();
          Navigator.pushNamed(context, '/assign-key',
              arguments: {'nKeyCount': nCount, 'mKeyCount': mCount});
        },
        isActive: _checkNextButtonActiveState(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        '전체 키의 수',
                        style: Styles.body2Bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CountingRowButton(
                    onMinusPressed: () =>
                        onCountButtonClicked(ChangeCountButtonType.nCountMinus),
                    onPlusPressed: () =>
                        onCountButtonClicked(ChangeCountButtonType.nCountPlus),
                    countText: nCount.toString(),
                    isMinusButtonDisabled: nCount <= 2,
                    isPlusButtonDisabled: nCount >= 3,
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        '필요한 서명 수',
                        style: Styles.body2Bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CountingRowButton(
                    onMinusPressed: () =>
                        onCountButtonClicked(ChangeCountButtonType.mCountMinus),
                    onPlusPressed: () =>
                        onCountButtonClicked(ChangeCountButtonType.mCountPlus),
                    countText: mCount.toString(),
                    isMinusButtonDisabled: mCount <= 1,
                    isPlusButtonDisabled: mCount == nCount,
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                ],
              ),
              const SizedBox(
                height: 50,
              ),
              Center(
                child: HighLightedText(
                  '$mCount/$nCount',
                  color: MyColors.darkgrey,
                  fontSize: 18,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                _buildQuorumMessage(),
                style: Styles.unit.merge(TextStyle(
                  height: mCount == nCount ? 32.4 / 18 : 23.4 / 18,
                  letterSpacing: -0.01,
                )),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 30,
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              keyActive_1
                                  ? SvgPicture.asset(
                                      'assets/svg/key-icon-color.svg',
                                      width: 36,
                                    )
                                  : SvgPicture.asset(
                                      'assets/svg/key-icon.svg',
                                      width: 36,
                                    ),
                              const SizedBox(
                                width: 30,
                              ),
                              Expanded(child: _buildProgressBar(0)),
                            ],
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Visibility(
                            visible: nCount == 3,
                            child: Row(
                              children: [
                                keyActive_2
                                    ? SvgPicture.asset(
                                        'assets/svg/key-icon-color.svg',
                                        width: 36,
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/key-icon.svg',
                                        width: 36,
                                      ),
                                const SizedBox(
                                  width: 30,
                                ),
                                Expanded(child: _buildProgressBar(1)),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Row(
                            children: [
                              keyActive_3
                                  ? SvgPicture.asset(
                                      'assets/svg/key-icon-color.svg',
                                      width: 36,
                                    )
                                  : SvgPicture.asset(
                                      'assets/svg/key-icon.svg',
                                      width: 36,
                                    ),
                              const SizedBox(
                                width: 30,
                              ),
                              Expanded(child: _buildProgressBar(2)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: MyColors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: MyColors.transparentBlack_15,
                            offset: Offset(0, 0),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Center(
                              child: SvgPicture.asset(
                                'assets/svg/coconut-security-gradient.svg',
                                width: 50,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                opacity: animatedOpacityValue,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  color: MyColors.transparentBlack_30,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 20,
                              child: AnimatedOpacity(
                                opacity: animatedOpacityValue,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: MyColors.greenyellow,
                                  size: 30,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _buildQuorumMessage() {
    String result = '';

    switch (nCount) {
      case 2:
        {
          if (mCount == 1) {
            {
              result = '하나의 키를 분실하거나 키 보관자 중 한 명이 부재중이더라도 비트코인을 보낼 수 있어요.';
              break;
            }
          } else {
            {
              result =
                  '모든 키가 있어야만 비트코인을 보낼 수 있어요. 단 하나의 키만 잃어버려도 자금에 접근할 수 없게 되니 분실에 각별히 신경써 주세요.';
              break;
            }
          }
        }
      case 3:
        {
          if (mCount == 1) {
            {
              result =
                  '하나의 키만 있어도 비트코인을 이동시킬 수 있어요. 상대적으로 보안성이 낮기 때문에 권장하지 않아요.';
              break;
            }
          } else if (mCount == 2) {
            {
              result = '하나의 키를 분실하거나 키 보관자 중 한 명이 부재중이더라도 비트코인을 보낼 수 있어요.';
              break;
            }
          } else {
            {
              result =
                  '모든 키가 있어야만 비트코인을 보낼 수 있어요. 단 하나의 키만 잃어버려도 자금에 접근할 수 없게 되니 분실에 각별히 신경써 주세요.';
              break;
            }
          }
        }
    }
    return result;
  }

  void changeKeyCounts() {
    progressQueue.clear();
    switch (nCount) {
      case 2:
        {
          if (mCount == 1) {
            {
              progressQueue.add(QueueEntity.n2m1);
              _startProgress(2, 1);
              break;
            }
          } else {
            {
              progressQueue.add(QueueEntity.n2m2);
              _startProgress(2, 2);
              break;
            }
          }
        }
      case 3:
        {
          if (mCount == 1) {
            {
              progressQueue.add(QueueEntity.n3m1);
              _startProgress(3, 1);
              break;
            }
          } else if (mCount == 2) {
            {
              progressQueue.add(QueueEntity.n3m2);
              _startProgress(3, 2);
              break;
            }
          } else {
            {
              progressQueue.add(QueueEntity.n3m3);
              _startProgress(3, 3);
              break;
            }
          }
        }
    }
  }

  Widget _buildProgressBar(int key) {
    return SizedBox(
      height: 10,
      child: GradientProgressBar(
        value: key == 0
            ? progressValue_1
            : key == 1
                ? progressValue_2
                : progressValue_3,
        height: 10,
        gradient: const LinearGradient(
          colors: [MyColors.cyanblue, Colors.purple], // 그라데이션 색상
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
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
    if (progressQueue.isEmpty || progressQueue.first != queueEntity) {
      return;
    }
    switch (num) {
      case 1:
        {
          _progressTimer_1 =
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (progressQueue.isEmpty || progressQueue.first != queueEntity) {
              return;
            }
            if (progressValue_1 >= 1.0) {
              timer.cancel();
            } else {
              setState(() {
                progressValue_1 += 0.01;
              });
            }
          });
          break;
        }
      case 2:
        {
          _progressTimer_2 =
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (progressQueue.isEmpty || progressQueue.first != queueEntity) {
              return;
            }
            if (progressValue_2 >= 1.0) {
              timer.cancel();
            } else {
              setState(() {
                progressValue_2 += 0.01;
              });
            }
          });
          break;
        }
      case 3:
        {
          _progressTimer_3 =
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (progressQueue.isEmpty || progressQueue.first != queueEntity) {
              return;
            }
            if (progressValue_3 >= 1.0) {
              timer.cancel();
            } else {
              setState(() {
                progressValue_3 += 0.01;
              });
            }
          });
          break;
        }
    }
  }

  void _changeOpacityValue(bool value, QueueEntity entity) {
    if (progressQueue.isEmpty || progressQueue.first != entity) {
      return;
    }
    if (!value) {
      setState(() {
        animatedOpacityValue = 0;
        keyActive_1 = false;
        keyActive_2 = false;
        keyActive_3 = false;

        progressValue_1 = 0;
        progressValue_2 = 0;
        progressValue_3 = 0;
      });
    } else {
      setState(() {
        animatedOpacityValue = value ? 1 : 0;
      });
    }
  }

  void _activeKey(int num, QueueEntity entity) {
    if (progressQueue.isEmpty || progressQueue.first != entity) {
      return;
    }
    setState(() {
      if (num == 1) {
        keyActive_1 = true;
      } else if (num == 2) {
        keyActive_2 = true;
      } else if (num == 3) {
        keyActive_3 = true;
      }
    });
  }

  /// TODO: 로직 개선 필요
  void _startProgress(int n, int m) async {
    _stopProgress();
    progressQueue.add(_getQueueEntity(n, m));
    if (n == 2 && m == 1) {
      progressQueue.add(QueueEntity.n2m1);
      setState(() {
        keyActive_1 = true;
      });
      await Future.delayed(const Duration(milliseconds: 1000));

      // 첫번 째 프로그레스 진행
      _runProgress(1, QueueEntity.n2m1);

      await Future.delayed(const Duration(milliseconds: 1000));
      // 1초 대기 후 체크표시
      _changeOpacityValue(true, QueueEntity.n2m1);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      _changeOpacityValue(false, QueueEntity.n2m1);
      setState(() {
        keyActive_3 = true;
      });

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(3, QueueEntity.n2m1);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n2m1);
    } else if (n == 2 && m == 2) {
      setState(() {
        keyActive_1 = true;
      });
      progressQueue.add(QueueEntity.n2m2);

      await Future.delayed(const Duration(milliseconds: 1000));
      // 첫번 째 프로그레스 진행
      _runProgress(1, QueueEntity.n2m2);

      await Future.delayed(const Duration(milliseconds: 1000));
      // 1초 대기 후 세 번재 프로그레스 진행
      if (progressQueue.isEmpty || progressQueue.first != QueueEntity.n2m2) {
        return;
      }
      setState(() {
        keyActive_3 = true;
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(3, QueueEntity.n2m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n2m2);
    } else if (n == 3 && m == 1) {
      /// n = 3 , m = 1
      ///
      ///
      setState(() {
        keyActive_1 = true;
      });
      progressQueue.add(QueueEntity.n3m1);

      await Future.delayed(const Duration(milliseconds: 1000));

      // 첫번 째 프로그레스 진행
      _runProgress(1, QueueEntity.n3m1);

      await Future.delayed(const Duration(milliseconds: 1000));
      // 1초 대기 후 체크표시
      _changeOpacityValue(true, QueueEntity.n3m1);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      _changeOpacityValue(false, QueueEntity.n3m1);
      setState(() {
        keyActive_2 = true;
      });

      // 1초 대기 후 두번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(2, QueueEntity.n3m1);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n3m1);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (progressQueue.isEmpty || progressQueue.first != QueueEntity.n3m1) {
        return;
      }
      _changeOpacityValue(false, QueueEntity.n3m1);
      setState(() {
        keyActive_3 = true;
      });

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(3, QueueEntity.n3m1);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n3m1);
    } else if (n == 3 && m == 2) {
      /// n = 3 , m = 2
      ///
      ///
      setState(() {
        keyActive_1 = true;
      });
      progressQueue.add(QueueEntity.n3m2);

      await Future.delayed(const Duration(milliseconds: 1000));
      // 첫 번째 프로그레스 실행
      _runProgress(1, QueueEntity.n3m2);

      // 1초 대기 후 두 번째 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      _activeKey(2, QueueEntity.n3m2);

      // 1초 대기 후 두번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(2, QueueEntity.n3m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n3m2);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (progressQueue.isEmpty || progressQueue.first != QueueEntity.n3m2) {
        return;
      }
      _changeOpacityValue(false, QueueEntity.n3m2);
      setState(() {
        keyActive_1 = true;
      });

      // 1초 대기 후 첫번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(1, QueueEntity.n3m2);

      // 1초 대기 후 세번 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      _activeKey(3, QueueEntity.n3m2);

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(3, QueueEntity.n3m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n3m2);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (progressQueue.isEmpty || progressQueue.first != QueueEntity.n3m2) {
        return;
      }
      _changeOpacityValue(false, QueueEntity.n3m2);
      setState(() {
        keyActive_2 = true;
      });

      // 1초 대기 후 두번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(2, QueueEntity.n3m2);

      // 1초 대기 후 세번 째 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      _activeKey(3, QueueEntity.n3m2);

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(3, QueueEntity.n3m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n3m2);
    } else if (n == 3 && m == 3) {
      /// n = 3 , m = 3
      ///
      ///
      setState(() {
        keyActive_1 = true;
      });
      progressQueue.add(QueueEntity.n3m3);

      await Future.delayed(const Duration(milliseconds: 1000));
      // 첫 번째 프로그레스 진행
      _runProgress(1, QueueEntity.n3m3);

      await Future.delayed(const Duration(milliseconds: 1000));
      // 1초 대기 후 두 번재 키 활성화
      _activeKey(2, QueueEntity.n3m3);

      // 1초 대기 후 두 번째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(2, QueueEntity.n3m3);

      // 1초 대기 후 세 번재 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      _activeKey(3, QueueEntity.n3m3);

      // 1초 대기 후 세 번재 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      _runProgress(3, QueueEntity.n3m3);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      _changeOpacityValue(true, QueueEntity.n3m3);
    }
  }
}

enum ChangeCountButtonType { nCountMinus, nCountPlus, mCountMinus, mCountPlus }

enum QueueEntity { n2m1, n2m2, n3m1, n3m2, n3m3 }

class GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Gradient gradient;

  const GradientProgressBar({
    super.key,
    required this.value,
    required this.height,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: double.infinity,
        height: height,
        color: MyColors.transparentBlack_06,
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
