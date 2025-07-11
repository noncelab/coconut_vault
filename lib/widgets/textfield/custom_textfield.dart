import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextStyle? placeholderStyle;
  final TextStyle style;
  final ValueChanged<String> onChanged;
  final int? maxLines;
  final int? minLines;
  final EdgeInsetsGeometry padding;
  final bool obscureText;
  final Widget? suffix;
  final bool? valid;
  final String errorMessage;
  final OverlayVisibilityMode clearButtonMode;
  final FocusNode? focusNode;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Color focusedBorderColor;
  final void Function()? onFocused;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
    this.style = CoconutTypography.body1_16,
    this.placeholderStyle,
    this.maxLines,
    this.minLines,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 20),
    this.obscureText = false,
    this.suffix,
    this.valid,
    this.errorMessage = '',
    this.clearButtonMode = OverlayVisibilityMode.never,
    this.focusNode,
    this.maxLength,
    this.inputFormatters,
    this.focusedBorderColor = CoconutColors.black,
    this.onFocused,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      buildTextField(),
      if (widget.errorMessage.isNotEmpty && widget.valid == false)
        Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Text(
              widget.errorMessage,
              style: const TextStyle(
                  color: CoconutColors.warningText, fontFamily: 'Pretendard', fontSize: 12),
            )),
    ]);
  }

  Stack buildTextField() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Text(
            widget.controller.text.isNotEmpty ? '' : widget.placeholder,
            style: widget.placeholderStyle ??
                CoconutTypography.body2_14.setColor(
                  CoconutColors.black.withOpacity(0.3),
                ),
          ),
        ),
        FocusScope(
          child: Focus(
            onFocusChange: (focus) {
              setState(() {
                isFocused = focus;
              });
              print('---> focus && widget.onFocused: $focus ${widget.onFocused != null}');
              if (focus && widget.onFocused != null) {
                widget.onFocused!();
              }
            },
            child: Container(
                padding: EdgeInsets.only(
                    right: widget.clearButtonMode != OverlayVisibilityMode.never ? 4 : 0),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: widget.valid != false
                          ? (isFocused
                              ? widget.focusedBorderColor
                              : CoconutColors.black.withOpacity(0.06))
                          : CoconutColors.warningText),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: CupertinoTextField(
                      controller: widget.controller,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      textAlignVertical: TextAlignVertical.top,
                      padding: widget.padding,
                      style: widget.style,
                      onChanged: widget.onChanged,
                      maxLines: widget.maxLines,
                      minLines: widget.minLines,
                      obscureText: widget.obscureText,
                      suffix: widget.suffix,
                      clearButtonMode: widget.clearButtonMode,
                      focusNode: widget.focusNode,
                      maxLength: widget.maxLength,
                      inputFormatters: widget.inputFormatters ?? const [],
                      // keyboardType: widget.keyboardType,
                      // textCapitalization: widget.textCapitalization,
                    )),
                  ],
                )),
          ),
        ),
      ],
    );
  }
}
