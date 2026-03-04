import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loader_overlay/loader_overlay.dart';

const int kMaxAccountIndex = 0x7fffffff;

bool isValidAccountIndex(int v) => v >= 0 && v <= kMaxAccountIndex;

class AccountEditBottomSheet extends StatefulWidget {
  final int account;
  final Function(int) onUpdate;

  const AccountEditBottomSheet({super.key, required this.account, required this.onUpdate});

  @override
  State<AccountEditBottomSheet> createState() => _AccountEditBottomSheetState();
}

class _AccountEditBottomSheetState extends State<AccountEditBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.account.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  int? get _validatedValue {
    final text = _controller.text;
    if (text.isEmpty) return null;

    final value = int.tryParse(text);
    if (value == null || !isValidAccountIndex(value)) {
      return null;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final validatedValue = _validatedValue;
    final isError = _controller.text.isNotEmpty && validatedValue == null;
    final isValid = validatedValue != null;

    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: CustomLoadingOverlay(
        child: Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(context: context, title: t.bottom_sheet.account_settings.title, isBottom: true),
          body: SafeArea(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _closeKeyboard,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: CoconutColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CoconutTextField(
                          isLengthVisible: false,
                          placeholderColor: CoconutColors.gray400,
                          placeholderText: t.bottom_sheet.account_settings.placeholder,
                          maxLength: 10,
                          maxLines: 1,
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (_) {},
                          textInputType: TextInputType.number,
                          textInputFormatter: [FilteringTextInputFormatter.digitsOnly],
                          isError: isError,
                          suffix: _buildClearButton(isError),
                        ),
                        if (isError) ...[
                          const SizedBox(height: 8),
                          Text(
                            t.bottom_sheet.account_settings.account_error_message,
                            style: CoconutTypography.body3_12.setColor(CoconutColors.hotPink),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                FixedBottomButton(
                  text: t.complete,
                  isActive: isValid,
                  onButtonClicked: () => _onNextPressed(validatedValue),
                  showGradient: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildClearButton(bool isError) {
    if (_controller.text.isEmpty) return null;

    return IconButton(
      highlightColor: CoconutColors.gray200,
      iconSize: 14,
      padding: EdgeInsets.zero,
      onPressed: _controller.clear,
      icon: SvgPicture.asset(
        'assets/svg/text-field-clear.svg',
        colorFilter: ColorFilter.mode(isError ? CoconutColors.hotPink : CoconutColors.gray400, BlendMode.srcIn),
      ),
    );
  }

  Future<void> _onNextPressed(int? value) async {
    if (value == null) return;

    _closeKeyboard();

    if (value == widget.account) {
      Navigator.of(context).pop();
      return;
    }

    context.loaderOverlay.show();
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    context.loaderOverlay.hide();

    widget.onUpdate(value);
    Navigator.of(context).pop();
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
