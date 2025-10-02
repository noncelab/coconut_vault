import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MultisigSignerMemoBottomSheet extends StatefulWidget {
  final String? memo;
  final Function(String) onUpdate;
  final bool? autofocus;

  const MultisigSignerMemoBottomSheet({super.key, required this.onUpdate, required this.memo, this.autofocus = false});

  @override
  State<MultisigSignerMemoBottomSheet> createState() => _MultisigSignerMemoBottomSheetState();
}

class _MultisigSignerMemoBottomSheetState extends State<MultisigSignerMemoBottomSheet> {
  late String _memo;
  bool hasChanged = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.memo ?? '';
    _memo = widget.memo ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        decoration: const BoxDecoration(
          color: CoconutColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 컨텐츠 크기에 맞추기
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(t.multi_sig_memo_bottom_sheet.imported_wallet_memo, style: CoconutTypography.heading4_18),
                ),

                const SizedBox(height: 16),

                // TextField
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: CoconutColors.black.withValues(alpha: 0.06)),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: CupertinoTextField(
                    autofocus: widget.autofocus ?? false,
                    controller: _controller,
                    placeholder: t.multi_sig_memo_bottom_sheet.placeholder,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    style: CoconutTypography.body1_16,
                    placeholderStyle: CoconutTypography.body2_14.setColor(CoconutColors.black.withValues(alpha: 0.3)),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    maxLength: 15,
                    clearButtonMode: OverlayVisibilityMode.always,
                    onChanged: (text) {
                      setState(() {
                        _memo = text;
                      });
                    },
                  ),
                ),

                // 글자 수 표시
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Text(
                      '(${_memo.length} / 15)',
                      style: CoconutTypography.body3_12.setColor(
                        _memo.length == 15
                            ? CoconutColors.black.withValues(alpha: 0.7)
                            : CoconutColors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 취소/완료 버튼
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: CoconutColors.gray150,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Text(
                              '닫기',
                              style: TextStyle(color: CoconutColors.black, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 완료 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          widget.onUpdate(_memo);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: CoconutColors.black, borderRadius: BorderRadius.circular(5)),
                          child: Center(
                            child: Text(
                              t.complete,
                              style: TextStyle(
                                color: CoconutColors.white,
                                fontSize: 14,
                                fontWeight: _memo.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
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
