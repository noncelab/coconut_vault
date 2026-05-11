import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:flutter/material.dart';

class ChildCreationScreen extends StatefulWidget {
  const ChildCreationScreen({super.key});

  @override
  State<ChildCreationScreen> createState() => _ChildCreationScreenState();
}

class _ChildCreationScreenState extends State<ChildCreationScreen> {
  static const int _totalStep = 4;
  int _currentStep = 1;
  int _selectedChildMethodIndex = -1;
  int _selectedChildCreationIndex = -1;
  int _selectedExistingChildIndex = -1;

  List<TextSpan> _titleLines() {
    final textList = _titleList[_currentStep - 1];
    if (textList.length == 1) {
      return [const TextSpan(text: ''), textList[0], const TextSpan(text: '')];
    }
    if (textList.length == 2) {
      return [textList[0], textList[1], const TextSpan(text: '')];
    }
    return textList;
  }

  List<List<TextSpan>> get _titleList => [
    [
      TextSpan(text: t.taproot.child_creation_screen.step1.title1),
      TextSpan(text: t.taproot.child_creation_screen.step1.title2),
    ],
    [
      TextSpan(text: t.taproot.child_creation_screen.step2.title1),
      TextSpan(text: t.taproot.child_creation_screen.step2.title2),
    ],
    _selectedChildMethodIndex == 0
        ? [TextSpan(text: t.taproot.child_creation_screen.step3.title_new)]
        : [TextSpan(text: t.taproot.child_creation_screen.step3.title_existing)],
    [const TextSpan(text: '자식 지갑 타이틀'), TextSpan(text: '($_currentStep / $_totalStep)')],
  ];

  List<Widget> get _childList => [
    Center(child: Image.asset('assets/png/load-wallet.png', scale: 4.0, width: 210)),
    MenuGrid(
      children: [
        SelectableOptionCard(
          title: t.taproot.child_creation_screen.step2.option1_title,
          description: t.taproot.child_creation_screen.step2.option1_desc,
          bottomAssetPath: 'assets/png/wallet.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: _selectedChildMethodIndex == 0,
          height: 217,
          onTap: () {
            setState(() {
              _selectedChildMethodIndex = 0;
            });
          },
        ),
        SelectableOptionCard(
          title: t.taproot.child_creation_screen.step2.option2_title,
          description: t.taproot.child_creation_screen.step2.option2_desc,
          bottomAssetPath: 'assets/png/key-holder.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: _selectedChildMethodIndex == 1,
          height: 217,
          onTap: () {
            setState(() {
              _selectedChildMethodIndex = 1;
            });
          },
        ),
      ],
    ),
    _selectedChildMethodIndex == 0
        ? MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.new_option1,
              bottomAssetPath: 'assets/png/coin.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: _selectedChildCreationIndex == 0,
              height: 118,
              onTap: () {
                setState(() {
                  _selectedChildCreationIndex = 0;
                });
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.new_option2,
              bottomAssetPath: 'assets/png/dice.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: _selectedChildCreationIndex == 1,
              height: 118,
              onTap: () {
                setState(() {
                  _selectedChildCreationIndex = 1;
                });
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.new_option3,
              bottomAssetPath: 'assets/png/gear.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: _selectedChildCreationIndex == 2,
              height: 118,
              onTap: () {
                setState(() {
                  _selectedChildCreationIndex = 2;
                });
              },
            ),
          ],
        )
        : MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.existing_option1,
              bottomAssetPath: 'assets/png/finger-picking.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: _selectedExistingChildIndex == 0,
              height: 118,
              onTap: () {
                setState(() {
                  _selectedExistingChildIndex = 0;
                });
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.existing_option2,
              bottomAssetPath: 'assets/png/word.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: _selectedExistingChildIndex == 1,
              height: 118,
              onTap: () {
                setState(() {
                  _selectedExistingChildIndex = 1;
                });
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.existing_option3,
              bottomAssetPath: 'assets/png/scan-qr.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: _selectedExistingChildIndex == 2,
              height: 118,
              onTap: () {
                setState(() {
                  _selectedExistingChildIndex = 2;
                });
              },
            ),
          ],
        ),
    const TimelineStepIndicator(
      timelineStepItemList: [
        TimelineStepItem(
          title: '부모 지갑 연결',
          description: '단일 서명 지갑과 연결됨 (MFP: 000000)',
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: '자식 지갑 설정',
          description: '탭루트 자식 지갑 (MFP: 000000)',
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(title: '기간 설정', description: '2030년 2월 16일 오전 09:21', status: TimelineStepStatus.upcoming),
        TimelineStepItem(
          title: '자식 지갑 활성화',
          description: '2030년 2월 16일 오전 09:21 이후',
          status: TimelineStepStatus.future,
        ),
      ],
    ),
  ];

  bool get _isNextButtonVisible {
    if (_currentStep == 2) {
      return _selectedChildMethodIndex != -1;
    }
    if (_currentStep == 3) {
      if (_selectedChildMethodIndex == 0) {
        return _selectedChildCreationIndex != -1;
      } else {
        return _selectedExistingChildIndex != -1;
      }
    }
    return true;
  }

  void _onNextPressed() async {
    if (_currentStep == 3) {
      if (_selectedChildMethodIndex == 0) {
        if (_selectedChildCreationIndex == 0) {
          final passedCheck = await Navigator.pushNamed(
            context,
            AppRoutes.securitySelfCheck,
            arguments: () {
              Navigator.pop(context, true);
            },
          );
          if (passedCheck == true) {
            final result = await Navigator.pushNamed(
              context,
              AppRoutes.mnemonicCoinflip,
              arguments: {'isTaprootChild': true},
            );
            if (result == true) {
              setState(() {
                _currentStep += 1;
              });
            }
          }
          return;
        } else if (_selectedChildCreationIndex == 1) {
          final passedCheck = await Navigator.pushNamed(
            context,
            AppRoutes.securitySelfCheck,
            arguments: () {
              Navigator.pop(context, true);
            },
          );
          if (passedCheck == true) {
            final result = await Navigator.pushNamed(
              context,
              AppRoutes.mnemonicDiceRoll,
              arguments: {'isTaprootChild': true},
            );
            if (result == true) {
              setState(() {
                _currentStep += 1;
              });
            }
          }
          return;
        } else if (_selectedChildCreationIndex == 2) {
          Navigator.pushNamed(
            context,
            AppRoutes.securitySelfCheck,
            arguments: () {
              Navigator.pushReplacementNamed(context, AppRoutes.mnemonicAutoGen);
            },
          );
          return;
        }
      } else if (_selectedChildMethodIndex == 1) {
        if (_selectedExistingChildIndex == 1) {
          Navigator.pushNamed(context, AppRoutes.mnemonicImport);
          return;
        } else if (_selectedExistingChildIndex == 2) {
          Navigator.pushNamed(context, AppRoutes.seedQrImport);
          return;
        }
      }
    }

    if (_currentStep >= _totalStep) {
      return;
    }

    setState(() {
      _currentStep += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.taproot.child_creation_screen.title,
        context: context,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            TaprootCreationBody(
              titleLines: _titleLines(),
              showBottomButton: _isNextButtonVisible,
              onBottomButtonPressed: _onNextPressed,
              child: Container(child: _childList[_currentStep - 1]),
            ),
            TopProgressBar(visible: true, total: _totalStep - 1, current: _currentStep - 1),
          ],
        ),
      ),
    );
  }
}
