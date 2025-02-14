import 'dart:io';

import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:coconut_vault/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeyButton extends StatefulWidget {
  final String keyValue;
  final ValueChanged<String> onKeyTap;

  const KeyButton({
    super.key,
    required this.keyValue,
    required this.onKeyTap,
  });

  @override
  State<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<KeyButton> {
  bool _isPressed = false;
  bool _isFaceRecognition = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricType();
  }

  Future<void> _checkBiometricType() async {
    final LocalAuthentication auth = LocalAuthentication();

    try {
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();

      if (Platform.isIOS) {
        if (availableBiometrics.contains(BiometricType.face)) {
          setState(() {
            _isFaceRecognition = true;
          });
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          setState(() {
            _isFaceRecognition = false;
          });
        }
      } else {
        // aos fingerprint included case
        if (availableBiometrics.contains(BiometricType.strong) &&
            availableBiometrics.contains(BiometricType.weak)) {
          setState(() {
            _isFaceRecognition = false;
          });
        } else if (!availableBiometrics.contains(BiometricType.strong) &&
            availableBiometrics.contains(BiometricType.weak)) {
          setState(() {
            _isFaceRecognition = true;
          });
        }
      }
    } catch (e) {
      Logger.log('생체 인식 유형을 확인하는 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          widget.onKeyTap(widget.keyValue);
        },
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        child: Container(
          width: 120,
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _isPressed
                  ? MyColors.borderLightgrey
                  : Colors.transparent // 버튼의 상태에 따라 색상 변경
              ),
          child: Center(
              child: widget.keyValue == kDeleteBtnIdentifier
                  ? const Icon(Icons.backspace, color: MyColors.black, size: 20)
                  : widget.keyValue == kBiometricIdentifier
                      ? _isFaceRecognition
                          ? SvgPicture.asset('assets/svg/face-id.svg',
                              width: 20,
                              colorFilter: const ColorFilter.mode(
                                  Colors.black, BlendMode.srcIn))
                          : SvgPicture.asset('assets/svg/fingerprint.svg',
                              width: 20,
                              colorFilter: const ColorFilter.mode(
                                  Colors.black, BlendMode.srcIn))
                      : Text(
                          widget.keyValue,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: MyColors.black,
                              fontFamily: 'SpaceGrotesk'),
                        )),
        ));
  }
}
