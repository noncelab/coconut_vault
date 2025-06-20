import 'dart:io';

import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';

class BrainWalletBackupBottomSheet extends StatefulWidget {
  final VoidCallback onConfirmPressed;
  final VoidCallback onCancelPressed;
  final VoidCallback? onInactivePressed;
  final List<String> phrases;
  final List<String> mnemonic;
  final String? topMessage;

  const BrainWalletBackupBottomSheet(
      {super.key,
      required this.onConfirmPressed,
      required this.onCancelPressed,
      this.onInactivePressed,
      required this.phrases,
      required this.mnemonic,
      this.topMessage});

  @override
  State<BrainWalletBackupBottomSheet> createState() => _BrainWalletBackupBottomSheetState();
}

class _BrainWalletBackupBottomSheetState extends State<BrainWalletBackupBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  bool _isBottom = false;

  @override
  void initState() {
    super.initState();

    vibrateLight();
    _isBottom = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Scaffold(
        body: Padding(
          padding: Paddings.container,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topText(),
                Text(t.brain_wallet_backup_bottom_sheet.information, style: Styles.warning),
                // const SizedBox(height: 20),
                for (int i = 0; i < widget.phrases.length; i++) ...[
                  const SizedBox(height: 50),
                  _mnemonicWidget(i),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _bottomButton(),
      ),
    );
    //);
  }

  Widget _topText() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(widget.topMessage ?? t.brain_wallet_backup_bottom_sheet.notification,
          style: Styles.appbarTitle.merge(
            const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          )),
    );
  }

  Widget _mnemonicWidget(int nmemonicIndex) {
    bool gridviewColumnFlag = false;

    widget.mnemonic[nmemonicIndex].trim();
    List<String> mnemonicWords = widget.mnemonic[nmemonicIndex].split(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${t.brain_wallet_backup_bottom_sheet.phrase} ${nmemonicIndex + 1} : ${widget.phrases[nmemonicIndex]}",
          style: Styles.body2Bold,
        ),
        const SizedBox(
          height: 8,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Number of columns
            childAspectRatio:
                MediaQuery.of(context).size.height > 640 ? 2.7 : 2, // Aspect ratio for grid items
            crossAxisSpacing: 0, // Space between columns
            mainAxisSpacing: 1, // Space between rows
          ),
          itemCount: widget.mnemonic[nmemonicIndex].split(' ').length,
          itemBuilder: (BuildContext context, int index) {
            if (index % 3 == 0) gridviewColumnFlag = !gridviewColumnFlag;
            BorderRadius borderRadius = BorderRadius.zero;
            if (index == 0) {
              borderRadius = const BorderRadius.only(topLeft: Radius.circular(8));
            } else if (index == 2) {
              borderRadius = const BorderRadius.only(topRight: Radius.circular(8));
            } else if (mnemonicWords.length == 12 && index == 9 ||
                mnemonicWords.length == 24 && index == 21) {
              borderRadius = const BorderRadius.only(bottomLeft: Radius.circular(8));
            } else if (mnemonicWords.length == 12 && index == 11 ||
                mnemonicWords.length == 24 && index == 23) {
              borderRadius = const BorderRadius.only(bottomRight: Radius.circular(8));
            }

            return Container(
              decoration: BoxDecoration(
                color: gridviewColumnFlag ? MyColors.lightgrey : MyColors.transparentBlack_06,
                borderRadius: borderRadius,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (index + 1).toString(),
                    style: Styles.body2.merge(
                      TextStyle(
                        fontFamily: CustomFonts.number.getFontFamily,
                        color: MyColors.darkgrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    widget.mnemonic[nmemonicIndex].split(' ')[index],
                    style: Styles.body1,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _bottomButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, Platform.isIOS ? 30 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: CupertinoButton(
              onPressed: widget.onCancelPressed,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              color: MyColors.lightgrey,
              alignment: Alignment.center,
              child: Text(t.cancel,
                  style: Styles.label.merge(const TextStyle(
                    color: MyColors.black,
                    fontWeight: FontWeight.w600,
                  ))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoButton(
              onPressed: _isBottom ? widget.onConfirmPressed : (widget.onInactivePressed ?? () {}),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              color: MyColors.darkgrey,
              alignment: Alignment.center,
              child: Text(
                t.mnemonic_confirm_screen.btn_confirm_completed,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
