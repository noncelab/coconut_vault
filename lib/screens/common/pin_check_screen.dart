import 'dart:async';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_auth_dialog.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'pin_input_screen.dart';

class PinCheckScreen extends StatefulWidget {
  final Function? onReset;
  final Function? onSuccess;
  final PinCheckContextEnum pinCheckContext;
  const PinCheckScreen({super.key, required this.pinCheckContext, this.onReset, this.onSuccess});

  @override
  State<PinCheckScreen> createState() => _PinCheckScreenState();
}

class _PinCheckScreenState extends State<PinCheckScreen> with WidgetsBindingObserver {
  late final bool _isAppLaunched;
  late String _pin;
  late String _errorMessage;
  late PinType _pinType;

  late AuthProvider _authProvider;
  late List<String> _shuffledPinNumbers;

  DateTime? _lastPressedAt;

  // when widget.appEntrance is true
  bool _isPaused = false;
  bool? _isUnlockDisabled;
  bool _isLastChanceToTry = false;

  @override
  void initState() {
    super.initState();

    _pin = '';
    _errorMessage = '';

    _isAppLaunched =
        widget.pinCheckContext == PinCheckContextEnum.appLaunch ||
        widget.pinCheckContext == PinCheckContextEnum.restoration;

    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _pinType = _authProvider.isPinCharacter ? PinType.character : PinType.number;
    Logger.log('initState pinType: $_pinType');

    Future.microtask(() {
      _authProvider.onRequestShowAuthenticationFailedDialog = () {
        showAuthenticationFailedDialog(context, _authProvider.hasAlreadyRequestedBioPermission);
      };
      _authProvider.onAuthenticationSuccess = _handleAuthenticationSuccess;
    });

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _authProvider.updateBiometricAvailability();
      if (mounted) {
        setState(() {
          _shuffledPinNumbers = _authProvider.getShuffledNumberList();
        });
      }
      if (_authProvider.isPermanantlyLocked) {
        setState(() {
          _isUnlockDisabled = true;
        });
        return;
      }

      if (!_authProvider.isUnlockAvailable) {
        setState(() {
          _isUnlockDisabled = true;
          Logger.log('--> set _isUnlockDisabled to true');
          if (_authProvider.unlockAvailableAt != null) {
            _startCountdownTimerUntil(_authProvider.unlockAvailableAt!);
          }
        });
      } else {
        setState(() {
          _isUnlockDisabled = false;
          _isLastChanceToTry = _authProvider.currentTurn + 1 == kMaxTurn;

          if (!_authProvider.isPermanantlyLocked && _isLastChanceToTry) {
            _errorMessage = t.errors.remaining_times_away_from_reset_error(
              count: kMaxAttemptPerTurn - _authProvider.currentAttemptInTurn,
            );
          }
          Logger.log('--> set _isUnlockDisabled to false');
        });
      }
    });

    _shuffledPinNumbers = _authProvider.getShuffledNumberList();

    if (_isAppLaunched && _authProvider.isPermanantlyLocked) {
      _errorMessage = t.errors.pin_max_attempts_exceeded_error;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    /// 스크린 Pause -> 생체인증 변동사항 체크
    if (AppLifecycleState.paused == state) {
      _isPaused = true;
    } else if (AppLifecycleState.resumed == state && _isPaused) {
      _isPaused = false;
      await _authProvider.updateBiometricAvailability();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _shuffledPinNumbers = _authProvider.getShuffledNumberList();
          });
        }
      });
    }
  }

  void _onKeyTap(String value) async {
    if (_isUnlockDisabled == null ||
        _isUnlockDisabled == true ||
        _isAppLaunched && _authProvider.isPermanantlyLocked) {
      return;
    }

    if (value == kBiometricIdentifier) {
      _authProvider.verifyBiometric(context);
      return;
    }

    setState(() {
      // 문자 입력 모드
      if (_pinType == PinType.character) {
        _pin = value;
        if (_pin.isNotEmpty) {
          _verifyPin();
        }
        return;
      }

      // 6-digit PIN 입력 모드
      if (value == kDeleteBtnIdentifier) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else if (_pin.length < kExpectedPinLength) {
        _pin += value;
        vibrateExtraLight();
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
      case PinCheckContextEnum.restoration:
        widget.onSuccess?.call();
        break;
      case PinCheckContextEnum.pinChange:
        Navigator.pop(context);
        MyBottomSheet.showBottomSheet_90(context: context, child: const PinSettingScreen());
        break;
      default: // vaultInfo
        widget.onSuccess?.call();
    }
  }

  void _verifyPin() async {
    context.loaderOverlay.show();
    bool isAuthenticated = await _authProvider.verifyPin(_pin, isAppLaunchScreen: _isAppLaunched);
    if (mounted) {
      context.loaderOverlay.hide();
    }
    if (isAuthenticated) {
      _handleAuthenticationSuccess();
      return;
    }

    if (_isAppLaunched) {
      if (_authProvider.isPermanantlyLocked) {
        Logger.log('1 - _handlePermanentLockout');
        vibrateMedium();
        _handlePermanentLockout();
        return;
      }

      if (_authProvider.remainingAttemptCount > 0 &&
          _authProvider.remainingAttemptCount < kMaxAttemptPerTurn) {
        vibrateLightDouble();
        setState(() {
          final remainingTimes = _authProvider.remainingAttemptCount;
          _errorMessage =
              _isLastChanceToTry
                  ? t.errors.remaining_times_away_from_reset_error(count: remainingTimes)
                  : t.errors.pin_incorrect_with_remaining_attempts_error(count: remainingTimes);
        });
      } else {
        vibrateMedium();
        setState(() {
          _errorMessage = '';
          _isUnlockDisabled = true;
          Logger.log('--> set _isUnlockDisabled to true');
        });

        final nextUnlockTime = _authProvider.unlockAvailableAt;
        if (nextUnlockTime != null) _startCountdownTimerUntil(nextUnlockTime);
      }
    } else {
      vibrateLightDouble();
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
      final remainingSeconds = remainingDuration.inSeconds > 0 ? remainingDuration.inSeconds : 0;

      if (remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          _errorMessage = '';
          _isUnlockDisabled = false;
          Logger.log('--> set _isUnlockDisabled to false');
          _isLastChanceToTry = _authProvider.currentTurn + 1 == kMaxTurn;
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
    showDialog(
      context: context,
      builder: (context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.forgot_password.title,
          description: t.alert.forgot_password.description1,
          leftButtonText: t.cancel,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.alert.forgot_password.btn_reset,
          rightButtonColor: CoconutColors.warningText,
          onTapRight: () => _reset(),
          onTapLeft: () => Navigator.pop(context),
        );
      },
    );
  }

  Future<void> _reset() async {
    await _authProvider.resetPin(context.read<PreferenceProvider>());

    if (mounted) {
      Navigator.of(context).pop();
    }
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _isAppLaunched
        ? Material(
          color: CoconutColors.white,
          child: PopScope(
            canPop: widget.pinCheckContext == PinCheckContextEnum.restoration,
            onPopInvokedWithResult: (didPop, _) async {
              if (Platform.isAndroid && widget.pinCheckContext == PinCheckContextEnum.appLaunch) {
                final now = DateTime.now();
                if (_lastPressedAt == null ||
                    now.difference(_lastPressedAt!) > const Duration(seconds: 3)) {
                  _lastPressedAt = now;
                  Fluttertoast.showToast(
                    backgroundColor: CoconutColors.gray800,
                    msg: t.toast.back_exit,
                    toastLength: Toast.LENGTH_SHORT,
                  );
                } else {
                  SystemNavigator.pop();
                }
              }
            },
            child: Scaffold(
              backgroundColor: CoconutColors.white,
              body: Stack(children: [Center(child: _pinInputScreen(isOnReset: true))]),
            ),
          ),
        )
        : _pinInputScreen();
  }

  Widget _pinInputScreen({isOnReset = false}) {
    Logger.log(
      '--> PinInputScreen isPermanantlyLocked: ${_authProvider.isPermanantlyLocked} / isUnlockDisabled: $_isUnlockDisabled',
    );
    return PinInputScreen(
      canChangePinType: false,
      appBarVisible: _isAppLaunched ? false : true,
      title: _isAppLaunched ? '' : t.pin_check_screen.enter_password,
      initOptionVisible: _isAppLaunched,
      pin: _pin,
      errorMessage: _errorMessage,
      onKeyTap: _onKeyTap,
      pinType: PinType.number,
      pinShuffleNumbers: _shuffledPinNumbers,
      onPinClear: () {
        setState(() {
          _pin = '';
          _errorMessage = '';
        });
      },
      onReset: isOnReset ? _showResetDialog : null,
      step: 0,
      lastChance: _isLastChanceToTry,
      lastChanceMessage: t.pin_check_screen.warning,
      disabled: _authProvider.isPermanantlyLocked || _isUnlockDisabled == true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
