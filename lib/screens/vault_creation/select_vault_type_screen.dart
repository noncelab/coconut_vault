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
  String? nextPath;
  late String guideText;
  List<String> options = ['/vault-creation-options', '/select-multisig-quoram'];

  @override
  void initState() {
    super.initState();
    guideText = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.buildWithNext(
          title: '지갑 만들기',
          context: context,
          onNextPressed: () {
            Navigator.pushNamed(context, nextPath!);
          },
          isActive: nextPath != null && nextPath!.isNotEmpty),
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
                        nextPath = options[0];
                        guideText = '하나의 니모닉 문구를 보관하는 단일 서명 지갑이에요';
                      });
                    },
                    isPressed: nextPath == options[0],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableButton(
                    text: '다중 서명 지갑',
                    onTap: () {
                      setState(() {
                        nextPath = options[1];
                        guideText = '지정한 수의 서명이 필요한 지갑이에요';
                      });
                    },
                    isPressed: nextPath == options[1],
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
