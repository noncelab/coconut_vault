import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/button/key_button.dart';
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
  });

  @override
  PinInputScreenState createState() => PinInputScreenState();
}

class PinInputScreenState extends State<PinInputScreen> {
  late final FocusNode _characterFocusNode;
  final TextEditingController _characterController = TextEditingController();
  late PinType _pinType;

  @override
  void initState() {
    super.initState();

    _characterFocusNode = widget.characterFocusNode ?? FocusNode();

    _pinType = widget.pinType;

    if (context.read<AuthProvider>().isPinCharacter) {
      _pinType = PinType.character;
    }

    if (_pinType == PinType.character) {
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
      body: SafeArea(
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
              SizedBox(height: 56, child: _pinType == PinType.number ? _buildNumberInput() : _buildCharacterInput()),
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
                                  child: KeyButton(keyValue: key, onKeyTap: widget.onKeyTap, disabled: widget.disabled),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                    if (widget.bottomTextButtonLabel != null)
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 50, top: 8),
                            child: GestureDetector(
                              onTap: () {
                                widget.onPressedBottomTextButton?.call();
                              },
                              child: Text(
                                widget.bottomTextButtonLabel ?? '',
                                style: CoconutTypography.body1_16_Bold.setColor(
                                  CoconutColors.black.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
