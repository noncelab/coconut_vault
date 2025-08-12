import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/localization/strings.g.dart';
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
  final void Function(String, bool) onKeyTap;
  final List<String> pinShuffleNumbers;
  final Function? onReset;
  final VoidCallback onClosePressed;
  final VoidCallback onPinClear;
  final VoidCallback? onBackPressed;
  final int step;
  final bool appBarVisible;
  final bool initOptionVisible;
  final bool lastChance;
  final String? lastChanceMessage;
  final bool disabled;
  final bool canChangePinType;

  const PinInputScreen(
      {super.key,
      required this.title,
      required this.pin,
      required this.errorMessage,
      required this.onKeyTap,
      required this.pinShuffleNumbers,
      required this.onClosePressed,
      required this.onPinClear,
      this.onReset,
      this.onBackPressed,
      required this.step,
      required this.canChangePinType,
      this.appBarVisible = true,
      this.initOptionVisible = false,
      this.descriptionTextWidget,
      this.lastChance = false,
      this.lastChanceMessage,
      this.disabled = false});

  @override
  PinInputScreenState createState() => PinInputScreenState();
}

class PinInputScreenState extends State<PinInputScreen> {
  final FocusNode _characterFocusNode = FocusNode();
  final TextEditingController _characterController = TextEditingController();
  String _previousCharacterText = "";
  PinType _pinType = PinType.number;

  @override
  void initState() {
    super.initState();
    _characterController.addListener(_characterTextListener);
    if (context.read<AuthProvider>().isPinCharacter) {
      _pinType = PinType.character;
      _characterFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _characterFocusNode.dispose();
    _characterController.dispose();
  }

  void _characterTextListener() {
    // 문자가 입력된 경우와 삭제된 경우를 인식한다.
    String currentText = _characterController.text;
    if (currentText.length > _previousCharacterText.length) {
      String lastInserted = currentText.substring(_previousCharacterText.length);
      widget.onKeyTap(lastInserted, true);
    } else if (currentText.length < _previousCharacterText.length) {
      widget.onKeyTap('<', false);
      // 삭제 버튼을 꾹 누른 경우에 대한 처리
      if (currentText.isEmpty) {
        _previousCharacterText = "";
        _characterController.text = "";
      }
    }

    _previousCharacterText = currentText;
    // 비밀번호 확인에서 사용하는 경우를 위해 미리 정리한다.
    if (currentText.length == kExpectedPinLength) {
      _previousCharacterText = "";
      _characterController.text = "";
    }
  }

  void _togglePinType() {
    _pinType = _pinType == PinType.character ? PinType.number : PinType.character;
    FocusScope.of(context).unfocus();
    if (_pinType == PinType.character) {
      _characterFocusNode.requestFocus();
    }
    widget.onPinClear();
    _characterController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: widget.appBarVisible
          ? CoconutAppBar.build(
              context: context,
              title: '',
              backgroundColor: Colors.transparent,
              height: 62,
              isBottom: widget.step == 0,
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: widget.initOptionVisible ? 60 : 24),
            Text(
              widget.title,
              style: CoconutTypography.body1_16_Bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: widget.descriptionTextWidget ?? const Text(''),
            ),
            const SizedBox(height: 10),
            if (_pinType == PinType.number)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PinBox(isSet: widget.pin.isNotEmpty, disabled: widget.disabled),
                  const SizedBox(width: 8),
                  PinBox(isSet: widget.pin.length > 1, disabled: widget.disabled),
                  const SizedBox(width: 8),
                  PinBox(isSet: widget.pin.length > 2, disabled: widget.disabled),
                  const SizedBox(width: 8),
                  PinBox(isSet: widget.pin.length > 3, disabled: widget.disabled),
                  const SizedBox(width: 8),
                  PinBox(isSet: widget.pin.length > 4, disabled: widget.disabled),
                  const SizedBox(width: 8),
                  PinBox(isSet: widget.pin.length > 5, disabled: widget.disabled),
                ],
              ),
            if (_pinType == PinType.character)
              SizedBox(
                width: 235,
                child: CoconutTextField(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                  borderRadius: 14,
                  backgroundColor: CoconutColors.gray150,
                  placeholderColor: Colors.transparent,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  maxLines: 1,
                  isLengthVisible: false,
                  isVisibleBorder: false,
                  errorText: null,
                  descriptionText: null,
                  controller: _characterController,
                  focusNode: _characterFocusNode,
                  onChanged: (text) {},
                ),
              ),
            if (widget.canChangePinType && widget.step == 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                    height: 40,
                    child: PinTypeToggleButton(
                        isActive: true, currentPinType: _pinType, onToggle: _togglePinType)),
              ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage,
              style: CoconutTypography.body3_12.setColor(CoconutColors.warningText),
              textAlign: TextAlign.center,
            ),
            Visibility(
              visible: widget.lastChance,
              child: Text(
                widget.lastChanceMessage ?? '',
                style: CoconutTypography.body3_12.setColor(CoconutColors.warningText),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: IgnorePointer(
                ignoring: _pinType == PinType.character,
                child: Opacity(
                  opacity: _pinType == PinType.number ? 1.0 : 0.0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: widget.pinShuffleNumbers.map((key) {
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
                ),
              ),
            ),
            SizedBox(
                height: widget.initOptionVisible
                    ? 60
                    : MediaQuery.sizeOf(context).height <= 640
                        ? 30
                        : 100),
            Visibility(
              visible: widget.initOptionVisible,
              replacement: Container(),
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 60.0),
                  child: GestureDetector(
                    onTap: () {
                      widget.onReset?.call();
                    },
                    child: Text(
                      t.forgot_password,
                      style: CoconutTypography.body2_14_Bold.setColor(
                        CoconutColors.black.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
