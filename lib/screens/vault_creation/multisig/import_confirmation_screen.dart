import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/multisig/card/signer_bsms_info_card.dart';
import 'package:flutter/material.dart';

class ImportConfirmationScreen extends StatefulWidget {
  const ImportConfirmationScreen({super.key, required this.importingBsms});
  final String importingBsms;

  @override
  State<ImportConfirmationScreen> createState() => _ImportConfirmationScreenState();
}

class _ImportConfirmationScreenState extends State<ImportConfirmationScreen>
    with WidgetsBindingObserver {
  static const int kMaxTextLength = 15;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  bool isPressing = false;
  double keyboardHeight = 0.0;
  double visibleWidgetHeight = 0.0;
  String memo = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          final currentPosition = _scrollController.position.pixels;
          final maxScrollExtent = _scrollController.position.maxScrollExtent;
          final targetPosition = currentPosition + 200;

          final finalPosition = targetPosition.clamp(0.0, maxScrollExtent);
          _scrollController.animateTo(
            finalPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: t.confirm_importing_screen.scan_info,
          context: context,
          isBottom: true,
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: _closeKeyboard,
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20, // 키보드 높이만큼 여백 추가
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // tooltip
                        CustomTooltip.buildInfoTooltip(
                          context,
                          paddingTop: 8,
                          richText: RichText(
                            text: TextSpan(
                              style: CoconutTypography.body3_12,
                              children: _getTooltipRichText(),
                            ),
                          ),
                        ),
                        CoconutLayout.spacing_800h,
                        // bsms info
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.74,
                                  child: Text(
                                    t.confirm_importing_screen.scan_info,
                                    style: CoconutTypography.body1_16.merge(
                                      const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        height: 20.8 / 16,
                                        letterSpacing: -0.01,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              CoconutLayout.spacing_300h,
                              Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.74,
                                  child: SignerBsmsInfoCard(
                                    bsms: Bsms.parseSigner(widget.importingBsms),
                                  ),
                                ),
                              ),
                              CoconutLayout.spacing_900h,
                            ],
                          ),
                        ),
                        // divider
                        Container(height: 16, color: CoconutColors.gray150),
                        // memo textfield
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CoconutLayout.spacing_600h,
                              Text(
                                t.confirm_importing_screen.memo,
                                style: CoconutTypography.body1_16.merge(
                                  const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    height: 20.8 / 16,
                                    letterSpacing: -0.01,
                                  ),
                                ),
                              ),
                              CoconutLayout.spacing_300h,
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: CoconutTextField(
                                      backgroundColor: CoconutColors.white,
                                      borderRadius: 16,
                                      isLengthVisible: true,
                                      placeholderText: t.confirm_importing_screen.placeholder,
                                      maxLength: kMaxTextLength,
                                      errorText: null,
                                      descriptionText: null,
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      onChanged: (text) {
                                        setState(() => memo = _controller.text);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FixedBottomButton(
                  onButtonClicked: () {
                    Navigator.pop(context, {
                      'bsms': widget.importingBsms,
                      'memo': _controller.text,
                    });
                  },
                  text: t.complete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  List<TextSpan> _getTooltipRichText() {
    return [
      TextSpan(
        text: t.confirm_importing_screen.guide1,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.confirm_importing_screen.guide2,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.confirm_importing_screen.guide3,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
  }
}
