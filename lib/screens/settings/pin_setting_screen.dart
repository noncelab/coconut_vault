import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
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
    vibrateMediumDouble();
  }

  Future<bool> _comparePin(String input) async {
    bool isSamePin = await _authProvider.verifyPin(input);
    return isSamePin;
  }

  void _onKeyTap(String value, bool isCharacter) async {
    // if (value != '<' && value != 'bio' && value != '') vibrateShort();

    if (step == 0) {
      if (value == kDeleteBtnIdentifier && !isCharacter) {
        if (pin.isNotEmpty) {
          setState(() {
            pin = pin.substring(0, pin.length - 1);
          });
        }
      } else if (pin.length < kExpectedPinLength) {
        setState(() {
          pin += value;
        });
      }

      if (pin.length == kExpectedPinLength) {
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
          _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
        });
      }
    } else if (step == 1) {
      setState(() {
        if (value == kDeleteBtnIdentifier && !isCharacter) {
          if (pinConfirm.isNotEmpty) {
            pinConfirm = pinConfirm.substring(0, pinConfirm.length - 1);
          }
        } else if (pinConfirm.length < kExpectedPinLength) {
          pinConfirm += value;
        }
      });

      if (pinConfirm.length == kExpectedPinLength) {
        if (pin != pinConfirm) {
          errorMessage = t.errors.pin_incorrect_error;
          pinConfirm = '';
          _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
          vibrateMediumDouble();
          return;
        }

        errorMessage = '';

        /// 최초 비밀번호 설정시에 생체 인증 사용 여부 확인
        bool isPinSet = SharedPrefsRepository().getBool(SharedPrefsKeys.isPinEnabled) ?? false;
        if (!isPinSet &&
            _authProvider.canCheckBiometrics &&
            !_authProvider.hasAlreadyRequestedBioPermission &&
            mounted) {
          await _authProvider.authenticateWithBiometrics(context: context, isSaved: true);
        }

        _finishPinSetting(isCharacter);
      }
    }
  }

  void _finishPinSetting(bool isCharacter) async {
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
    await _authProvider.savePin(pinConfirm, isCharacter);

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
