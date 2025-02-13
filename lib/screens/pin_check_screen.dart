import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/managers/wallet_list_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/screens/pin_setting_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/managers/app_unlock_manager.dart';
import 'package:provider/provider.dart';

import '../widgets/pin/pin_input_screen.dart';

enum PinCheckScreenStatus {
  entrance, // 앱 실행해서 pin 확인
  lock, // 앱 켜져있는 상태에서 화면 껐다가 켜졌을 때 (AppLifecycleState.paused) // TODO: lock은 Deprecated
  change, // 핀 변경
  info // 니모닉, 확장키, 삭제
}

class PinCheckScreen extends StatefulWidget {
  final Function? onReset;
  final Function? onComplete;
  final bool isDeleteScreen;
  final PinCheckScreenStatus screenStatus;
  const PinCheckScreen({
    super.key,
    required this.screenStatus,
    this.onReset,
    this.onComplete,
    this.isDeleteScreen = false,
  });

  @override
  State<PinCheckScreen> createState() => _PinCheckScreenState();
}

class _PinCheckScreenState extends State<PinCheckScreen>
    with WidgetsBindingObserver {
  final AppUnlockManager _appUnlockManager = AppUnlockManager();
  late String pin;
  late String errorMessage;
  late AppModel _appModel;

  DateTime? _lastPressedAt;

  // when widget.appEntrance is true
  int attempt = 0;
  bool lastChanceToTry = false;
  static const MAX_NUMBER_OF_ATTEMPTS = 3;
  static const LAST_UNLOCK_ATTEMPT_COUNT = 7;
  static const WRONG_PIN_AWAIT_TIME_1 = 1;
  static const WRONG_PIN_AWAIT_TIME_2 = 5;
  static const WRONG_PIN_AWAIT_TIME_3 = 15;
  static const WRONG_PIN_AWAIT_TIME_4 = 30;
  static const WRONG_PIN_AWAIT_TIME_5 = 60;
  static const WRONG_PIN_AWAIT_TIME_6 = 180;
  static const WRONG_PIN_AWAIT_TIME_7 = 480;
  static const WRONG_PIN_AWAIT_TIME_8 = 600;
  static const WRONG_PIN_AWAIT_TIME_FOREVER = -1;

  bool _isPause = false;

  final List<int> lockoutDurations = [
    WRONG_PIN_AWAIT_TIME_1,
    WRONG_PIN_AWAIT_TIME_2,
    WRONG_PIN_AWAIT_TIME_3,
    WRONG_PIN_AWAIT_TIME_4,
    WRONG_PIN_AWAIT_TIME_5,
    WRONG_PIN_AWAIT_TIME_6,
    WRONG_PIN_AWAIT_TIME_7,
    WRONG_PIN_AWAIT_TIME_8,
    WRONG_PIN_AWAIT_TIME_FOREVER,
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _appModel = Provider.of<AppModel>(context, listen: false);
    super.initState();
    pin = '';
    errorMessage = '';
    _loadAttemptCountFromStorage();
    _checkPinLocked();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  void _loadAttemptCountFromStorage() async {
    attempt = int.parse(_appUnlockManager.loadPinInputAttemptCount());
    if (attempt != 0 && attempt < MAX_NUMBER_OF_ATTEMPTS) {
      setState(() {
        errorMessage = t.errors.pin_incorrect_with_remaining_attempts_error(
            count: MAX_NUMBER_OF_ATTEMPTS - attempt);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// 스크린 Pause -> 생체인증 변동사항 체크
    if (AppLifecycleState.paused == state) {
      _isPause = true;
    } else if (AppLifecycleState.resumed == state && _isPause) {
      _isPause = false;
      _checkBiometrics();
    }
  }

  /// vault_list_tab screen, this screen pause -> Bio 체크
  void _checkBiometrics() async {
    if (widget.screenStatus == PinCheckScreenStatus.lock) {
      /// 생체인증 정보 체크
      await _appModel.setInitData();
    }

    _appModel.shuffleNumbers();

    if (_appModel.isBiometricEnabled && _appModel.canCheckBiometrics) {
      _verifyBiometric();
    }
  }

  void moveToMain() async {
    await _appModel.checkDeviceBiometrics();
    Navigator.pushNamedAndRemoveUntil(
        context, '/', (Route<dynamic> route) => false);
  }

  void _onKeyTap(String value) async {
    // if (value != '<' && value != 'bio' && value != '') vibrateShort();
    if (value == 'bio') {
      _verifyBiometric();
      return;
    }

    if ((widget.screenStatus == PinCheckScreenStatus.entrance ||
            widget.screenStatus == PinCheckScreenStatus.lock) &&
        attempt == MAX_NUMBER_OF_ATTEMPTS) {
      return;
    }

    setState(() {
      if (value == '<') {
        if (pin.isNotEmpty) {
          pin = pin.substring(0, pin.length - 1);
        }
      } else if (pin.length < 4) {
        pin += value;
      }

      if (pin.length == 4) {
        context.loaderOverlay.show();
        _verifyPin();
      }
    });
  }

  void _verifyBiometric() async {
    if (await _appModel.authenticateWithBiometrics(context,
        showAuthenticationFailedDialog: false)) {
      _verifySwitch();
    }
  }

  void _verifyPin() async {
    if (await _appModel.verifyPin(pin)) {
      context.loaderOverlay.hide();
      _verifySwitch();
    } else {
      context.loaderOverlay.hide();
      if (widget.screenStatus == PinCheckScreenStatus.entrance ||
          widget.screenStatus == PinCheckScreenStatus.lock) {
        attempt += 1;
        await _appUnlockManager.setPinInputAttemptCount(attempt);
        if (attempt < MAX_NUMBER_OF_ATTEMPTS) {
          setState(() {
            errorMessage = t.errors.pin_incorrect_with_remaining_attempts_error(
                count: MAX_NUMBER_OF_ATTEMPTS - attempt);
          });
          _appModel.shuffleNumbers();
          vibrateMediumDouble();
        } else {
          vibrateMedium();
          _checkPinLockout();
        }
      } else {
        errorMessage = t.errors.pin_incorrect_error;
        _appModel.shuffleNumbers();
        vibrateMediumDouble();
      }
      setState(() {
        pin = '';
      });
    }
  }

  void _startLockoutTimer(DateTime lockoutEndTime, int totalAttempt) {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remainingDuration = lockoutEndTime.difference(DateTime.now());
      final remainingSeconds =
          remainingDuration.inSeconds > 0 ? remainingDuration.inSeconds : 0;

      if (remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          if (attempt == MAX_NUMBER_OF_ATTEMPTS) {
            attempt = 0;
            errorMessage = '';
          }

          /// 마지막인 시도인 경우 "초기화 주의 문구" 출력
          if (totalAttempt == LAST_UNLOCK_ATTEMPT_COUNT &&
              remainingSeconds <= 0) {
            lastChanceToTry = true;
          }
          _appUnlockManager.setPinInputAttemptCount(attempt);
        });
      } else {
        final formattedTime = _formatRemainingTime(remainingSeconds);
        setState(() {
          errorMessage = t.errors.retry_after(time: formattedTime);
        });
      }
    });
  }

  String _formatRemainingTime(int remainingSeconds) {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    List<String> timeComponents = [];

    if (hours > 0) timeComponents.add('$hours${t.hour}');
    if (minutes > 0) timeComponents.add('$minutes${t.minute}');
    if (seconds > 0 || timeComponents.isEmpty) {
      timeComponents.add('$seconds${t.second}');
    }

    return timeComponents.join(' ');
  }

  void _checkPinLocked() async {
    /// 처음 시작시 잠금 상태 확인하는 함수
    /// 잠금 정보를 로드
    Map<String, String> lockout = _appUnlockManager.loadLockoutDuration();
    final totalAttempt = int.parse(lockout[AppUnlockManager.totalAttemptKey]!);

    /// 시도 횟수가 0이고 현재 시도 횟수가 {MAX_NUMBER_OF_ATTEMPTS}이 아니라면, 아무 작업도 하지 않음
    if (totalAttempt == 0 && attempt != MAX_NUMBER_OF_ATTEMPTS) {
      return;
    }

    /// 영구 잠금 상태를 처리
    if (lockoutDurations[totalAttempt - 1] == WRONG_PIN_AWAIT_TIME_FOREVER) {
      _handlePermanentLockout();
      return;
    }

    /// lockoutEndTime이 유효한 값인지 확인
    final lockoutEndTime =
        DateTime.tryParse(lockout[AppUnlockManager.lockoutEndTimeKey]!);
    if (lockoutEndTime == null) {
      return;
    }

    /// 남은 시간을 계산
    final remainingDuration = lockoutEndTime.difference(DateTime.now());
    final remainingSeconds =
        remainingDuration.inSeconds > 0 ? remainingDuration.inSeconds : 0;

    /// 잠금 상태에 따라 타이머를 시작하거나 시도 횟수를 초기화
    if (remainingSeconds > 0) {
      _startLockoutTimer(lockoutEndTime, totalAttempt);
    } else if (attempt == MAX_NUMBER_OF_ATTEMPTS) {
      attempt = 0;
    }

    /// 마지막 재시도인 경우 초기화 주의 문구 출력
    if (totalAttempt == LAST_UNLOCK_ATTEMPT_COUNT && remainingSeconds <= 0) {
      setState(() {
        lastChanceToTry = true;
      });
    }
  }

  void _checkPinLockout() async {
    /// Pin 틀릴 시 잠금처리
    Map<String, String> lockout = _appUnlockManager.loadLockoutDuration();
    final totalAttempt = int.parse(lockout[AppUnlockManager.totalAttemptKey]!);

    int awaitDuration = lockoutDurations[totalAttempt];
    await _appUnlockManager.setLockoutDuration(awaitDuration,
        totalAttemptCount: totalAttempt + 1);

    if (awaitDuration == WRONG_PIN_AWAIT_TIME_FOREVER) {
      _handlePermanentLockout();
      return;
    }

    lockout = _appUnlockManager.loadLockoutDuration();
    final lockoutEndTime =
        DateTime.parse(lockout[AppUnlockManager.lockoutEndTimeKey]!);
    _startLockoutTimer(lockoutEndTime, totalAttempt + 1);
  }

  void _handlePermanentLockout() {
    setState(() {
      errorMessage = t.errors.pin_max_attempts_exceeded_error;
      lastChanceToTry = false;
    });
    _showResetDialog();
  }

  void _verifySwitch() {
    switch (widget.screenStatus) {
      case PinCheckScreenStatus.entrance:
        _appModel.changeIsAuthChecked(true);
        _appUnlockManager.setLockoutDuration(0);
        _appUnlockManager.setPinInputAttemptCount(0);
        widget.onComplete?.call();
      case PinCheckScreenStatus.lock:
        _appUnlockManager.setLockoutDuration(0);
        _appUnlockManager.setPinInputAttemptCount(0);
        moveToMain();
      case PinCheckScreenStatus.change:
        _appModel.shuffleNumbers(isSettings: true);
        Navigator.pop(context);
        MyBottomSheet.showBottomSheet_90(
            context: context, child: const PinSettingScreen());
      default: // vaultInfo
        widget.onComplete?.call();
    }
  }

  void _showResetDialog() {
    CustomDialogs.showCustomAlertDialog(context,
        title: t.alert.forgot_password.title,
        textWidget: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: t.alert.forgot_password.description1,
                style: Styles.body2,
              ),
              TextSpan(
                text: t.alert.forgot_password.description2,
                style: Styles.warning,
              ),
            ],
          ),
        ),
        confirmButtonText: t.alert.forgot_password.btn_reset,
        confirmButtonColor: MyColors.warningText,
        cancelButtonText: t.close, onConfirm: () async {
      WalletListManager().resetAll();
      final appModel = Provider.of<AppModel>(context, listen: false);
      appModel.resetPassword();
      appModel.saveVaultListLength(0);
      // TODO: 모든 저장소 초기화 필요(?)
      // TODO: _pinAttemptService reset

      if (widget.screenStatus == PinCheckScreenStatus.entrance) {
        Navigator.of(context).pop();
        widget.onReset?.call();
      } else {
        moveToMain();
      }
    }, onCancel: () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.screenStatus == PinCheckScreenStatus.entrance ||
            widget.screenStatus == PinCheckScreenStatus.lock
        ? Material(
            color: MyColors.white,
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (Platform.isAndroid) {
                  final now = DateTime.now();
                  if (_lastPressedAt == null ||
                      now.difference(_lastPressedAt!) >
                          const Duration(seconds: 3)) {
                    _lastPressedAt = now;
                    Fluttertoast.showToast(
                      backgroundColor: MyColors.grey,
                      msg: t.toast.back_exit,
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  } else {
                    SystemNavigator.pop();
                  }
                }
              },
              child: Scaffold(
                backgroundColor: MyColors.white,
                body: Stack(
                  children: [
                    Center(child: _pinInputScreen(isOnReset: true)),
                  ],
                ),
              ),
            ))
        : _pinInputScreen();
  }

  Widget _pinInputScreen({isOnReset = false}) {
    return PinInputScreen(
      appBarVisible: widget.screenStatus == PinCheckScreenStatus.entrance ||
              widget.screenStatus == PinCheckScreenStatus.lock
          ? false
          : true,
      title: widget.screenStatus == PinCheckScreenStatus.entrance ||
              widget.screenStatus == PinCheckScreenStatus.lock
          ? ''
          : t.pin_check_screen.enter_password,
      initOptionVisible: widget.screenStatus == PinCheckScreenStatus.entrance ||
          widget.screenStatus == PinCheckScreenStatus.lock,
      isCloseIcon: widget.isDeleteScreen,
      pin: pin,
      errorMessage: errorMessage,
      onKeyTap: _onKeyTap,
      onClosePressed: () {
        Navigator.pop(context);
      },
      onBackPressed: () {
        Navigator.pop(context);
      },
      onReset: isOnReset ? _showResetDialog : null,
      step: 0,
      lastChance: lastChanceToTry,
      lastChanceMessage: t.pin_check_screen.warning,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
