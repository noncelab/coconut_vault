import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/widgets/multisig/card/signer_bsms_info_card.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';

class ConfirmImportingScreen extends StatefulWidget {
  const ConfirmImportingScreen({
    super.key,
    required this.importingBsms,
    required this.scrollController,
  });
  final String importingBsms;
  final ScrollController scrollController;

  @override
  State<ConfirmImportingScreen> createState() => _ConfirmImportingScreenState();
}

class _ConfirmImportingScreenState extends State<ConfirmImportingScreen>
    with WidgetsBindingObserver {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  bool isPressing = false;
  double keyboardHeight = 0.0;
  double visibleWidgetHeight = 0.0;
  String memo = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    setState(() {
      if (keyboardHeight == bottomInset) {
        Future.delayed(const Duration(milliseconds: 50)).then((_) {
          scrollToBottom();
        });
      } else {
        keyboardHeight = bottomInset;
      }
    });
  }

  void scrollToBottom() {
    if (widget.scrollController.hasClients &&
        !widget.scrollController.position.isScrollingNotifier.value) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _closeKeyboard(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 30),
        padding: EdgeInsets.only(
            top: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          color: MyColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTooltip(
                richText: RichText(
                  text: TextSpan(
                    text: '다른 볼트에서 가져온 ',
                    style: Styles.body1.merge(
                      const TextStyle(
                        height: 20.8 / 16,
                        letterSpacing: -0.01,
                      ),
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '정보가 일치하는지 ',
                        style: Styles.body1.merge(
                          const TextStyle(
                            fontWeight: FontWeight.bold,
                            height: 20.8 / 16,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: '확인해 주세요.',
                        style: Styles.body1.merge(
                          const TextStyle(
                            height: 20.8 / 16,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                showIcon: true,
                type: TooltipType.info,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '스캔한 정보',
                      style: Styles.body1.merge(
                        const TextStyle(
                          fontWeight: FontWeight.bold,
                          height: 20.8 / 16,
                          letterSpacing: -0.01,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SignerBsmsInfoCard(
                        bsms: BSMS.parseSigner(widget.importingBsms)),
                    const SizedBox(height: 36),
                    Text(
                      '메모',
                      style: Styles.body1.merge(
                        const TextStyle(
                          fontWeight: FontWeight.bold,
                          height: 20.8 / 16,
                          letterSpacing: -0.01,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: MyColors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: MyColors.transparentBlack_15,
                                offset: Offset(4, 4),
                                blurRadius: 30,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: CustomTextField(
                            placeholder: '키에 대한 간단한 메모를 추가하세요',
                            maxLength: 15,
                            controller: _controller,
                            clearButtonMode: OverlayVisibilityMode.never,
                            focusNode: _focusNode,
                            focusedBorderColor: MyColors.transparentBlack_50,
                            onChanged: (text) {
                              setState(() => memo = _controller.text);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 4),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              '${_controller.text.length} / 15',
                              style: TextStyle(
                                  color: _controller.text.length == 15
                                      ? MyColors.transparentBlack
                                      : MyColors.transparentBlack_50,
                                  fontSize: 12,
                                  fontFamily: CustomFonts.text.getFontFamily),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isPressing = false;
                          });
                          Navigator.pop(context, {
                            'bsms': widget.importingBsms,
                            'memo': _controller.text
                          });
                        },
                        onTapDown: (details) {
                          setState(() {
                            isPressing = true;
                          });
                        },
                        onTapCancel: () {
                          setState(() {
                            isPressing = false;
                          });
                        },
                        child: Container(
                          width: 90,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30.0,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: isPressing
                                  ? MyColors.transparentBlack_03
                                  : MyColors.transparentBlack_06,
                            ),
                            color: isPressing
                                ? MyColors.transparentBlack_70
                                : MyColors.darkgrey,
                          ),
                          child: const Center(
                            child: Text(
                              '완 료',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
