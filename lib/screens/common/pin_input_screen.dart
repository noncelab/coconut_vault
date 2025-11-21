import 'dart:async';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/button/key_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../widgets/pin/pin_box.dart';

class PinInputScreen extends StatefulWidget {
  final String title;
  final Text? descriptionTextWidget;
  final String pin;
  final String errorMessage;
  final void Function(String) onKeyTap;
  final List<String> pinShuffleNumbers;
  final String? bottomTextButtonLabel;
  final Function? onPressedBottomTextButton;
  final VoidCallback onPinClear;
  final int step;
  final bool appBarVisible;
  final bool lastChance;
  final String? lastChanceMessage;
  final bool disabled;
  final bool canChangePinType;
  final PinType pinType; // 문자 또는 6-digit PIN 입력 모드 확인용
  final Function(PinType)? onPinTypeChanged; // 입력 모드 변경 핸들러
  final FocusNode? characterFocusNode;
  final bool isLoading;
  final bool shouldDelayKeyboard;

  const PinInputScreen({
    super.key,
    required this.title,
    required this.pin,
    required this.errorMessage,
    required this.onKeyTap,
    required this.pinShuffleNumbers,
    required this.onPinClear,
    required this.step,
    required this.canChangePinType,
    this.appBarVisible = true,
    this.bottomTextButtonLabel,
    this.onPressedBottomTextButton,
    this.descriptionTextWidget,
    this.lastChance = false,
    this.lastChanceMessage,
    this.disabled = false,
    this.pinType = PinType.number,
    this.onPinTypeChanged,
    this.characterFocusNode,
    this.isLoading = false,
    this.shouldDelayKeyboard = false,
  });

  @override
  PinInputScreenState createState() => PinInputScreenState();
}

class PinInputScreenState extends State<PinInputScreen> {
  late final FocusNode _characterFocusNode;
  final TextEditingController _characterController = TextEditingController();
  late PinType _pinType;
  bool _hideBottomPadding = false;
  double get keyboardHeight => MediaQuery.of(context).viewInsets.bottom;

  // 안드로이드 키보드 focus 설정을 IOS스타일과 동일시 하기 위한 코드
  // ignore: unused_field
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void initState() {
    super.initState();

    _characterFocusNode = widget.characterFocusNode ?? FocusNode();

    _characterFocusNode.addListener(() {
      if (_characterFocusNode.hasFocus) {
        setState(() {
          _hideBottomPadding = true;
        });
      } else {
        setState(() {
          _hideBottomPadding = false;
        });
      }
    });

    _keyboardSubscription = KeyboardVisibilityController().onChange.listen((visible) {
      if (!visible && mounted) {
        FocusScope.of(context).unfocus();
      }
    });

    _pinType = widget.pinType;

    if (_pinType == PinType.character && !widget.shouldDelayKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          _characterFocusNode.requestFocus();
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.characterFocusNode == null) {
      _characterFocusNode.dispose();
    }
    _characterController.dispose();
  }

