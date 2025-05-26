import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/multisig/card/signer_bsms_info_card.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';

class ImportConfirmationScreen extends StatefulWidget {
  const ImportConfirmationScreen({
    super.key,
    required this.importingBsms,
    required this.scrollController,
  });
  final String importingBsms;
  final ScrollController scrollController;

  @override
  State<ImportConfirmationScreen> createState() => _ImportConfirmationScreenState();
}

class _ImportConfirmationScreenState extends State<ImportConfirmationScreen>
    with WidgetsBindingObserver {
  static const int kMaxTextLength = 15;
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
        padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          color: MyCoCoconutColorslors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTooltip(
                richText: RichText(
                  text: TextSpan(
                    text: t.confirm_importing_screen.guide1,
                    style: Styles.body1.merge(
                      const TextStyle(
                        height: 20.8 / 16,
                        letterSpacing: -0.01,
                      ),
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: t.confirm_importing_screen.guide2,
                        style: Styles.body1.merge(
                          const TextStyle(
                            fontWeight: FontWeight.bold,
                            height: 20.8 / 16,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: t.confirm_importing_screen.guide3,
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
                      t.confirm_importing_screen.scan_info,
                      style: Styles.body1.merge(
                        const TextStyle(
                          fontWeight: FontWeight.bold,
                          height: 20.8 / 16,
                          letterSpacing: -0.01,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SignerBsmsInfoCard(bsms: Bsms.parseSigner(widget.importingBsms)),
                    const SizedBox(height: 36),
                    Text(
                      t.confirm_importing_screen.memo,
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
                            color: CoconutColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: CoconutColors.black.withOpacity(0.15),
                                offset: const Offset(4, 4),
                                blurRadius: 30,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: CustomTextField(
                            placeholder: t.confirm_importing_screen.placeholder,
                            maxLength: 15,
                            controller: _controller,
                            clearButtonMode: OverlayVisibilityMode.never,
                            focusNode: _focusNode,
                            focusedBorderColor: CoconutColors.black.withOpacity(0.5),
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
                              '${_controller.text.length} / $kMaxTextLength',
                              style: TextStyle(
                                  color: _controller.text.length == kMaxTextLength
                                      ? CoconutColors.black.withOpacity(0.7)
                                      : CoconutColors.black.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: CustomFonts.text.getFontFamily),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    CompleteButton(
                      onPressed: () {
                        Navigator.pop(
                            context, {'bsms': widget.importingBsms, 'memo': _controller.text});
                      },
                      label: t.complete,
                      disabled: false,
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
