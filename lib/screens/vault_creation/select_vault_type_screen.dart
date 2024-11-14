import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';

class SelectVaultTypeScreen extends StatefulWidget {
  const SelectVaultTypeScreen({super.key});

  @override
  State<SelectVaultTypeScreen> createState() => _SelectVaultTypeScreenState();
}

class _SelectVaultTypeScreenState extends State<SelectVaultTypeScreen> {
  late var nextPath;
  late var guideText;
  late var isSingleSigClicked;
  late var isMultiSigClicked;
  @override
  void initState() {
    super.initState();
    nextPath = '';
    guideText = '';
    isSingleSigClicked = false;
    isMultiSigClicked = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.buildWithNext(
          title: '지갑 만들기',
          context: context,
          onNextPressed: () {
            Navigator.pushNamed(context, nextPath);
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
                    text: '일반 지갑',
                    onTap: () {
                      setState(() {
                        nextPath = '/vault-creation-options';
                        guideText = '하나의 니모닉 문구를 보관하는 단일 서명 지갑이에요';
                        isSingleSigClicked = true;
                        isMultiSigClicked = false;
                      });
                    },
                    isPressed: isSingleSigClicked,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableButton(
                    text: '다중 서명 지갑',
                    onTap: () {
                      setState(() {
                        nextPath = '/select-key-options';
                        guideText = '지정한 수의 서명이 필요한 지갑이에요';
                        isMultiSigClicked = true;
                        isSingleSigClicked = false;
                      });
                    },
                    isPressed: isMultiSigClicked,
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
