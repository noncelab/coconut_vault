import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/taproot_import_view_model.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_scanner_screen.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/widgets/text/character_fade_in_text.dart';
import 'package:flutter/material.dart';

class TaprootImportScreen extends StatefulWidget {
  const TaprootImportScreen({super.key});

  @override
  State<TaprootImportScreen> createState() => _TaprootImportScreenState();
}

class _TaprootImportScreenState extends State<TaprootImportScreen> {
  static const int _initialStepCount = 1;
  static const int _progressTotalStep = 6;

  late final List<List<TextSpan>> _titleList;
  late final List<List<Widget>> _bodyList;
  late final List<VoidCallback?> _nextButtonActions;
  late final List<bool> _ignoreBodyHorizontalPaddingList;
  late final List<bool> _pauseProgressList;
  late final List<bool> _scrollChildList;
  final TaprootImportViewModel _viewModel = TaprootImportViewModel();
  int _currentStep = 1;

  bool get _isProgressPaused => _pauseProgressList[_currentStep - 1];
  bool get _showHeader => !_isProgressPaused;
  int get _progressCurrentStep => _pauseProgressList.take(_currentStep).where((isPaused) => !isPaused).length;

  VoidCallback? get _onNextPressed {
    final actionIndex = _currentStep - 1;
    if (actionIndex < 0 || actionIndex >= _nextButtonActions.length) {
      return null;
    }
    return _nextButtonActions[actionIndex];
  }

  @override
  void initState() {
    super.initState();
    _titleList = _initialTitleList();
    _bodyList = _initialBodyList();
    _nextButtonActions = [_addScannerStep];
    _ignoreBodyHorizontalPaddingList = [false];
    _pauseProgressList = [false];
    _scrollChildList = [true];
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  List<List<TextSpan>> _initialTitleList() {
    return [
      [
        TextSpan(text: t.taproot.taproot_import_screen.step1.title1),
        TextSpan(text: t.taproot.taproot_import_screen.step1.title2),
      ],
    ];
  }

  List<List<Widget>> _initialBodyList() {
    return [
      [
        Padding(
          padding: const EdgeInsets.only(left: 64, top: 36, right: 64),
          child: Image.asset('assets/png/hand-bitcoin.png'),
        ),
      ],
    ];
  }

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

  int _addStep({
    required List<TextSpan> titleList,
    required List<Widget> bodyList,
    required VoidCallback? nextButtonAction,
    bool ignoreBodyHorizontalPadding = false,
    bool pauseProgress = false,
    bool scrollChild = true,
  }) {
    final addedStep = _titleList.length + 1;
    setState(() {
      _titleList.add(titleList);
      _bodyList.add(bodyList);
      _nextButtonActions.add(nextButtonAction);
      _ignoreBodyHorizontalPaddingList.add(ignoreBodyHorizontalPadding);
      _pauseProgressList.add(pauseProgress);
      _scrollChildList.add(scrollChild);
      _currentStep += 1;
    });
    return addedStep;
  }

  int _addEmbeddedStep(Widget embeddedScreen) {
    return _addStep(
      titleList: const [],
      bodyList: [embeddedScreen],
      nextButtonAction: null,
      ignoreBodyHorizontalPadding: true,
      pauseProgress: true,
      scrollChild: false,
    );
  }

  void _addScannerStep() {
    final guideText = Text(
      t.taproot.taproot_import_screen.step2.title1,
      style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.white),
      textAlign: TextAlign.center,
    );

    _addEmbeddedStep(
      TaprootScannerScreen(
        hasAppbar: false,
        dataType: TaprootScannerDataType.walletSync,
        topGuideWidget: Positioned(top: 80, left: 24, right: 24, child: guideText),
        onWalletSyncScanned: (walletSyncData) {
          _viewModel.setWalletSyncData(walletSyncData);
          _addImportedWalletStep();
          return true;
        },
      ),
    );
  }

