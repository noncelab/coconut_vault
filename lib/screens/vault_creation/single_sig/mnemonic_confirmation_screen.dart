import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MnemonicConfirmationScreen extends StatefulWidget {
  const MnemonicConfirmationScreen({super.key});

  @override
  State<MnemonicConfirmationScreen> createState() => _MnemonicConfirmationScreenState();
}

class _MnemonicConfirmationScreenState extends State<MnemonicConfirmationScreen> {
  late WalletCreationProvider _walletCreationProvider;
  late int step;
  final ScrollController _scrollController = ScrollController();
  // TODO: Uint8List 타입으로 바꿀 예정
  late String _mnemonic;

  @override
  void initState() {
    super.initState();
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);
    _mnemonic = _walletCreationProvider.secret!;
    step = 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  NextButtonState _getNextButtonState() {
    if (_walletCreationProvider.passphrase?.isEmpty ?? true) {
      // 패스프레이즈 사용 안함 - 항상 '완료' 버튼
      return NextButtonState.completeActive;
    }
    if (step == 0) {
      return NextButtonState.nextActive;
    }
    return NextButtonState.completeActive;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: CoconutAppBar.build(
            title: t.mnemonic_confirm_screen.title,
            context: context,
          ),
          backgroundColor: CoconutColors.white,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      color: CoconutColors.white,
                      child: Column(
                        children: [
                          buildStepIndicator(),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 18,
                              bottom: 25,
                            ),
                            child: Text(
                              t.mnemonic_confirm_screen.description,
                              style: CoconutTypography.body1_16_Bold.setColor(
                                CoconutColors.black,
                              ),
                            ),
                          ),
                          step == 0
                              ? MnemonicList(mnemonic: utf8.encode(_mnemonic))
                              : _passphraseGridViewWidget(),
                          const SizedBox(height: 100),
                        ],
                      )),
                ),
                FixedBottomButton(
                  isActive: _getNextButtonState().isActive,
                  text: _getNextButtonState().text,
                  backgroundColor: CoconutColors.black,
                  onButtonClicked: () {
                    if (step == 0 && (_walletCreationProvider.passphrase?.isNotEmpty ?? false)) {
                      setState(() {
                        // 패스프레이즈 확인 단계로 이동
                        step = 1;
                      });
                      return;
                    }
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const VaultNameAndIconSetupScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStepIndicator() {
    return Visibility(
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      visible: _walletCreationProvider.passphrase?.isNotEmpty ?? false,
      child: Container(
        padding: const EdgeInsets.only(
          top: 10,
        ),
        child: Stack(
          children: [
            const SizedBox(
              height: 50,
              width: 120,
              child: Center(
                child: DottedDivider(
                  height: 2.0,
                  width: 100,
                  dashWidth: 2.0,
                  dashSpace: 4.0,
                  color: CoconutColors.gray400,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: NumberWidget(
                  number: 1,
                  selected: step == 0,
                  onSelected: () {
                    setState(() {
                      step = 0;
                    });
                  }),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: NumberWidget(
                  number: 2,
                  selected: step == 1,
                  onSelected: () {
                    setState(() {
                      step = 1;
                    });
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passphraseGridViewWidget() {
    final passphrase = _walletCreationProvider.passphrase;
    if (passphrase == null) return Container();
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 10,
      crossAxisSpacing: 3.0,
      mainAxisSpacing: 10.0,
      shrinkWrap: true,
      children: List.generate((passphrase.length + 20), (index) {
        // 가장 아래에 빈 공간을 배치하기 위한 조건문
        if (index < passphrase.length) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CoconutColors.white,
              border: Border.all(
                width: 1,
                color: CoconutColors.black,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Visibility(
                  visible: index % 10 == 0,
                  child: Positioned(
                    top: 3,
                    left: 3,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: CoconutColors.borderGray,
                          fontWeight: FontWeight.bold,
                          fontSize: 6),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Text(
                      passphrase[index],
                      style: const TextStyle(
                        color: CoconutColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // 빈 공간을 추가하기 위해 빈 컨테이너를 반환
          return Container();
        }
      }),
    );
  }
}
