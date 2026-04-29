import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:flutter/material.dart';

class ParentCreationScreen extends StatefulWidget {
  const ParentCreationScreen({super.key});

  @override
  State<ParentCreationScreen> createState() => _ParentCreationScreenState();
}

class _ParentCreationScreenState extends State<ParentCreationScreen> {
  static const int _totalStep = 100;
  int _currentStep = 1;

  List<TextSpan> get _titleLines => [
    const TextSpan(text: '테스트용 타이틀'),
    TextSpan(text: '입니다. ($_currentStep / $_totalStep)'),
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
            TaprootCreationBody(onBottomButtonPressed: _onNextPressed, titleLines: _titleLines),
            TopProgressBar(visible: true, total: _totalStep, current: _currentStep),
          ],
        ),
      ),
    );
  }
}
