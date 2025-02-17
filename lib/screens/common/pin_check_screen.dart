import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_auth_dialog.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/screens/pin_setting_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'pin_input_screen.dart';

class PinCheckScreen extends StatefulWidget {
  final Function? onReset;
  final Function? onComplete;
  final bool isDeleteScreen;
  final PinCheckContextEnum pinCheckContext;
  const PinCheckScreen({
    super.key,
    required this.pinCheckContext,
    this.onReset,
    this.onComplete,
    this.isDeleteScreen = false,
  });

  @override
  State<PinCheckScreen> createState() => _PinCheckScreenState();
}

class _PinCheckScreenState extends State<PinCheckScreen>
    with WidgetsBindingObserver {
  late bool _isAppLaunchedOrResumed;
  late String _pin;
  late String _errorMessage;

  late AuthProvider _authProvider;
  late List<String> _shuffledPinNumbers;

  DateTime? _lastPressedAt;

  // when widget.appEntrance is true
  bool _isPaused = false;
  bool _isUnlockDisabled = false;
  bool _isLastChanceToTry = false;

  @override
  void initState() {
    super.initState();

    _pin = '';
    _errorMessage = '';

    _isAppLaunchedOrResumed =
        widget.pinCheckContext == PinCheckContextEnum.appLaunch ||
            widget.pinCheckContext == PinCheckContextEnum.appResume;

    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    Future.microtask(() {
      _authProvider.onRequestShowAuthenticationFailedDialog = () {
        showAuthenticationFailedDialog(
            context, _authProvider.hasAlreadyRequestedBioPermission);
      };
      _authProvider.onAuthenticationSuccess = _handleAuthenticationSuccess;
    });

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });

    _shuffledPinNumbers = _authProvider.getShuffledNumberList();

    if (_isAppLaunchedOrResumed && _authProvider.isPermanantlyLocked) {
      _errorMessage = t.errors.pin_max_attempts_exceeded_error;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// 스크린 Pause -> 생체인증 변동사항 체크
    if (AppLifecycleState.paused == state) {
      _isPaused = true;
    } else if (AppLifecycleState.resumed == state && _isPaused) {
      _isPaused = false;
      _checkBiometrics();
    }
  }

  /// vault_list_tab screen, this screen pause -> Bio 체크
  void _checkBiometrics() {
    if (widget.pinCheckContext == PinCheckContextEnum.appResume) {
      // TODO: app_model의  await checkDeviceBiometrics(); 실행을 위해서 아래 함수를 실행한 것임
      // TODO: 앱 백그라운드 -> 포그라운드 상태 변경 시 생체 정보를 업데이트 해주는 로직이 필요함
      /// 생체인증 정보 체크
      _authProvider.setInitState();
    }

    if (_authProvider.canCheckBiometrics) {
      _authProvider.verifyBiometric(context);
    }
  }

  void moveToMain() async {
    await _authProvider.updateBiometricAvailability(); // TODO: 이거 여기서 왜하지?
    Navigator.pushNamedAndRemoveUntil(
        context, '/', (Route<dynamic> route) => false);
  }

  void _onKeyTap(String value) async {
    if (_isUnlockDisabled ||
        _isAppLaunchedOrResumed && _authProvider.isPermanantlyLocked) return;

    if (value == kBiometricIdentifier) {
      _authProvider.verifyBiometric(context);
      return;
    }

    setState(() {
      if (value == kDeleteBtnIdentifier) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else if (_pin.length < kExpectedPinLength) {
        _pin += value;
      }

      if (_pin.length == kExpectedPinLength) {
        _verifyPin();
      }
    });
  }

  void _handleAuthenticationSuccess() {
    _authProvider.resetAuthenticationState();

    switch (widget.pinCheckContext) {
      case PinCheckContextEnum.appLaunch:
        widget.onComplete?.call();
        break;
      case PinCheckContextEnum.appResume:
        moveToMain();
        break;
      case PinCheckContextEnum.change:
        Navigator.pop(context);
        MyBottomSheet.showBottomSheet_90(
            context: context, child: const PinSettingScreen());
        break;
      default: // vaultInfo
        widget.onComplete?.call();
    }
  }

  void _verifyPin() async {
    context.loaderOverlay.show();
    bool isAuthenticated = await _authProvider.verifyPin(_pin);
    context.loaderOverlay.hide();

    if (isAuthenticated) {
      _handleAuthenticationSuccess();
      return;
    }

    if (_isAppLaunchedOrResumed) {
      if (_authProvider.isPermanantlyLocked) {
        Logger.log('1 - _handlePermanentLockout');
        vibrateMedium();
        _handlePermanentLockout();
        return;
      }

      if (_authProvider.remainingAttemptCount > 0 &&
          _authProvider.remainingAttemptCount < kMaxAttemptPerTurn) {
        vibrateMediumDouble();
        setState(() {
          final remainingTimes = _authProvider.remainingAttemptCount;
          _errorMessage = _isLastChanceToTry
              ? t.errors
                  .remaining_times_away_from_reset_error(count: remainingTimes)
              : t.errors.pin_incorrect_with_remaining_attempts_error(
                  count: remainingTimes);
        });
      } else {
        vibrateMedium();
        setState(() {
          _errorMessage = '';
          _isUnlockDisabled = true;
        });

        final nextUnlockTime = _authProvider.unlockAvailableAt;
        if (nextUnlockTime != null) _startCountdownTimerUntil(nextUnlockTime);
      }
    } else {
      vibrateMediumDouble();
      setState(() {
        _errorMessage = t.errors.pin_incorrect_error;
      });
    }

    setState(() {
      _pin = '';
      _shuffledPinNumbers = _authProvider.getShuffledNumberList();
    });
  }

  void _startCountdownTimerUntil(DateTime lockoutEndTime) {
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
          _errorMessage = '';
          _isUnlockDisabled = false;

          if (_authProvider.currentTurn + 1 == kMaxTurn) {
            _isLastChanceToTry = true;
          }
        });
      } else {
        final formattedTime = _formatRemainingTime(remainingSeconds);
        setState(() {
          _errorMessage = t.errors.retry_after(time: formattedTime);
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

  void _handlePermanentLockout() {
    setState(() {
      _isLastChanceToTry = false;
      _errorMessage = t.errors.pin_max_attempts_exceeded_error;
    });
    _showResetDialog();
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
      await _authProvider.resetPin();

      if (widget.pinCheckContext == PinCheckContextEnum.appLaunch) {
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
    return _isAppLaunchedOrResumed
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
      appBarVisible: _isAppLaunchedOrResumed ? false : true,
      title: _isAppLaunchedOrResumed ? '' : t.pin_check_screen.enter_password,
      initOptionVisible: _isAppLaunchedOrResumed,
      isCloseIcon: widget.isDeleteScreen,
      pin: _pin,
      errorMessage: _errorMessage,
      onKeyTap: _onKeyTap,
      pinShuffleNumbers: _shuffledPinNumbers,
      onClosePressed: () {
        Navigator.pop(context);
      },
      onBackPressed: () {
        Navigator.pop(context);
      },
      onReset: isOnReset ? _showResetDialog : null,
      step: 0,
      lastChance: _isLastChanceToTry,
      lastChanceMessage: t.pin_check_screen.warning,
      disabled: _authProvider.isPermanantlyLocked || _isUnlockDisabled,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
