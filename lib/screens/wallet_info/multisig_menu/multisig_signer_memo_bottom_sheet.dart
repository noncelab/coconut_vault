import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MultisigSignerNameBottomSheet extends StatefulWidget {
  final String? memo;
  final Function(String) onUpdate;

  const MultisigSignerNameBottomSheet({super.key, required this.onUpdate, required this.memo});

  @override
  State<MultisigSignerNameBottomSheet> createState() => _MultisigSignerNameBottomSheetState();
}

class _MultisigSignerNameBottomSheetState extends State<MultisigSignerNameBottomSheet> {
  late String _memo;
  final FocusNode _focusNode = FocusNode();
  bool hasChanged = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.memo ?? '';
    _memo = widget.memo ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onComplete() {
    FocusScope.of(context).unfocus();
    widget.onUpdate(_memo);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        child: Container(
          color: CoconutColors.white,
          child: SafeArea(
            child: IntrinsicHeight(
              child: Stack(
                fit: StackFit.loose,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CoconutAppBar.build(
                        customTitle: Text(
                          t.multi_sig_memo_bottom_sheet.imported_wallet_memo,
                          style: CoconutTypography.body1_16_Bold,
                        ),
                        context: context,
                        isBottom: true,
                        height: kToolbarHeight,
                        backgroundColor: CoconutColors.white,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CoconutLayout.spacing_500h,
                            CoconutTextField(
                              isLengthVisible: false,
                              placeholderColor: CoconutColors.gray400,
                              placeholderText: t.memo,
                              maxLength: 20,
                              maxLines: 1,
                              controller: _controller,
                              focusNode: _focusNode,
                              suffix: IconButton(
                                highlightColor: CoconutColors.gray200,
                                iconSize: 14,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _controller.text = '';
                                  });
                                },
                                icon:
                                    _controller.text.isNotEmpty
                                        ? SvgPicture.asset(
                                          'assets/svg/text-field-clear.svg',
                                          colorFilter: const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
                                        )
                                        : Container(),
                              ),
                              onChanged: (text) {
                                setState(() {
                                  _memo = text;
                                });
                              },
                            ),

                            // 글자 수 표시
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4, right: 4),
                                child: Text(
                                  '${_memo.length} / 20',
                                  style: CoconutTypography.body3_12_Number.setColor(CoconutColors.gray500),
                                ),
                              ),
                            ),

                            // FixedBottomButton 공간 확보 (버튼 높이 + 하단 패딩)
                            const SizedBox(
                              height:
                                  FixedBottomButton.fixedBottomButtonDefaultHeight +
                                  FixedBottomButton.fixedBottomButtonDefaultBottomPadding +
                                  16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  FixedBottomButton(
                    text: t.complete,
                    onButtonClicked: _onComplete,
                    isVisibleAboveKeyboard: false,
                    bottomPadding: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MemoTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MemoTextField({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CoconutColors.black.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: t.multi_sig_memo_bottom_sheet.placeholder,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        style: CoconutTypography.body1_16,
        placeholderStyle: CoconutTypography.body2_14.setColor(CoconutColors.black.withValues(alpha: 0.3)),
        decoration: const BoxDecoration(color: Colors.transparent),
        maxLength: 100,
        clearButtonMode: OverlayVisibilityMode.always,
        onChanged: onChanged,
      ),
    );
  }
}
