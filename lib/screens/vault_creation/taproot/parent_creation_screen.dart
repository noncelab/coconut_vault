import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:flutter/material.dart';

class ParentCreationScreen extends StatefulWidget {
  const ParentCreationScreen({super.key});

  @override
  State<ParentCreationScreen> createState() => _ParentCreationScreenState();
}

class _ParentCreationScreenState extends State<ParentCreationScreen> {
  static const int _totalStep = 3;
  int _currentStep = 1;

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
    [const TextSpan(text: '이건 첫번째 타이틀'), TextSpan(text: '($_currentStep / $_totalStep)')],
    [
      const TextSpan(text: '이건 두번째 타이틀'),
      const TextSpan(text: '두번째 타이틀의 두번째 줄'),
      TextSpan(text: '($_currentStep / $_totalStep)'),
    ],
    [const TextSpan(text: '이건 세번재 타이틀'), TextSpan(text: '($_currentStep / $_totalStep)')],
  ];

  List<Widget> get _childList => [
    TimelineStepIndicator(
      timelineStepItemList: [
        TimelineStepItem(
          title: t.taproot.parent_creation_screen.created_parent_wallet,
          description: t.taproot.parent_creation_screen.singlesig_wallet_with_mfp(mfp: 000000),
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: t.taproot.parent_creation_screen.set_child_wallet,
          description: t.taproot.parent_creation_screen.taproot_wallet_with_mfp(mfp: 000000),
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: t.taproot.parent_creation_screen.set_child_period,
          description: '2030년 2월 16일 오전 09:21',
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: t.taproot.parent_creation_screen.avtive_child_wallet,
          description: '2030년 2월 16일 오전 09:21 이후',
          status: TimelineStepStatus.future,
        ),
      ],
    ),
    Container(),
    Container(),
  ];

  void _onNextPressed() {
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
        title: t.taproot.parent_creation_screen.title,
        context: context,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            TaprootCreationBody(
              titleLines: _titleLines(),
              onBottomButtonPressed: _onNextPressed,
              child: Container(child: _childList[_currentStep - 1]),
            ),
            TopProgressBar(visible: true, total: _totalStep, current: _currentStep),
          ],
        ),
      ),
    );
  }
}
