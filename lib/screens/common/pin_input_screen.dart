import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/widgets/button/key_button.dart';

import '../../widgets/pin/pin_box.dart';

class PinInputScreen extends StatefulWidget {
  final String title;
  final Text? descriptionTextWidget;
  final String pin;
  final String errorMessage;
  final void Function(String) onKeyTap;
  final List<String> pinShuffleNumbers;
  final Function? onReset;
  final VoidCallback onClosePressed;
  final VoidCallback? onBackPressed;
  final int step;
  final bool appBarVisible;
  final bool initOptionVisible;
  final bool lastChance;
  final String? lastChanceMessage;
  final bool disabled;

  const PinInputScreen(
      {super.key,
      required this.title,
      required this.pin,
      required this.errorMessage,
      required this.onKeyTap,
      required this.pinShuffleNumbers,
      required this.onClosePressed,
      this.onReset,
      this.onBackPressed,
      required this.step,
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              ],
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
