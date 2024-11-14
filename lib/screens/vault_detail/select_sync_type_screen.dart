import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';

class SelectSyncTypeScreen extends StatefulWidget {
  final String id;

  const SelectSyncTypeScreen({super.key, required this.id});

  @override
  State<SelectSyncTypeScreen> createState() => _SelectSyncTypeScreenState();
}

class _SelectSyncTypeScreenState extends State<SelectSyncTypeScreen> {
  late var nextPath;
  late var guideText;
  late var isSyncToWalletClicked;
  late var isSyncToMultiSigWalletClicked;
  @override
  void initState() {
    super.initState();
    nextPath = '/sync-to-wallet';
    guideText = '어떤 용도로 사용하시나요?';
    isSyncToWalletClicked = false;
    isSyncToMultiSigWalletClicked = false;
    debugPrint('id:: ${widget.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.buildWithNext(
          title: '내보내기',
          context: context,
          onNextPressed: () {
            Navigator.pushReplacementNamed(context, nextPath, arguments: {
              'id': widget.id,
              'isMultiSignatureSync': isSyncToMultiSigWalletClicked
            });
          },
          isActive: nextPath != ''),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: [
            Text(guideText),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SelectableButton(
                    text: '월렛에\n보기 전용 지갑 추가',
                    onTap: () {
                      setState(() {
                        isSyncToWalletClicked = true;
                        isSyncToMultiSigWalletClicked = false;
                      });
                    },
                    isPressed: isSyncToWalletClicked,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableButton(
                    text: '다른 볼트에서\n다중 서명 키로 사용',
                    onTap: () {
                      setState(() {
                        isSyncToWalletClicked = false;
                        isSyncToMultiSigWalletClicked = true;
                      });
                    },
                    isPressed: isSyncToMultiSigWalletClicked,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