  void _addImportedWalletStep() {
    _addStep(
      titleList: [TextSpan(text: t.taproot.taproot_import_screen.step3.title1)],
      bodyList: [_buildScannedWalletSyncDataText()],
      nextButtonAction: _addParentConfigurationStep,
    );
  }

  Widget _buildScannedWalletSyncDataText() {
    final walletSyncData = _viewModel.walletSyncData;
    debugPrint('walletSyncData : ${_viewModel.walletSyncData}');
    if (walletSyncData == null) {
      return const SizedBox.shrink();
    }

    final buffer =
        StringBuffer()
          ..writeln('name: ${walletSyncData.name}')
          ..writeln('colorIndex: ${walletSyncData.colorIndex}')
          ..writeln('iconIndex: ${walletSyncData.iconIndex}')
          ..writeln()
          ..writeln('descriptor:')
          ..writeln(walletSyncData.descriptor)
          ..writeln()
          ..writeln('keyPathSeedInfos:');

    for (final extendedPublicKey in walletSyncData.keyPathExtendedPublicKeys) {
      buffer.writeln('- $extendedPublicKey');
    }

    buffer.writeln();
    buffer.writeln('scriptPathSeedInfos:');
    for (int index = 0; index < walletSyncData.scriptPathSeedInfos.length; index++) {
      final scriptPath = walletSyncData.scriptPathSeedInfos[index];
      buffer
        ..writeln('- [$index] miniscript:')
        ..writeln(scriptPath.miniscript)
        ..writeln('  extendedPublicKeys:');
      for (final extendedPublicKey in scriptPath.extendedPublicKeys) {
        buffer.writeln('  - $extendedPublicKey');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CoconutColors.gray100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CoconutColors.gray300),
        ),
        child: SelectableText(
          buffer.toString(),
          style: CoconutTypography.body3_12.copyWith(color: CoconutColors.gray800, height: 1.4),
        ),
      ),
    );
  }

  void _addParentConfigurationStep() {
    _addStep(
      titleList: [
        TextSpan(text: t.taproot.taproot_import_screen.step4.title1),
        TextSpan(text: t.taproot.taproot_import_screen.step4.title2),
      ],
      bodyList: [
        CharacterFadeInText(
          text: t.taproot.taproot_import_screen.step4.description,
          animationKey: 'taproot-import-body-role-description',
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 1700),
        ),
      ],
      nextButtonAction: null,
    );
  }

  void _handleBackPressed() {
    if (_currentStep <= 1) {
      Navigator.maybePop(context);
      return;
    }

    setState(() {
      if (_currentStep <= _initialStepCount) {
        _currentStep -= 1;
        return;
      }

      final currentStepIndex = _currentStep - 1;
      _titleList.removeAt(currentStepIndex);
      _bodyList.removeAt(currentStepIndex);
      _nextButtonActions.removeAt(currentStepIndex);
      _ignoreBodyHorizontalPaddingList.removeAt(currentStepIndex);
      _pauseProgressList.removeAt(currentStepIndex);
      _scrollChildList.removeAt(currentStepIndex);
      _currentStep -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: t.taproot.taproot_creation_option.prepared_creation_title,
          context: context,
          backgroundColor: CoconutColors.white,
          onBackPressed: _handleBackPressed,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              TaprootCreationBody(
                titleLines: _titleLines(),
                onBottomButtonPressed: _onNextPressed,
                bottomButtonText: _progressCurrentStep >= _progressTotalStep ? t.complete : null,
                showBottomButton: _onNextPressed != null,
                ignoreChildHorizontalPadding: _ignoreBodyHorizontalPaddingList[_currentStep - 1],
                showHeader: _showHeader,
                scrollChild: !_isProgressPaused && _scrollChildList[_currentStep - 1],
                child:
                    _isProgressPaused
                        ? _bodyList[_currentStep - 1].first
                        : Column(children: _bodyList[_currentStep - 1]),
              ),
              TopProgressBar(visible: !_isProgressPaused, total: _progressTotalStep, current: _progressCurrentStep),
            ],
          ),
        ),
      ),
    );
  }
}
