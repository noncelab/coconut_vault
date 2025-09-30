import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
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
  late bool _isWarningVisible;
  late Uint8List _mnemonic;

  @override
  void initState() {
    super.initState();
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);
    _mnemonic = Uint8List.fromList(_walletCreationProvider.secret);
    step = 0;
    _isWarningVisible = true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  NextButtonState _getNextButtonState() {
    if (_walletCreationProvider.passphrase?.isEmpty ?? true) {
      // 패스프레이즈 사용 안함 - 항상 '완료' 버튼
      if (_isWarningVisible) {
        return NextButtonState.completeInactive;
      }
      return NextButtonState.completeActive;
    }
    if (step == 0) {
      if (_isWarningVisible) {
        return NextButtonState.nextInactive;
      }
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
          appBar: CoconutAppBar.build(title: t.mnemonic_confirm_screen.title, context: context),
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
                          padding: const EdgeInsets.only(top: 18, bottom: 25),
                          child: Text(
                            t.mnemonic_confirm_screen.description,
                            textAlign: TextAlign.center,
                            style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.black),
                          ),
                        ),
                        step == 0
                            ? MnemonicList(
                              mnemonic: _mnemonic,
                              onWarningPressed: () {
                                setState(() {
                                  _isWarningVisible = false;
                                });
                              },
                              showWarningWidget: false,
                            )
                            : _passphraseGridViewWidget(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
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
                    Navigator.pushReplacementNamed(context, AppRoutes.vaultNameSetup);
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
    return EntropyStepIndicator(
      usePassphrase: _walletCreationProvider.passphrase?.isNotEmpty ?? false,
      step: step,
      onStepSelected: (selectedStep) {
        setState(() {
          step = selectedStep;
        });
      },
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
              border: Border.all(width: 1, color: CoconutColors.black),
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
                      style: const TextStyle(color: CoconutColors.borderGray, fontWeight: FontWeight.bold, fontSize: 6),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Text(
                      utf8.decode(passphrase)[index],
                      style: const TextStyle(color: CoconutColors.black, fontWeight: FontWeight.bold),
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

enum NextButtonState {
  completeActive, // '완료' + 활성화
  completeInactive, // '완료' + 비활성화
  nextActive, // '다음' + 활성화
  nextInactive, // '다음' + 비활성화
}

extension NextButtonStateExtension on NextButtonState {
  String get text {
    switch (this) {
      case NextButtonState.completeActive:
      case NextButtonState.completeInactive:
        return t.complete;
      case NextButtonState.nextActive:
      case NextButtonState.nextInactive:
        return t.next;
    }
  }

  bool get isActive {
    switch (this) {
      case NextButtonState.completeActive:
      case NextButtonState.nextActive:
        return true;
      case NextButtonState.completeInactive:
      case NextButtonState.nextInactive:
        return false;
    }
  }
}
