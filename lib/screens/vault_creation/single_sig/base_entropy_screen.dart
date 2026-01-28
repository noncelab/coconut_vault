import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:flutter/material.dart';
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

  // 추상 메서드 (각 구현체에서 정의)
  String get screenTitle;
  Widget buildEntropyWidget();

  @override
  void initState() {
    super.initState();
    _totalStep = Provider.of<VisibilityProvider>(context, listen: false).isPassphraseUseEnabled ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WordsLengthSelection(onSelected: _onLengthSelected),
      PassphraseSelection(onSelected: _onPassphraseSelected),
      buildEntropyWidget(),
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
          appBar: CoconutAppBar.build(title: screenTitle, context: context, backgroundColor: CoconutColors.white),
          body: SafeArea(child: screens[_step]),
        ),
      ),
    );
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
          languageCode: context.read<VisibilityProvider>().language,
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
