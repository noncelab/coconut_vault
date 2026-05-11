import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/parent_creation_view_model.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParentCreationScreen extends StatefulWidget {
  const ParentCreationScreen({super.key});

  @override
  State<ParentCreationScreen> createState() => _ParentCreationScreenState();
}

class _ParentCreationScreenState extends State<ParentCreationScreen> {
  static const int _progressTotalStep = 6;

  final ParentCreationViewModel _viewModel = ParentCreationViewModel();
  late final List<List<TextSpan>> _titleList;
  late final List<Widget> _bodyList;
  late final List<VoidCallback?> _nextButtonActions;
  int _currentStep = 1;

  bool get _hasNextBuiltStep => _currentStep < _titleList.length;

  @override
  void initState() {
    super.initState();
    _titleList = _initialTitleList();
    _bodyList = _initialBodyList();
    _nextButtonActions = [_moveToNextStep, _confirmWalletType];
    _viewModel.addListener(_handleViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    setState(() {});
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

  List<List<TextSpan>> _initialTitleList() {
    return [
      [
        // Step 0: 사용하려는 지갑에 상속 조건을 함께 준비할게요
        TextSpan(text: t.taproot.parent_creation_screen.creation_intro_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.creation_intro_title_2),
      ],
      [
        // Step 1: 부모 지갑은 몇 개의 키를 사용할까요?
        TextSpan(text: t.taproot.parent_creation_screen.step_1.title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.title_2),
      ],
    ];
  }

  List<Widget> _initialBodyList() {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 64, top: 36, right: 64),
        child: Image.asset('assets/png/hand-bitcoin.png'),
      ),
      Consumer<ParentCreationViewModel>(
        builder: (context, viewModel, child) {
          return MenuGrid(
            children: [
              SelectableOptionCard(
                title: t.taproot.parent_creation_screen.step_1.single_sig_wallet,
                description: t.taproot.parent_creation_screen.step_1.wallet_usable_with_single_key,
                bottomAssetPath: 'assets/png/single-key.png',
                isSelected: viewModel.isSingleSigSelected,
                onTap: () => viewModel.toggleWalletType(ParentWalletType.singleSig),
                imageScale: 3.8,
                height: 195,
              ),
              SelectableOptionCard(
                title: t.taproot.parent_creation_screen.step_1.multisig_wallet,
                description: t.taproot.parent_creation_screen.step_1.wallet_usable_after_signed_all,
                bottomAssetPath: 'assets/png/multi-keys.png',
                isSelected: viewModel.isMultisigSelected,
                onTap: () => viewModel.toggleWalletType(ParentWalletType.multisig),
                imageScale: 3.8,
                height: 195,
              ),
            ],
          );
        },
      ),
    ];
  }

  VoidCallback? get _onNextPressed {
    final actionIndex = _currentStep - 1;
    if (actionIndex < 0 || actionIndex >= _nextButtonActions.length) {
      return null;
    }
    if (!_canRunCurrentStepAction) {
      return null;
    }

    return _nextButtonActions[actionIndex];
  }

  bool get _canRunCurrentStepAction {
    return switch (_currentStep) {
      1 => true,
      2 => _viewModel.selectedWalletType != null,
      _ => true,
    };
  }

  void _moveToNextStep() {
    debugPrint(
      'Current Step: $_currentStep, Built Step: ${_titleList.length}, Progress Total Step: $_progressTotalStep',
    );
    if (!_hasNextBuiltStep) {
      return;
    }

    setState(() {
      _currentStep += 1;
    });
  }

  void _confirmWalletType() {
    switch (_viewModel.selectedWalletType) {
      case ParentWalletType.singleSig:
        _startSingleSigParentCreation();
        return;
      case ParentWalletType.multisig:
        _startMultisigParentCreation();
        return;
      case null:
        return;
    }
  }

  void _startSingleSigParentCreation() {
    setState(() {
      _titleList.add([
        TextSpan(text: t.taproot.parent_creation_screen.step_2.creation_script_path_intro_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_2.creation_script_path_intro_title_2),
      ]);
      _bodyList.add(const SizedBox.shrink());
      _nextButtonActions.add(_onSingleSigGuideConfirmed);
      _currentStep += 1;
    });
  }

  void _startMultisigParentCreation() {
    setState(() {
      _titleList.add([
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_title_2),
      ]);
      _bodyList.add(
        Column(
          children: [
            t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_description_1
                .characterFadeInAnimation(
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 1700),
                  textStyle: CoconutTypography.body1_16,
                ),
            t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_description_2
                .characterFadeInAnimation(
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 2400),
                  textStyle: CoconutTypography.body1_16,
                ),
            CoconutLayout.spacing_900h,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Image.asset('assets/png/hanging-phone.png'),
            ),
          ],
        ),
      );
      _nextButtonActions.add(_onMultisigGuideConfirmed);
      _currentStep += 1;
    });
  }

  void _onSingleSigGuideConfirmed() {
    // TODO: 다음 single-sig parent creation step 연결
  }

  void _onMultisigGuideConfirmed() {
    // TODO: 다음 multisig parent creation step 연결
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
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
                child: _bodyList[_currentStep - 1],
              ),
              TopProgressBar(visible: true, total: _progressTotalStep, current: _currentStep),
            ],
          ),
        ),
      ),
    );
  }
}
