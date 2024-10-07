import 'dart:io';

import 'package:flutter/material.dart';
import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/animated_dialog.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/pin/pin_input_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preferences_constants.dart';
import '../widgets/custom_dialog.dart';

class PinSettingScreen extends StatefulWidget {
  final bool greetingVisible;
  final Function? onComplete;
  const PinSettingScreen(
      {super.key, this.greetingVisible = false, this.onComplete});

  @override
  State<PinSettingScreen> createState() => _PinSettingScreenState();
}

class _PinSettingScreenState extends State<PinSettingScreen> {
  late bool greeting;
  int step = 0;
  late String pin;
  late String pinConfirm;
  late String errorMessage;
  late AppModel _appModel;

  @override
  void initState() {
    _appModel = Provider.of<AppModel>(context, listen: false);
    super.initState();
    greeting = widget.greetingVisible;
    pin = '';
    pinConfirm = '';
    errorMessage = '';
  }

  void returnToBackSequence(String message,
      {bool isError = false, bool firstSequence = false}) {
    setState(() {
      errorMessage = message;
      pinConfirm = '';
      _appModel.shuffleNumbers(isSettings: true);
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
    bool isSamePin = await _appModel.verifyPin(input);
    return isSamePin;
  }

  void _onKeyTap(String value) async {
    // if (value != '<' && value != 'bio' && value != '') vibrateShort();

    if (step == 0) {
      if (value == '<') {
        if (pin.isNotEmpty) {
          setState(() {
            pin = pin.substring(0, pin.length - 1);
          });
        }
      } else if (pin.length < 4) {
        setState(() {
          pin += value;
        });
      }

      if (pin.length == 4) {
        try {
          bool isAlreadyUsingPin = await _comparePin(pin);

          if (isAlreadyUsingPin) {
            returnToBackSequence('이미 사용중인 비밀번호예요', firstSequence: true);
            return;
          }
        } catch (error) {
          returnToBackSequence('처리 중 문제가 발생했어요', isError: true);
          return;
        }
        setState(() {
          step = 1;
          errorMessage = '';
          _appModel.shuffleNumbers(isSettings: true);
        });
      }
    } else if (step == 1) {
      setState(() {
        if (value == '<') {
          if (pinConfirm.isNotEmpty) {
            pinConfirm = pinConfirm.substring(0, pinConfirm.length - 1);
          }
        } else if (pinConfirm.length < 4) {
          pinConfirm += value;
        }
      });

      if (pinConfirm.length == 4) {
        if (pin != pinConfirm) {
          errorMessage = '비밀번호가 일치하지 않아요';
          pinConfirm = '';
          _appModel.shuffleNumbers(isSettings: true);
          vibrateMediumDouble();
          return;
        }

        errorMessage = '';

        /// 최초 비밀번호 설정시에 생체 인증 사용 여부 확인
        final prefs = await SharedPreferences.getInstance();
        bool isPinSet =
            prefs.getBool(SharedPreferencesConstants.isPinEnabled) ?? false;
        if (!isPinSet &&
            !_appModel.hasAlreadyRequestedBioPermission &&
            mounted) {
          await _appModel.authenticateWithBiometrics(context, isSave: true);
        }

        _finishPinSetting();
      }
    }
  }

  void _finishPinSetting() async {
    vibrateLight();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation,
          Animation secondaryAnimation) {
        return AnimatedDialog(
          context: buildContext,
          lottieAddress: 'assets/lottie/pin-locked-success.json',
          // body: '비밀번호가 설정되었습니다.',
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
    await _appModel.savePin(pinConfirm);
    Navigator.pop(context);
    Navigator.pop(context);
    if (widget.greetingVisible) {
      Navigator.pushNamed(context, '/vault-creation-options');
    }
  }

  void _showDialog() {
    if (!_appModel.isPinEnabled) {
      Navigator.of(context).pop();
    } else {
      CustomDialogs.showCustomAlertDialog(context,
          title: '비밀번호를 유지하시겠어요?',
          message: '[그만하기]를 누르면 설정 화면으로 돌아갈게요.',
          confirmButtonText: '그만하기',
          confirmButtonColor: MyColors.warningText, onConfirm: () {
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
          appBar: CustomAppBar.buildWithClose(title: '', context: context),
          body: SafeArea(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              const Center(
                  child: Text(
                '안전한 볼트 사용을 위해\n먼저 비밀번호를 설정할게요',
                style: Styles.h3,
                textAlign: TextAlign.center,
              )),
              const SizedBox(height: 100),
              CompleteButton(
                  onPressed: () {
                    setState(() {
                      greeting = false;
                    });
                    _appModel.shuffleNumbers(isSettings: true);
                  },
                  label: '확인',
                  disabled: false),
            ],
          )));
    }

    return PinInputScreen(
        title: step == 0 ? '새로운 비밀번호를 눌러주세요' : '다시 한번 확인할게요',
        descriptionTextWidget: const Text.rich(
          TextSpan(
            text: '반드시 기억할 수 있는 비밀번호로 설정해 주세요',
            style: Styles.warning,
          ),
          textAlign: TextAlign.center,
        ),
        pin: step == 0 ? pin : pinConfirm,
        errorMessage: errorMessage,
        onKeyTap: _onKeyTap,
        isCloseIcon: !widget.greetingVisible,
        onClosePressed: step == 0
            ? () {
                _showDialog();
              }
            : () {
                setState(() {
                  pin = '';
                  pinConfirm = '';
                  step = 0;
                  errorMessage = '';
                });
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
