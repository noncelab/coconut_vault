import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/animated_dialog.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/screens/common/pin_input_screen.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_dialog.dart';

class PinSettingScreen extends StatefulWidget {
  final bool greetingVisible;
  final Function? onComplete;
  const PinSettingScreen({super.key, this.greetingVisible = false, this.onComplete});

  @override
  State<PinSettingScreen> createState() => _PinSettingScreenState();
}

class _PinSettingScreenState extends State<PinSettingScreen> {
  late bool greeting;
  int step = 0;
  late String pin;
  late String pinConfirm;
  late String errorMessage;
  PinType _currentPinType = PinType.number;

  late AuthProvider _authProvider;
  late List<String> _shuffledPinNumbers;

  @override
  void initState() {
    super.initState();
    pin = '';
    pinConfirm = '';
    errorMessage = '';
    greeting = widget.greetingVisible;

    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);

    _currentPinType = _authProvider.isPinCharacter ? PinType.character : PinType.number;
  }

  void returnToBackSequence(String message, {bool isError = false, bool firstSequence = false}) {
    setState(() {
      errorMessage = message;
      pinConfirm = '';

      _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
      if (firstSequence) {
        step = 0;
        pin = '';
      }
    });

    if (isError) {
      vibrateMedium();
      return;
    }
    vibrateLightDouble();
  }

  Future<bool> _comparePin(String input) async {
    bool isSamePin = await _authProvider.verifyPin(input);
    return isSamePin;
  }

  // 입력 모드 변경 핸들러 추가: 입력 모드가 변경되면 입력값 초기화
  void _onPinTypeChanged(PinType newPinType) {
    setState(() {
      _currentPinType = newPinType;
      pin = '';
      pinConfirm = '';
      errorMessage = '';
      if (step == 1) {
        step = 0;
      }
    });
  }

  void _onKeyTap(String value) async {
    if (_currentPinType == PinType.character) {
      // 문자 입력 모드에서 'Done' 버튼을 누르는 경우
      _onPressDoneKey(value);
    } else {
      _onKeyTapNumber(value);
    }
  }

  void _onPressDoneKey(String value) {
    if (step == 0) {
      pin = value;

      if (pin.isNotEmpty) {
        _proceedToNextStep();
      }
    } else {
      pinConfirm = value;

      if (pinConfirm.isNotEmpty) {
        _finalizePinSetup();
      }
    }
  }

  void _proceedToNextStep() async {
    try {
      bool isAlreadyUsingPin = await _comparePin(pin);

      if (isAlreadyUsingPin) {
        returnToBackSequence(t.errors.duplicate_pin_error, firstSequence: true);
        return;
      }
    } catch (error) {
      returnToBackSequence(t.errors.pin_processing_error, isError: true);
      return;
    }
    setState(() {
      step = 1;
      errorMessage = '';
      if (_currentPinType == PinType.number) {
        _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
      }
    });
  }

  /// 비밀번호 일치 여부 확인 후 저장
  /// 비밀번호 최초 설정 시 생체 인증 사용 여부 확인
  Future<void> _finalizePinSetup() async {
    if (pin != pinConfirm) {
      errorMessage = t.errors.pin_incorrect_error;
      pinConfirm = '';
      if (_currentPinType == PinType.number) {
        _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
      }
      setState(() {});
      vibrateLightDouble();
      return;
    }

    setState(() {
      errorMessage = '';
    });

    // 생체 인증 사용 여부 확인
    bool isPinSet = SharedPrefsRepository().getBool(SharedPrefsKeys.isPinEnabled) ?? false;
    if (!isPinSet &&
        _authProvider.canCheckBiometrics &&
        !_authProvider.hasAlreadyRequestedBioPermission &&
        mounted) {
      await _authProvider.authenticateWithBiometrics(context: context, isSaved: true);
    }

    // 비밀번호 저장 후 화면 이동
    await _savePin();
  }

  // 숫자 모드 PIN 입력 처리
  void _onKeyTapNumber(String value) async {
    if (step == 0) {
      if (value == kDeleteBtnIdentifier) {
        if (pin.isNotEmpty) {
          setState(() {
            pin = pin.substring(0, pin.length - 1);
          });
        }
      } else if (pin.length < kExpectedPinLength) {
        setState(() {
          pin += value;
        });
        vibrateLight();
      }

      if (pin.length == kExpectedPinLength) {
        _proceedToNextStep();
      }
    } else {
      if (value == kDeleteBtnIdentifier) {
        if (pinConfirm.isNotEmpty) {
          setState(() {
            pinConfirm = pinConfirm.substring(0, pinConfirm.length - 1);
          });
        }
      } else if (pinConfirm.length < kExpectedPinLength) {
        setState(() {
          pinConfirm += value;
          vibrateLight();
        });
      }

      if (pinConfirm.length == kExpectedPinLength) {
        _finalizePinSetup();
      }
    }
  }

  Future<void> _savePin() async {
    vibrateLight();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return AnimatedDialog(
          context: buildContext,
          lottieAddress: 'assets/lottie/pin-locked-success.json',
          duration: 400,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ).drive(Tween<Offset>(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          )),
          child: child,
        );
      },
    );

    await Future.delayed(const Duration(seconds: 3));
    widget.onComplete?.call();
    await _authProvider.savePin(pinConfirm, _currentPinType == PinType.character ? true : false);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
    Navigator.pop(context);
    if (widget.greetingVisible) {
      Navigator.pushNamed(context, AppRoutes.vaultTypeSelection);
    }
  }

  void showDialog() {
    if (!_authProvider.isPinSet) {
      Navigator.of(context).pop();
    } else {
      CustomDialogs.showCustomAlertDialog(context,
          title: t.alert.unchange_password.title,
          message: t.alert.unchange_password.description,
          confirmButtonText: t.stop,
          confirmButtonColor: CoconutColors.warningText, onConfirm: () {
        // 스택 두단계 뒤로 이동
        int count = 0;
        Navigator.of(context).popUntil((route) {
          return count++ == 2;
        });
      }, onCancel: () {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (greeting) {
      return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CoconutAppBar.build(
            title: '',
            context: context,
            isBottom: true,
          ),
          body: SafeArea(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              Center(
                  child: Text(
                t.pin_setting_screen.set_password,
                style: CoconutTypography.heading4_18_Bold,
                textAlign: TextAlign.center,
              )),
              const SizedBox(height: 100),
              CompleteButton(
                  onPressed: () {
                    setState(() {
                      greeting = false;
                    });
                  },
                  label: t.confirm,
                  disabled: false),
            ],
          )));
    }

    return PinInputScreen(
        canChangePinType: true,
        title: step == 0 ? t.pin_setting_screen.new_password : t.pin_setting_screen.enter_again,
        descriptionTextWidget: Text.rich(
          TextSpan(
            text: t.pin_setting_screen.keep_in_mind,
            style: CoconutTypography.body3_12.setColor(CoconutColors.warningText),
          ),
          textAlign: TextAlign.center,
        ),
        pin: step == 0 ? pin : pinConfirm,
        errorMessage: errorMessage,
        onKeyTap: _onKeyTap,
        onPinTypeChanged: _onPinTypeChanged,
        pinType: _currentPinType,
        pinShuffleNumbers: _shuffledPinNumbers,
        onClosePressed: step == 0
            ? () {
                showDialog();
              }
            : () {
                setState(() {
                  pin = '';
                  pinConfirm = '';
                  step = 0;
                  errorMessage = '';
                });
              },
        onPinClear: () {
          if (step == 0) {
            pin = '';
          } else {
            pinConfirm = '';
          }
          setState(() {});
        },
        onBackPressed: () {
          setState(() {
            if (widget.greetingVisible) {
              greeting = true;
            }
            pin = '';
            pinConfirm = '';
            step = 0;
            errorMessage = '';
          });
        },
        step: step);
  }
}