  void _togglePinType() {
    _pinType = _pinType == PinType.character ? PinType.number : PinType.character;
    FocusScope.of(context).unfocus();
    if (_pinType == PinType.character) {
      _characterFocusNode.requestFocus();
    }
    widget.onPinClear();
    _characterController.clear();

    widget.onPinTypeChanged?.call(_pinType);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final keyboardBackgroundColor =
        Platform.isIOS
            ? (isDarkMode ? const Color(0x00000082) : const Color(0xFFCED2D9))
            : (isDarkMode ? CoconutColors.gray400 : CoconutColors.gray150);

    final isBiometricEnabled = Provider.of<AuthProvider>(context, listen: false).isBiometricEnabled;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar:
          widget.appBarVisible
              ? CoconutAppBar.build(
                context: context,
                title: '',
                backgroundColor: Colors.transparent,
                height: 62,
                isBottom: widget.step == 0,
              )
              : null,
      body: Stack(
        children: [
          SafeArea(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (widget.bottomTextButtonLabel != null) const SizedBox(height: 60),
                  if (widget.title.isNotEmpty)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(widget.title, style: CoconutTypography.body1_16_Bold, textAlign: TextAlign.center),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (widget.descriptionTextWidget != null) ...[
                    Align(alignment: Alignment.center, child: widget.descriptionTextWidget ?? const Text('')),
                    CoconutLayout.spacing_200h,
                  ],
                  SizedBox(
                    height: 56,
                    child: _pinType == PinType.number ? _buildNumberInput() : _buildCharacterInput(),
                  ),
                  if (widget.canChangePinType && widget.step == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        height: 40,
                        child: PinTypeToggleButton(isActive: true, currentPinType: _pinType, onToggle: _togglePinType),
                      ),
                    ),
                  Visibility(
                    visible: widget.errorMessage.isNotEmpty,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        widget.errorMessage,
                        style: CoconutTypography.body1_16.setColor(CoconutColors.warningText),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.lastChance,
                    child: Text(
                      widget.lastChanceMessage ?? '',
                      style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.warningText),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_pinType != PinType.character) ...[
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: GridView.count(
                              crossAxisCount: 3,
                              childAspectRatio:
                                  MediaQuery.of(context).size.width > 600
                                      ? 2.5 // 폴드 펼친화면에서는 버튼 사이즈 줄여서 공간 확보
                                      : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children:
                                  widget.pinShuffleNumbers.map((key) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: KeyButton(
                                        keyValue: key,
                                        onKeyTap: widget.onKeyTap,
                                        disabled: widget.disabled,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                          if (widget.bottomTextButtonLabel != null) ...[_buildBottomTextButton()],
                        ] else ...[
                          if (widget.bottomTextButtonLabel != null) ...[
                            _buildBottomTextButton(),
                            if (isBiometricEnabled && _characterFocusNode.hasFocus) ...[
                              Container(
                                color: keyboardBackgroundColor,
                                width: MediaQuery.of(context).size.width,
                                child: Align(alignment: Alignment.center, child: _buildBiometricsButton(context)),
                              ),
                            ],
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 로딩 오버레이
          if (widget.isLoading)
            Container(
              color: CoconutColors.white.withValues(alpha: 0.5),
              child: const Center(child: CoconutCircularIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomTextButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: _hideBottomPadding ? 50 : 30, top: 8),
          child: GestureDetector(
            onTap: () {
              widget.onPressedBottomTextButton?.call();
            },
            child: Text(
              widget.bottomTextButtonLabel ?? '',
              style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.black.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricsButton(BuildContext context) {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final bool isFaceRecognition = provider.availableBiometrics.contains(BiometricType.face);

    final String iconAsset = isFaceRecognition ? 'assets/svg/face-id.svg' : 'assets/svg/fingerprint.svg';

    return Padding(
      padding: EdgeInsets.only(bottom: _hideBottomPadding ? keyboardHeight + 8 : 100, top: _hideBottomPadding ? 8 : 8),
      child: GestureDetector(
        onTap: () {
          widget.onKeyTap(kBiometricIdentifier);
        },
        child: Container(
          width: 69,
          height: 48,
          decoration: BoxDecoration(
            color:
                MediaQuery.of(context).platformBrightness == Brightness.dark
                    ? (Platform.isIOS ? CoconutColors.gray400 : CoconutColors.gray400)
                    : CoconutColors.white,
            border: Border.all(color: CoconutColors.gray350, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: SvgPicture.asset(iconAsset, width: 24, height: 24, color: CoconutColors.gray800)),
        ),
      ),
    );
  }

  Widget _buildNumberInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PinBox(isSet: widget.pin.isNotEmpty, disabled: widget.disabled),
        CoconutLayout.spacing_200w,
        PinBox(isSet: widget.pin.length > 1, disabled: widget.disabled),
        CoconutLayout.spacing_200w,
        PinBox(isSet: widget.pin.length > 2, disabled: widget.disabled),
        CoconutLayout.spacing_200w,
        PinBox(isSet: widget.pin.length > 3, disabled: widget.disabled),
        CoconutLayout.spacing_200w,
        PinBox(isSet: widget.pin.length > 4, disabled: widget.disabled),
        CoconutLayout.spacing_200w,
        PinBox(isSet: widget.pin.length > 5, disabled: widget.disabled),
      ],
    );
  }

  Widget _buildCharacterInput() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: SizedBox(
        width: 270,
        child: CoconutTextField(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          borderRadius: 12,
          backgroundColor: CoconutColors.gray150,
          placeholderColor: Colors.transparent,
          textAlign: TextAlign.center,
          maxLines: 1,
          isLengthVisible: false,
          isVisibleBorder: false,
          errorText: null,
          descriptionText: null,
          controller: _characterController,
          focusNode: _characterFocusNode,
          onChanged: (text) {},
          textInputAction: TextInputAction.done,
          enabled: !widget.disabled,
          onEditingComplete: () {
            // 문자 입력 모드에서 'Done' 버튼을 누르는 경우 다음 단계로 이동
            if (_pinType == PinType.character) {
              widget.onKeyTap(_characterController.text);

              if (widget.step == 0) {
                _characterController.clear();
                return;
              }
            }
          },
        ),
      ),
    );
  }
}
