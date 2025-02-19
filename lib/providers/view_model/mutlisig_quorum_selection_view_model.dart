import 'dart:async';
import 'dart:collection';

import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_creation_model.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/multisig_quorum_selection_screen.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';
import 'package:flutter/material.dart';

class MultisigQuorumSelectionViewModel extends ChangeNotifier {
  final MultisigCreationModel _multisigCreationModel;
  late int _requiredCount;
  late int _totalCount;
  late int _buttonClickedCount;
  late bool _nextButtonEnabled;

  /// 하단 애니메이션 관련 변수
  double _animatedOpacityValue = 0.0;
  bool _keyActive_1 = false;
  bool _keyActive_2 = false;
  bool _keyActive_3 = false;
  final bool _isProgressCanceled = false;
  double _progressValue_1 = 0.0;
  double _progressValue_2 = 0.0;
  double _progressValue_3 = 0.0;
  final Queue _progressQueue = Queue<QueueDataClass>();
  Timer? _progressTimer_1;
  Timer? _progressTimer_2;
  Timer? _progressTimer_3;
  bool _mounted = true;

  MultisigQuorumSelectionViewModel(this._multisigCreationModel) {
    _requiredCount = 2;
    _totalCount = 3;
    _buttonClickedCount = 0;
    _nextButtonEnabled = false;

    startAnimationProgress(_totalCount, _requiredCount, _buttonClickedCount);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_mounted) {
        setNextButtonEnabled(true);
      }
    });
  }
  double get animatedOpacityValue => _animatedOpacityValue;
  int get buttonClickedCount => _buttonClickedCount;
  bool get isProgressCanceled => _isProgressCanceled;
  bool get keyActive_1 => _keyActive_1;
  bool get keyActive_2 => _keyActive_2;
  bool get keyActive_3 => _keyActive_3;
  bool get nextButtonEnabled => _nextButtonEnabled;
  bool get isQuorumSettingValid =>
      _nextButtonEnabled &&
      MultisigUtils.validateQuorumRequirement(_requiredCount, _totalCount);
  double get progressValue_1 => _progressValue_1;
  double get progressValue_2 => _progressValue_2;
  double get progressValue_3 => _progressValue_3;
  int get requiredCount => _requiredCount;

  int get totalCount => _totalCount;

  String buildQuorumMessage() {
    String result = '';

    switch (_totalCount) {
      case 2:
        {
          if (_requiredCount == 1) {
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
          if (_requiredCount == 1) {
            {
              result = t.select_multisig_quorum_screen.one_of_n;
              break;
            }
          } else if (_requiredCount == 2) {
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
    stopAnimationProgress();
    switch (totalCount) {
      case 2:
        {
          if (requiredCount == 1) {
            {
              startAnimationProgress(2, 1, buttonClickedCount);
              break;
            }
          } else {
            {
              startAnimationProgress(2, 2, buttonClickedCount);
              break;
            }
          }
        }
      case 3:
        {
          if (requiredCount == 1) {
            {
              startAnimationProgress(3, 1, buttonClickedCount);
              break;
            }
          } else if (requiredCount == 2) {
            {
              startAnimationProgress(3, 2, buttonClickedCount);
              break;
            }
          } else {
            {
              startAnimationProgress(3, 3, buttonClickedCount);
              break;
            }
          }
        }
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _progressQueue.clear();
    _progressTimer_1?.cancel();
    _progressTimer_2?.cancel();
    _progressTimer_3?.cancel();
    super.dispose();
  }

  void setQuorumRequirementToModel() {
    _multisigCreationModel.setQuorumRequirement(_requiredCount, _totalCount);
  }

  void onCountButtonClicked(ChangeCountButtonType buttonType) {
    if (!_nextButtonEnabled) {
      setNextButtonEnabled(true);
    }
    switch (buttonType) {
      case ChangeCountButtonType.mCountMinus:
        {
          if (requiredCount == 1) return;
          _requiredCount--;
          notifyListeners();

          _buttonClickedCount++;
          changeKeyCounts();
          break;
        }
      case ChangeCountButtonType.mCountPlus:
        {
          if (requiredCount == totalCount) return;
          _requiredCount++;
          notifyListeners();

          _buttonClickedCount++;
          changeKeyCounts();
          break;
        }

      case ChangeCountButtonType.nCountMinus:
        {
          if (totalCount == 2) return;
          if (totalCount == requiredCount) {
            _requiredCount--;
          }
          _totalCount--;
          notifyListeners();

          _buttonClickedCount++;
          changeKeyCounts();
          break;
        }
      case ChangeCountButtonType.nCountPlus:
        {
          if (totalCount == 3) return;
          _totalCount++;
          notifyListeners();

          _buttonClickedCount++;
          changeKeyCounts();
          break;
        }
    }
  }

  void setNextButtonEnabled(bool value) {
    _nextButtonEnabled = value;
    notifyListeners();
  }

  void startAnimationProgress(int n, int m, int buttonCountAtStart) async {
    stopAnimationProgress();
    _progressQueue.add(QueueDataClass(
        count: buttonClickedCount, entity: _getQueueEntity(n, m)));

    debugPrint(
        '########buttonClickedCount : $buttonClickedCount  << count : ${_progressQueue.last.count}  << current N : $n  << current M : $m  << queueLastEntity : ${_progressQueue.last.entity}  ');
    if (n == 2 && m == 1) {
      _keyActive_1 = true;
      notifyListeners();

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

      _keyActive_3 = true;
      notifyListeners();

      // 1초 대기 후 세번 째 프로그레스 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m1)) return;
      _runProgress(3, QueueEntity.n2m1);

      // 1초 대기 후 체크표시
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m1)) return;
      _changeOpacityValue(true);
    } else if (n == 2 && m == 2) {
      _keyActive_1 = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m2)) return;
      // 첫번 째 프로그레스 진행
      _runProgress(1, QueueEntity.n2m2);

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_canRunCurrentProgress(buttonCountAtStart, QueueEntity.n2m2)) return;
      // 1초 대기 후 세 번재 프로그레스 진행
      _keyActive_3 = true;
      notifyListeners();

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
      _keyActive_1 = true;
      notifyListeners();

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

      _keyActive_2 = true;
      notifyListeners();

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
      _keyActive_3 = true;
      notifyListeners();

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
      _keyActive_1 = true;
      notifyListeners();

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
      _keyActive_1 = true;
      notifyListeners();

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
      _keyActive_2 = true;
      notifyListeners();

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
      _keyActive_1 = true;
      notifyListeners();

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

  void stopAnimationProgress() {
    _progressQueue.clear();
    _progressTimer_1 = null;
    _progressTimer_2 = null;
    _progressTimer_3 = null;
    if (_mounted) {
      _keyActive_1 = false;
      _keyActive_2 = false;
      _keyActive_3 = false;
      _animatedOpacityValue = 0.0;
      _progressValue_1 = 0.0;

      _progressValue_2 = 0.0;
      _progressValue_3 = 0.0;
      notifyListeners();
    }
  }

  void _activeKey(int num) {
    if (num == 1) {
      _keyActive_1 = true;
    } else if (num == 2) {
      _keyActive_2 = true;
    } else if (num == 3) {
      _keyActive_3 = true;
    }
    notifyListeners();
  }

  bool _canRunCurrentProgress(int buttonCountAtStart, QueueEntity entity) {
    if (!_mounted ||
        _progressQueue.isEmpty ||
        buttonCountAtStart != buttonClickedCount ||
        entity != _progressQueue.last.entity) {
      return false;
    }
    return true;
  }

  void _changeOpacityValue(bool value) {
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
    notifyListeners();
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
        _progressQueue.last.entity != queueEntity &&
            _progressQueue.last.count != buttonClickedCount) {
      stopAnimationProgress();
      return;
    }
    switch (num) {
      case 1:
        {
          _progressTimer_1 =
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (_progressQueue.isEmpty ||
                (_progressQueue.last.entity != queueEntity &&
                    _progressQueue.last.count != buttonClickedCount)) {
              timer.cancel();
              return;
            }
            if (progressValue_1 >= 1.0) {
              timer.cancel();
            } else {
              _progressValue_1 += 0.01;
              notifyListeners();
            }
          });
          break;
        }
      case 2:
        {
          _progressTimer_2 =
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (_progressQueue.isEmpty ||
                _progressQueue.last.entity != queueEntity ||
                _progressQueue.last.count != buttonClickedCount) {
              timer.cancel();
              return;
            }
            if (_progressValue_2 >= 1.0) {
              timer.cancel();
            } else {
              _progressValue_2 += 0.01;
              notifyListeners();
            }
          });
          break;
        }
      case 3:
        {
          _progressTimer_3 =
              Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (_progressQueue.isEmpty ||
                _progressQueue.last.entity != queueEntity ||
                _progressQueue.last.count != buttonClickedCount) {
              timer.cancel();
              return;
            }
            if (_progressValue_3 >= 1.0) {
              timer.cancel();
            } else {
              _progressValue_3 += 0.01;
              notifyListeners();
            }
          });
          break;
        }
    }
  }
}

class QueueDataClass {
  final int count;
  final QueueEntity entity;

  const QueueDataClass({
    required this.count,
    required this.entity,
  });
}

enum QueueEntity { n2m1, n2m2, n3m1, n3m2, n3m3 }
