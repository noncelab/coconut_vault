import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';

class MultiSigMemoBottomSheet extends StatefulWidget {
  final String? memo;
  final Function(String) onUpdate;

  const MultiSigMemoBottomSheet({
    super.key,
    required this.onUpdate,
    required this.memo,
  });

  @override
  State<MultiSigMemoBottomSheet> createState() =>
      _MultiSigMemoBottomSheetState();
}

class _MultiSigMemoBottomSheetState extends State<MultiSigMemoBottomSheet> {
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
          color: Colors.white,
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
                  child: Text(
                    '외부 지갑 메모',
                    style: Styles.body1.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // TextField
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: MyColors.transparentBlack_06),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: CupertinoTextField(
                    controller: _controller,
                    placeholder: '메모를 작성해주세요.',
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    style: Styles.body1,
                    placeholderStyle: Styles.body2Grey,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
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
                      style: TextStyle(
                        color: _memo.length == 15
                            ? MyColors.transparentBlack
                            : MyColors.transparentBlack_50,
                        fontSize: 12,
                        fontFamily: CustomFonts.text.getFontFamily,
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
                            color: MyColors.lightgrey,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Text(
                              '닫기',
                              style: TextStyle(
                                color: MyColors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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
                          decoration: BoxDecoration(
                            color: MyColors.black,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Text(
                              '완료',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: _memo.isNotEmpty
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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

  const MemoTextField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: MyColors.transparentBlack_06,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: '메모를 작성해주세요.',
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        style: Styles.body1,
        placeholderStyle: Styles.body2Grey,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        maxLength: 100,
        clearButtonMode: OverlayVisibilityMode.always,
        onChanged: onChanged,
      ),
    );
  }
}
