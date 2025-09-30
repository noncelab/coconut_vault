import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

enum EntropyType { auto, manual }

abstract class BaseMnemonicEntropyScreen extends StatefulWidget {
  const BaseMnemonicEntropyScreen({super.key, required this.entropyType});
  final EntropyType entropyType;
}

abstract class BaseMnemonicEntropyScreenState<T extends BaseMnemonicEntropyScreen> extends State<T> {
  late final int _totalStep;
  int _step = 0;

  // protected variables
  int selectedWordsCount = 0;
  bool usePassphrase = false;
  bool finished = false;
  final ValueNotifier<bool> regenerateNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> stepNotifier = ValueNotifier<int>(0);
  bool showRegenerateButton = true;

  // 추상 메서드 (각 구현체에서 정의)
  String get screenTitle;
  // notifier is used to regenerate the mnemonic
  Widget buildEntropyWidget([ValueNotifier<bool>? notifier, ValueNotifier<int>? stepNotifier]);

  @override
  void initState() {
    super.initState();
    _totalStep = Provider.of<VisibilityProvider>(context, listen: false).isPassphraseUseEnabled ? 2 : 1;
    stepNotifier.addListener(_onStepChanged);
  }

  void _onStepChanged() {
    // 니모닉 입력 단계 또는 패스프레이즈 입력 단계
    final currentStep = stepNotifier.value;

    if (currentStep == 1) {
      // 패스프레이즈 입력 단계
      setState(() {
        showRegenerateButton = false;
      });
    } else if (currentStep == 0) {
      // 니모닉 입력 단계
      setState(() {
        showRegenerateButton = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WordsLengthSelection(onSelected: _onLengthSelected),
      PassphraseSelection(onSelected: _onPassphraseSelected),
      buildEntropyWidget(regenerateNotifier, stepNotifier),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showStopGeneratingMnemonicDialog();
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(
            title: screenTitle,
            context: context,
            backgroundColor: CoconutColors.white,
            actionButtonList: [
              if (widget.entropyType == EntropyType.auto && _step == 2 && showRegenerateButton)
                IconButton(
                  onPressed: _onRegenerate,
                  icon: SvgPicture.asset('assets/svg/refresh.svg', width: 18, height: 18),
                ),
            ],
          ),
          body: SafeArea(child: screens[_step]),
        ),
      ),
    );
  }

  void _onRegenerate() {
    regenerateNotifier.value = true;
  }

  void _onLengthSelected(int wordsCount) {
    setState(() {
      selectedWordsCount = wordsCount;
      _step = _totalStep == 2 ? 1 : 2;
    });
  }

  void _onPassphraseSelected(bool selected) {
    setState(() {
      usePassphrase = selected;
      _step = 2;
    });
  }

  void onReset() {
    setState(() {
      _step = 0;
      selectedWordsCount = 0;
      usePassphrase = false;
      finished = false;
    });
  }

  void _showStopGeneratingMnemonicDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.stop_generating_mnemonic.title,
          description: t.alert.stop_generating_mnemonic.description,
          backgroundColor: CoconutColors.white,
          rightButtonText: t.alert.stop_generating_mnemonic.confirm,
          rightButtonColor: CoconutColors.gray900,
          leftButtonText: t.alert.stop_generating_mnemonic.reselect,
          leftButtonColor: CoconutColors.gray900,
          onTapLeft: () {
            Navigator.pop(context);
            onReset();
          },
          onTapRight: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
