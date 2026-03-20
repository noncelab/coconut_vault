import 'dart:async';
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loader_overlay/loader_overlay.dart';

const int kMaxAccountIndex = 0x7fffffff;

bool isValidAccountIndex(int v) => v >= 0 && v <= kMaxAccountIndex;

class AccountEditBottomSheet extends StatefulWidget {
  final int account;
  final Future<void> Function(int) onUpdate;

  const AccountEditBottomSheet({super.key, required this.account, required this.onUpdate});

  @override
  State<AccountEditBottomSheet> createState() => _AccountEditBottomSheetState();
}

class _AccountEditBottomSheetState extends State<AccountEditBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isSubmitting = false; // prevent duplicate execution of async logic caused by double taps

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
    final isChanged = validatedValue != widget.account;
    final isValid = validatedValue != null && !_isSubmitting && isChanged;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: CoconutBottomSheet(
        useIntrinsicHeight: true,
        appBar: CoconutAppBar.build(context: context, title: t.bottom_sheet.account_settings.title, isBottom: true),
        bottomMargin: 20,
        body: CustomLoadingOverlay(
          child: Builder(
            builder: (overlayContext) {
              return Padding(
                padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? keyboardHeight : 0, left: 20, right: 20, top: 8),
                child: GestureDetector(
                  onTap: _closeKeyboard,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    color: CoconutColors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            t.bottom_sheet.account_settings.description,
                            style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.hotPink),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                          errorText: t.bottom_sheet.account_settings.account_error_message,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: CoconutButton(
                            text: t.complete,
                            isActive: isValid,
                            onPressed: () => _onCompletePressed(overlayContext, validatedValue),
                            backgroundColor: CoconutColors.black,
                            foregroundColor: CoconutColors.white,
                            disabledBackgroundColor: CoconutColors.gray150,
                            disabledForegroundColor: CoconutColors.gray350,
                            height: 50.0,
                            textStyle: CoconutTypography.body1_16_Bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
        colorFilter: ColorFilter.mode(isError ? CoconutColors.hotPink : CoconutColors.gray900, BlendMode.srcIn),
      ),
    );
  }

  Future<void> _onCompletePressed(BuildContext overlayContext, int? value) async {
    if (value == null || _isSubmitting) return;

    _closeKeyboard();

    if (value == widget.account) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    overlayContext.loaderOverlay.show();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      await widget.onUpdate(value);

      await Future.delayed(const Duration(milliseconds: 300));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        overlayContext.loaderOverlay.hide();
        Navigator.of(context).pop();
      }
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
