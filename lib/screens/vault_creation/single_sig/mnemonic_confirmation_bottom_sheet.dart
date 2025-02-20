import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';

class MnemonicConfirmationBottomSheet extends StatefulWidget {
  final VoidCallback onConfirmPressed;
  final VoidCallback onCancelPressed;
  final VoidCallback? onInactivePressed;
  final String mnemonic;
  final String? passphrase;
  final String? topMessage;

  const MnemonicConfirmationBottomSheet(
      {super.key,
      required this.onConfirmPressed,
      required this.onCancelPressed,
      this.onInactivePressed,
      required this.mnemonic,
      this.passphrase,
      this.topMessage});

  @override
  State<MnemonicConfirmationBottomSheet> createState() =>
      _MnemonicConfirmationBottomSheetState();
}

class _MnemonicConfirmationBottomSheetState
    extends State<MnemonicConfirmationBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  bool _isBottom = false;

  @override
  void initState() {
    super.initState();

    vibrateLight();
    if (widget.passphrase == null) _isBottom = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.passphrase != null) {
        if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 300) {
          setState(() {
            _isBottom = true;
          });
        }

        _scrollController.addListener(_scrollListener);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 30) {
      setState(() {
        _isBottom = true;
      });
    }
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
                const SizedBox(height: 20),
                _mnemonicWidget(),
                const SizedBox(height: 20),
                Visibility(
                  visible: widget.passphrase != null,
                  child: Row(
                    children: [
                      Text(t.passphrase, style: Styles.body2Bold),
                      Text(
                        t.mnemonic_confirm_screen
                            .passphrase_character_total_count(
                                count: widget.passphrase != null
                                    ? widget.passphrase!.length.toString()
                                    : '0'),
                        style: TextStyle(
                          fontFamily: CustomFonts.text.getFontFamily,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                          color: MyColors.darkgrey,
                        ),
                      ),
                    ],
                  ),
                ),
                _hintText(),
                const SizedBox(height: 8),
                _passphraseGridViewWidget(),
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
      child: Text(widget.topMessage ?? t.mnemonic_confirm_screen.title,
          style: Styles.appbarTitle.merge(
            const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          )),
    );
  }

  Widget _hintText() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: widget.passphrase?.contains(' ') ?? false,
            child: Text(
              t.mnemonic_confirm_screen.warning.contains_space_character,
              style: Styles.warning,
            ),
          ),
          Opacity(
            opacity: !_isBottom ? 1.0 : 0.0,
            child: Text(
              t.mnemonic_confirm_screen.warning.long_passphrase,
              style: TextStyle(
                  color: MyColors.warningText,
                  fontSize: 12.0,
                  fontFamily: CustomFonts.text.getFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mnemonicWidget() {
    bool gridviewColumnFlag = false;

    widget.mnemonic.trim();
    List<String> mnemonicWords = widget.mnemonic.split(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.mnemonic,
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
            childAspectRatio: MediaQuery.of(context).size.height > 640
                ? 2.7
                : 2, // Aspect ratio for grid items
            crossAxisSpacing: 0, // Space between columns
            mainAxisSpacing: 1, // Space between rows
          ),
          itemCount: widget.mnemonic.split(' ').length,
          itemBuilder: (BuildContext context, int index) {
            if (index % 3 == 0) gridviewColumnFlag = !gridviewColumnFlag;
            BorderRadius borderRadius = BorderRadius.zero;
            if (index == 0) {
              borderRadius =
                  const BorderRadius.only(topLeft: Radius.circular(8));
            } else if (index == 2) {
              borderRadius =
                  const BorderRadius.only(topRight: Radius.circular(8));
            } else if (mnemonicWords.length == 12 && index == 9 ||
                mnemonicWords.length == 24 && index == 21) {
              borderRadius =
                  const BorderRadius.only(bottomLeft: Radius.circular(8));
            } else if (mnemonicWords.length == 12 && index == 11 ||
                mnemonicWords.length == 24 && index == 23) {
              borderRadius =
                  const BorderRadius.only(bottomRight: Radius.circular(8));
            }

            return Container(
              decoration: BoxDecoration(
                color: gridviewColumnFlag
                    ? MyColors.lightgrey
                    : MyColors.transparentBlack_06,
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
                    widget.mnemonic.split(' ')[index],
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
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
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
              onPressed: _isBottom
                  ? widget.onConfirmPressed
                  : (widget.onInactivePressed ?? () {}),
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

  Widget _passphraseGridViewWidget() {
    if (widget.passphrase == null) return Container();
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 10,
      crossAxisSpacing: 3.0,
      mainAxisSpacing: 10.0,
      shrinkWrap: true,
      children: List.generate((widget.passphrase!.length + 20), (index) {
        // 가장 아래에 빈 공간을 배치하기 위한 조건문
        if (index < widget.passphrase!.length) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MyColors.white,
              border: Border.all(
                width: 1,
                color: MyColors.black,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Visibility(
                  visible: index % 10 == 0,
                  child: Positioned(
                    top: 3,
                    left: 3,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: MyColors.borderGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 6),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Text(
                      widget.passphrase![index],
                      style: const TextStyle(
                        color: MyColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // 빈 공간을 추가하기 위해 빈 컨테이너를 반환
          return Container();
        }
      }),
    );
  }
}
