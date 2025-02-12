import 'dart:async';
import 'dart:collection';

import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_creation_model.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SelectMultisigQuorumScreen extends StatefulWidget {
  const SelectMultisigQuorumScreen({super.key});

  @override
  State<SelectMultisigQuorumScreen> createState() =>
      _SelectMultisigQuorumScreenState();
}

class _SelectMultisigQuorumScreenState
    extends State<SelectMultisigQuorumScreen> {
  late int requiredCount; // 필요한 서명 수
  late int totalCount; // 전체 키의 수
  bool nextButtonEnabled = false;
  int buttonClickedCount = 0;

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
  Queue progressQueue = Queue<QueueDataClass>();

  @override
  void initState() {
    super.initState();
    requiredCount = 2;
    totalCount = 3;
    _startProgress(totalCount, requiredCount, buttonClickedCount);
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
        currentRoute.startsWith('/select-multisig-quorum')) {
      // _startProgress(nCount, mCount);
    }
  }

  void _stopProgress() {
    progressQueue.clear();
    _progressTimer_1 = null;
    _progressTimer_2 = null;
    _progressTimer_3 = null;
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

    return MultisigUtils.validateQuorumRequirement(requiredCount, totalCount);
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
          if (requiredCount == 1) return;
          setState(() {
            requiredCount--;
          });

          buttonClickedCount++;
          changeKeyCounts();
          break;
        }
      case ChangeCountButtonType.mCountPlus:
        {
          if (requiredCount == totalCount) return;
          setState(() {
            requiredCount++;
          });

          buttonClickedCount++;
          changeKeyCounts();
          break;
        }

      case ChangeCountButtonType.nCountMinus:
        {
          if (totalCount == 2) return;
          setState(() {
            if (totalCount == requiredCount) {
              requiredCount--;
            }
            totalCount--;
          });

          buttonClickedCount++;
          changeKeyCounts();
          break;
        }
      case ChangeCountButtonType.nCountPlus:
        {
          if (totalCount == 3) return;
          setState(() {
            totalCount++;
          });

          buttonClickedCount++;
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
        title: t.multisig_wallet,
        context: context,
        onNextPressed: () {
          Provider.of<MultisigCreationModel>(context, listen: false)
              .setQuorumRequirement(requiredCount, totalCount);

          _stopProgress();
          Navigator.pushNamed(context, '/assign-signers');
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
                  Expanded(
                    child: Center(
                      child: Text(
                        t.select_multisig_quorum_screen.total_key_count,
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
                    countText: totalCount.toString(),
                    isMinusButtonDisabled: totalCount <= 2,
                    isPlusButtonDisabled: totalCount >= 3,
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        t.select_multisig_quorum_screen
                            .required_signature_count,
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
                    countText: requiredCount.toString(),
                    isMinusButtonDisabled: requiredCount <= 1,
                    isPlusButtonDisabled: requiredCount == totalCount,
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
                  '$requiredCount/$totalCount',
                  color: MyColors.darkgrey,
                  fontSize: 24,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _buildQuorumMessage(),
                  style: Styles.unit.merge(TextStyle(
                      height:
                          requiredCount == totalCount ? 32.4 / 18 : 23.4 / 18,
                      letterSpacing: -0.01,
                      fontSize: 14)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Padding(
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
                                keyActive_1
                                    ? SvgPicture.asset(
                                        'assets/svg/key-icon.svg',
                                        width: 20,
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/key-icon.svg',
                                        width: 20,
                                        colorFilter: const ColorFilter.mode(
                                            MyColors.progressbarColorDisabled,
                                            BlendMode.srcIn),
                                      ),
                                const SizedBox(
                                  width: 30,
                                ),
                                Expanded(child: _buildProgressBar(0)),
                              ],
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            Visibility(
                              visible: totalCount == 3,
                              child: Row(
                                children: [
                                  keyActive_2
                                      ? SvgPicture.asset(
                                          'assets/svg/key-icon.svg',
                                          width: 20,
                                        )
                                      : SvgPicture.asset(
                                          'assets/svg/key-icon.svg',
                                          width: 20,
                                          colorFilter: const ColorFilter.mode(
                                              MyColors.progressbarColorDisabled,
                                              BlendMode.srcIn),
                                        ),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  Expanded(child: _buildProgressBar(1)),
                                ],
                              ),
                            ),
                            totalCount == 3
                                ? const SizedBox(
                                    height: 24,
                                  )
                                : Container(),
                            Row(
                              children: [
                                keyActive_3
                                    ? SvgPicture.asset(
                                        'assets/svg/key-icon.svg',
                                        width: 20,
                                      )
                                    : SvgPicture.asset(
                                        'assets/svg/key-icon.svg',
                                        width: 20,
                                        colorFilter: const ColorFilter.mode(
                                            MyColors.progressbarColorDisabled,
                                            BlendMode.srcIn),
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
                      animatedOpacityValue == 1
                          ? SvgPicture.asset(
                              'assets/svg/safe-bit.svg',
                              width: 50,
                            )
                          : SvgPicture.asset('assets/svg/safe.svg', width: 50)
                    ],
                  ),
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

    switch (totalCount) {
      case 2:
        {
          if (requiredCount == 1) {
            {
              result = t.select_multisig_quorum_screen.one_or_two_of_n;
              break;
            }
          } else {
            {
              result = t.select_multisig_quorum_screen.n_of_n;
              break;
            }
          }
        }
      case 3:
        {
          if (requiredCount == 1) {
            {
              result = t.select_multisig_quorum_screen.one_of_n;
              break;
            }
          } else if (requiredCount == 2) {
            {
              result = t.select_multisig_quorum_screen.one_or_two_of_n;
              break;
            }
          } else {
            {
              result = t.select_multisig_quorum_screen.n_of_n;
              break;
            }
          }
        }
    }
    return result;
  }

  void changeKeyCounts() {
    _stopProgress();
    switch (totalCount) {
      case 2:
        {
          if (requiredCount == 1) {
            {
              _startProgress(2, 1, buttonClickedCount);
              break;
            }
          } else {
            {
              _startProgress(2, 2, buttonClickedCount);
              break;
            }
          }
        }
      case 3:
        {
          if (requiredCount == 1) {
            {
              _startProgress(3, 1, buttonClickedCount);
              break;
            }
          } else if (requiredCount == 2) {
            {
              _startProgress(3, 2, buttonClickedCount);
              break;
            }
          } else {
            {
              _startProgress(3, 3, buttonClickedCount);
              break;
            }
          }
        }
    }
  }

  Widget _buildProgressBar(int key) {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        borderRadius: BorderRadius.circular(12),
        value: key == 0
            ? progressValue_1
            : key == 1
                ? progressValue_2
                : progressValue_3,
        color: MyColors.progressbarColorEnabled,
        backgroundColor: MyColors.progressbarColorDisabled,
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
    if (progressQueue.isEmpty ||
        progressQueue.last.entity != queueEntity &&
            progressQueue.last.count != buttonClickedCount) {
      _stopProgress();
      return;
    }
    debugPrint(
        'count : $buttonClickedCount queueCount : ${progressQueue.last.count}');
    switch (num) {
      case 1:
        {
          _progressTimer_1 =
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (progressQueue.isEmpty ||
                (progressQueue.last.entity != queueEntity &&
                    progressQueue.last.count != buttonClickedCount)) {
              timer.cancel();
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
            if (progressQueue.isEmpty ||
                progressQueue.last.entity != queueEntity ||
                progressQueue.last.count != buttonClickedCount) {
              timer.cancel();
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
            if (progressQueue.isEmpty ||
                progressQueue.last.entity != queueEntity ||
                progressQueue.last.count != buttonClickedCount) {
              timer.cancel();
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

  void _changeOpacityValue(bool value) {
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

  bool _canRunCurrentProgress(int buttonCountAtStart, QueueEntity entity) {
    if (progressQueue.isEmpty ||
        buttonCountAtStart != buttonClickedCount ||
        entity != progressQueue.last.entity) {
      return false;
    }
    return true;
  }

  void _activeKey(int num) {
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
  void _startProgress(int n, int m, int buttonCountAtStart) async {
    _stopProgress();
    progressQueue.add(QueueDataClass(
        count: buttonClickedCount, entity: _getQueueEntity(n, m)));

    debugPrint(
        'buttonClickedCount : $buttonClickedCount  << count : ${progressQueue.last.count}  << current N : $n  << current M : $m  << queueLastEntity : ${progressQueue.last.entity}  ');
    if (n == 2 && m == 1) {
      setState(() {
        keyActive_1 = true;
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m1)) return;
      // 첫번 째 프로그레스 진행
      _runProgress(1, QueueEntity.n2m1);

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m1)) return;
      // 1초 대기 후 체크표시
      _changeOpacityValue(true);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m1)) return;
      _changeOpacityValue(false);

      setState(() {
        keyActive_3 = true;
      });

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m1)) return;
      _runProgress(3, QueueEntity.n2m1);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m1)) return;
      _changeOpacityValue(true);
    } else if (n == 2 && m == 2) {
      setState(() {
        keyActive_1 = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m2)) return;
      // 첫번 째 프로그레스 진행
      _runProgress(1, QueueEntity.n2m2);

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m2)) return;
      // 1초 대기 후 세 번재 프로그레스 진행
      setState(() {
        keyActive_3 = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m2)) return;
      _runProgress(3, QueueEntity.n2m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m2)) return;
      _changeOpacityValue(true);
    } else if (n == 3 && m == 1) {
      /// n = 3 , m = 1
      ///
      ///
      setState(() {
        keyActive_1 = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;

      // 첫번 째 프로그레스 진행
      _runProgress(1, QueueEntity.n3m1);

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;
      // 1초 대기 후 체크표시
      _changeOpacityValue(true);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;
      _changeOpacityValue(false);

      setState(() {
        keyActive_2 = true;
      });

      // 1초 대기 후 두번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;
      _runProgress(2, QueueEntity.n3m1);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;
      _changeOpacityValue(true);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;

      _changeOpacityValue(false);
      setState(() {
        keyActive_3 = true;
      });

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;
      _runProgress(3, QueueEntity.n3m1);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m1)) return;
      _changeOpacityValue(true);
    } else if (n == 3 && m == 2) {
      /// n = 3 , m = 2
      ///
      ///
      setState(() {
        keyActive_1 = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      // 첫 번째 프로그레스 실행
      _runProgress(1, QueueEntity.n3m2);

      // 1초 대기 후 두 번째 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _activeKey(2);

      // 1초 대기 후 두번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _runProgress(2, QueueEntity.n3m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _changeOpacityValue(true);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;

      _changeOpacityValue(false);
      setState(() {
        keyActive_1 = true;
      });

      // 1초 대기 후 첫번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _runProgress(1, QueueEntity.n3m2);

      // 1초 대기 후 세번 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _activeKey(3);

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _runProgress(3, QueueEntity.n3m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _changeOpacityValue(true);

      // 2초 대기 후 체크표시 해제
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;

      _changeOpacityValue(false);
      setState(() {
        keyActive_2 = true;
      });

      // 1초 대기 후 두번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _runProgress(2, QueueEntity.n3m2);

      // 1초 대기 후 세번 째 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _activeKey(3);

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _runProgress(3, QueueEntity.n3m2);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m2)) return;
      _changeOpacityValue(true);
    } else if (n == 3 && m == 3) {
      /// n = 3 , m = 3
      ///
      ///
      setState(() {
        keyActive_1 = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m3)) return;
      // 첫 번째 프로그레스 진행
      _runProgress(1, QueueEntity.n3m3);

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m3)) return;
      // 1초 대기 후 두 번재 키 활성화
      _activeKey(2);

      // 1초 대기 후 두 번째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m3)) return;
      _runProgress(2, QueueEntity.n3m3);

      // 1초 대기 후 세 번재 키 활성화
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m3)) return;
      _activeKey(3);

      // 1초 대기 후 세 번재 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m3)) return;
      _runProgress(3, QueueEntity.n3m3);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n3m3)) return;
      _changeOpacityValue(true);
    }
  }
}

enum ChangeCountButtonType { nCountMinus, nCountPlus, mCountMinus, mCountPlus }

enum QueueEntity { n2m1, n2m2, n3m1, n3m2, n3m3 }

class QueueDataClass {
  final int count;
  final QueueEntity entity;

  const QueueDataClass({
    required this.count,
    required this.entity,
  });
}

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
