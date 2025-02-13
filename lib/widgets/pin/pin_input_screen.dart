import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/button/key_button.dart';
import 'package:provider/provider.dart';

import 'pin_box.dart';

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
  final bool isCloseIcon;
  final bool lastChance;
  final String? lastChanceMessage;

  const PinInputScreen({
    super.key,
    required this.title,
    required this.pin,
    required this.errorMessage,
    required this.onKeyTap,
    required this.pinShuffleNumbers,
    required this.onClosePressed,
    this.onReset,
    this.onBackPressed,
    required this.step,
    this.isCloseIcon = false,
    this.appBarVisible = true,
    this.initOptionVisible = false,
    this.descriptionTextWidget,
    this.lastChance = false,
    this.lastChanceMessage,
  });

  @override
  PinInputScreenState createState() => PinInputScreenState();
}

class PinInputScreenState extends State<PinInputScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.appBarVisible
          ? AppBar(
              backgroundColor: Colors.transparent,
              toolbarHeight: 62,
              leading: widget.isCloseIcon && widget.step == 0
                  ? IconButton(
                      onPressed: widget.onClosePressed,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: MyColors.darkgrey,
                        size: 22,
                      ),
                    )
                  : IconButton(
                      onPressed: widget.onBackPressed,
                      icon: SvgPicture.asset('assets/svg/back.svg'),
                    ),
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
              style: Styles.body1
                  .merge(const TextStyle(fontWeight: FontWeight.bold)),
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
                PinBox(isSet: widget.pin.isNotEmpty),
                const SizedBox(width: 8),
                PinBox(isSet: widget.pin.length > 1),
                const SizedBox(width: 8),
                PinBox(isSet: widget.pin.length > 2),
                const SizedBox(width: 8),
                PinBox(isSet: widget.pin.length > 3),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage,
              style: Styles.warning,
              textAlign: TextAlign.center,
            ),
            Visibility(
              visible: widget.lastChance,
              child: Text(
                widget.lastChanceMessage ?? '',
                style: Styles.warning,
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
                      style: Styles.body2.merge(const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MyColors.transparentBlack_50)),
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
