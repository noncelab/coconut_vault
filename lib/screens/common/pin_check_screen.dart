import 'dart:async';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'pin_input_screen.dart';

class PinCheckScreen extends StatefulWidget {
  final Function? onReset;
  final Function? onSuccess;
  final Function? onPermanentlyLocked;
  final PinCheckContextEnum pinCheckContext;
  const PinCheckScreen({
    super.key,
    required this.pinCheckContext,
    this.onReset,
    this.onSuccess,
    this.onPermanentlyLocked,
  });

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
  bool? _isPinInputLocked;
  bool _isLastChanceToTry = false;
  bool _isVerifyingPin = false;

  // 생체인증 실패 후 키보드가 다시 올라오게 하려고 선언하여 PinInputScreen에 넘겨줌.
  // 하지만 이미 focus상태에서 생태인증 때문에 키보드가 사라져 있는 상태라
  // 다시 requestFocus 함수 호출로 키보드가 올라오지 않는 상황
  final FocusNode _characterFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _pin = '';
    _errorMessage = '';

    _isAppLaunched = widget.pinCheckContext == PinCheckContextEnum.appLaunch;
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _pinType = _authProvider.isPinCharacter ? PinType.character : PinType.number;
    Logger.log('initState pinType: $_pinType');

    Future.microtask(() {
      _authProvider.onAuthenticationSuccess = _handleAuthenticationSuccess;
    });

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isAppLaunched) {
        setState(() {
          _isPinInputLocked = false;
        });
        return;
      }

      if (_authProvider.isPermanentlyLocked) {
        setState(() {
          _isPinInputLocked = true;
        });
        return;
      }

      if (!_authProvider.isUnlockAvailable) {
        setState(() {
          _isPinInputLocked = true;
          Logger.log('--> set _isPinInputLocked to true');
          if (_authProvider.unlockAvailableAt != null) {
            _startCountdownTimerUntil(_authProvider.unlockAvailableAt!);
          }
        });
      } else {
        setState(() {
          _isPinInputLocked = false;
          _isLastChanceToTry = _authProvider.currentTurn + 1 == kMaxTurn;

          if (!_authProvider.isPermanentlyLocked && _isLastChanceToTry) {
            _errorMessage = t.errors.remaining_times_away_from_reset_error(
              count: kMaxAttemptPerTurn - _authProvider.currentAttemptInTurn,
            );
          }
          Logger.log('--> set _isPinInputLocked to false');
        });
      }

      final authenticated = await _authenticateWithBiometricsIfEligible();
      if (authenticated) {
        _handleAuthenticationSuccess();
      } else {
        // 키보드가 다시 올라오면 좋겠는데 원하는 대로 동작을 안함
        // _characterFocusNode.requestFocus();
      }
    });

    _shuffledPinNumbers = _authProvider.getShuffledNumberList();

    if (_isAppLaunched && _authProvider.isPermanentlyLocked) {
      _errorMessage = t.errors.pin_max_attempts_exceeded_error;
    }
  }

  Future<bool> _authenticateWithBiometricsIfEligible() async {
    if (!_isAppLaunched ||
        _authProvider.isPermanentlyLocked ||
        _isPinInputLocked == true ||
        !_authProvider.isBiometricEnabled) {
      return false;
    }

    return await _authProvider.authenticateWithBiometrics();
  }

  void _onKeyTap(String value) async {
    if (_isPinInputLocked == null || _isPinInputLocked == true || _isAppLaunched && _authProvider.isPermanentlyLocked) {
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
      case PinCheckContextEnum.pinChange:
        Navigator.pop(context);
        MyBottomSheet.showBottomSheet_90(context: context, child: const PinSettingScreen());
        break;
      case PinCheckContextEnum.appLaunch:
      default: // vaultInfo
        widget.onSuccess?.call();
    }
  }

  void _verifyPin() async {
    setState(() {
      _isVerifyingPin = true;
    });
    bool isAuthenticated = await _authProvider.verifyPin(_pin, isAppLaunchScreen: _isAppLaunched);
    if (mounted) {
      setState(() {
        _isVerifyingPin = false;
      });
    }
    if (isAuthenticated) {
      _handleAuthenticationSuccess();
      return;
    }

    if (_isAppLaunched) {
      if (_authProvider.isPermanentlyLocked) {
        Logger.log('1 - _handlePermanentLockout');
        vibrateMedium();
        _handlePermanentLockout();
        return;
      }

      if (_authProvider.remainingAttemptCount > 0 && _authProvider.remainingAttemptCount < kMaxAttemptPerTurn) {
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
          _isPinInputLocked = true;
          Logger.log('--> set _isPinInputLocked to true');
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
          _isPinInputLocked = false;
          Logger.log('--> set _isPinInputLocked to false');
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
    _authProvider.resetData(context.read<PreferenceProvider>());
    widget.onPermanentlyLocked?.call();
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title:
              !_authProvider.isPermanentlyLocked
                  ? t.alert.forgot_password.title
                  : t.pin_check_screen.dialog.restart.title,
          description:
              !_authProvider.isPermanentlyLocked
                  ? t.alert.forgot_password.description1
                  : t.pin_check_screen.dialog.restart.description,
          leftButtonText: t.no,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.yes,
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
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (Platform.isAndroid && widget.pinCheckContext == PinCheckContextEnum.appLaunch) {
                final now = DateTime.now();
                if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 3)) {
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
      '--> PinInputScreen isPermanantlyLocked: ${_authProvider.isPermanentlyLocked} / isPinInputLocked: $_isPinInputLocked',
    );
    return Selector<AuthProvider, bool>(
      selector: (_, authProvider) => authProvider.isPermanentlyLocked,
      builder: (context, isPermanentlyLocked, child) {
        return PinInputScreen(
          canChangePinType: false,
          appBarVisible: _isAppLaunched ? false : true,
          title: _isAppLaunched ? '' : t.pin_check_screen.enter_password,
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
          bottomTextButtonLabel:
              _isAppLaunched
                  ? isPermanentlyLocked
                      ? t.errors.restart_vault
                      : t.forgot_password
                  : null,
          onPressedBottomTextButton: _showResetDialog,
          step: 0,
          lastChance: _isLastChanceToTry,
          lastChanceMessage: t.pin_check_screen.warning,
          disabled: isPermanentlyLocked || _isPinInputLocked == true || _isVerifyingPin,
          characterFocusNode: _characterFocusNode,
          isLoading: _isVerifyingPin,
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _characterFocusNode.dispose();
    super.dispose();
  }
}
