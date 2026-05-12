import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/parent_creation_view_model.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_dice_roll_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
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
  late final List<List<Widget>> _bodyList;
  late final List<VoidCallback?> _nextButtonActions;
  late final List<bool> _ignoreBodyHorizontalPaddingList;
  late final List<bool> _pauseProgressList;
  int _currentStep = 1;

  bool get _hasNextBuiltStep => _currentStep < _titleList.length;

  @override
  void initState() {
    super.initState();
    _titleList = _initialTitleList();
    _bodyList = _initialBodyList();
    _nextButtonActions = [_moveToNextStep, _confirmWalletType];
    _ignoreBodyHorizontalPaddingList = [false, false];
    _pauseProgressList = [false, false];
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
        // Step 1-1: 부모 지갑은 몇 개의 키를 사용할까요?
        TextSpan(text: t.taproot.parent_creation_screen.step_1.title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.title_2),
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
      [
        Consumer<ParentCreationViewModel>(
          builder: (context, viewModel, child) {
            return MenuGrid(
              children: [
                SelectableOptionCard(
                  title: t.taproot.parent_creation_screen.step_1.single_sig_wallet,
                  description: t.taproot.parent_creation_screen.step_1.wallet_usable_with_single_key,
                  bottomAssetPath: 'assets/png/single-key.png',
                  isSelected: viewModel.isSingleSigSelected,
                  onTap: () => viewModel.setWalletType(ParentWalletType.singleSig),
                  imageScale: 3.8,
                  height: 195,
                ),
                SelectableOptionCard(
                  title: t.taproot.parent_creation_screen.step_1.multisig_wallet,
                  description: t.taproot.parent_creation_screen.step_1.wallet_usable_after_signed_all,
                  bottomAssetPath: 'assets/png/multi-keys.png',
                  isSelected: viewModel.isMultisigSelected,
                  onTap: () => viewModel.setWalletType(ParentWalletType.multisig),
                  imageScale: 3.8,
                  height: 195,
                ),
              ],
            );
          },
        ),
      ],
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
      2 => _viewModel.selectedWalletType != ParentWalletType.none,
      3 =>
        _viewModel.selectedWalletType == ParentWalletType.singleSig
            ? _viewModel.selectedKeyPreparationType != ParentKeyPreparationType.none
            : true,
      4 =>
        _viewModel.selectedWalletType == ParentWalletType.multisig
            ? _viewModel.selectedKeyPreparationType != ParentKeyPreparationType.none
            : _hasSelectedKeyCreationOrImportOption,
      5 => _viewModel.selectedWalletType == ParentWalletType.multisig ? _hasSelectedKeyCreationOrImportOption : true,
      _ => true,
    };
  }

  bool get _hasSelectedKeyCreationOrImportOption {
    return switch (_viewModel.selectedKeyPreparationType) {
      ParentKeyPreparationType.create => _viewModel.selectedNewKeyCreationType != ParentNewKeyCreationType.none,
      ParentKeyPreparationType.import => _viewModel.selectedExistingKeyImportType != ParentExistingKeyImportType.none,
      ParentKeyPreparationType.none => false,
    };
  }

  bool get _isProgressPaused => _pauseProgressList[_currentStep - 1];

  int get _progressCurrentStep {
    return _pauseProgressList.take(_currentStep).where((isPaused) => !isPaused).length;
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
      case ParentWalletType.none:
        return;
    }
  }

  void _startSingleSigParentCreation() {
    _onWalletTypeGuideConfirmed();
  }

  void _startMultisigParentCreation() {
    final multisigStartWithAnotherVaultGuide = [
      t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_description_1.characterFadeInAnimation(
        duration: const Duration(milliseconds: 700),
        delay: const Duration(milliseconds: 1700),
        textStyle: CoconutTypography.body1_16,
      ),
      t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_description_2.characterFadeInAnimation(
        duration: const Duration(milliseconds: 700),
        delay: const Duration(milliseconds: 2400),
        textStyle: CoconutTypography.body1_16,
      ),
      CoconutLayout.spacing_900h,
      Padding(padding: const EdgeInsets.symmetric(horizontal: 64), child: Image.asset('assets/png/hanging-phone.png')),
    ];

    _addStep(
      titleList: [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_title_2),
      ],
      bodyList: multisigStartWithAnotherVaultGuide,
      nextButtonAction: _onWalletTypeGuideConfirmed,
    );
  }

  void _addStep({
    required List<TextSpan> titleList,
    required List<Widget> bodyList,
    required VoidCallback? nextButtonAction,
    bool ignoreBodyHorizontalPadding = false,
    bool pauseProgress = false,
  }) {
    setState(() {
      _titleList.add(titleList);
      _bodyList.add(bodyList);
      _nextButtonActions.add(nextButtonAction);
      _ignoreBodyHorizontalPaddingList.add(ignoreBodyHorizontalPadding);
      _pauseProgressList.add(pauseProgress);
      _currentStep += 1;
    });
  }

  void _onWalletTypeGuideConfirmed() {
    final titleLines = switch (_viewModel.selectedWalletType) {
      ParentWalletType.singleSig => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_how_to_prepare_key_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_how_to_prepare_key_title_2),
      ],
      ParentWalletType.multisig => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_how_to_prepare_key_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_how_to_prepare_key_title_2),
      ],
      ParentWalletType.none => [const TextSpan(text: '')],
    };

    final bodyList = [
      Consumer<ParentCreationViewModel>(
        builder: (context, viewModel, child) {
          return MenuGrid(
            children: [
              SelectableOptionCard(
                title: t.taproot.common.prepare_key_option1_title,
                description: t.taproot.common.prepare_key_option1_desc,
                bottomAssetPath: 'assets/png/wallet.png',
                isSelected: viewModel.isCreateKeySelected,
                onTap: () => viewModel.setKeyPreparationType(ParentKeyPreparationType.create),
                imageScale: 3.8,
                height: 217,
              ),
              SelectableOptionCard(
                title: t.taproot.common.prepare_key_option2_title,
                description: t.taproot.common.prepare_key_option2_desc,
                bottomAssetPath: 'assets/png/key-holder.png',
                isSelected: viewModel.isImportKeySelected,
                onTap: () => viewModel.setKeyPreparationType(ParentKeyPreparationType.import),
                imageScale: 3.8,
                height: 217,
              ),
            ],
          );
        },
      ),
    ];
    _addStep(
      titleList: titleLines,
      bodyList: bodyList,
      nextButtonAction: () {
        _onKeyPreparationTypeSelected();
      },
    );
  }

  void _onKeyPreparationTypeSelected() {
    if (_viewModel.selectedKeyPreparationType == ParentKeyPreparationType.none) {
      return;
    }

    final titleLines = switch (_viewModel.selectedKeyPreparationType) {
      ParentKeyPreparationType.create => [TextSpan(text: t.taproot.common.create_new_wallet_title)],
      ParentKeyPreparationType.import => [TextSpan(text: t.taproot.common.existing_mnemonic_title)],
      ParentKeyPreparationType.none => [const TextSpan(text: '')],
    };

    final bodyList = switch (_viewModel.selectedKeyPreparationType) {
      ParentKeyPreparationType.create => [
        Consumer<ParentCreationViewModel>(
          builder: (context, viewModel, child) {
            return MenuGrid(
              children: [
                SelectableOptionCard(
                  title: t.taproot.common.new_option1,
                  bottomAssetPath: 'assets/png/coin.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.isCoinFlipSelected,
                  height: 118,
                  onTap: () => viewModel.setNewKeyCreationType(ParentNewKeyCreationType.coinFlip),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.new_option2,
                  bottomAssetPath: 'assets/png/dice.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.isDiceRollSelected,
                  height: 118,
                  onTap: () => viewModel.setNewKeyCreationType(ParentNewKeyCreationType.diceRoll),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.new_option3,
                  bottomAssetPath: 'assets/png/gear.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.isAutoGenerateSelected,
                  height: 118,
                  onTap: () => viewModel.setNewKeyCreationType(ParentNewKeyCreationType.autoGenerate),
                ),
              ],
            );
          },
        ),
      ],
      ParentKeyPreparationType.import => [
        Consumer<ParentCreationViewModel>(
          builder: (context, viewModel, child) {
            return MenuGrid(
              children: [
                SelectableOptionCard(
                  title: t.taproot.common.existing_option1,
                  bottomAssetPath: 'assets/png/finger-picking.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.isCurrentVaultSelected,
                  height: 118,
                  onTap: () => viewModel.setExistingKeyImportType(ParentExistingKeyImportType.currentVault),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.existing_option2,
                  bottomAssetPath: 'assets/png/word.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.isMnemonicInputSelected,
                  height: 118,
                  onTap: () => viewModel.setExistingKeyImportType(ParentExistingKeyImportType.mnemonicInput),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.existing_option3,
                  bottomAssetPath: 'assets/png/scan-qr.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.isSeedQrScanSelected,
                  height: 118,
                  onTap: () => viewModel.setExistingKeyImportType(ParentExistingKeyImportType.seedQrScan),
                ),
              ],
            );
          },
        ),
      ],
      ParentKeyPreparationType.none => [const SizedBox.shrink()],
    };

    _addStep(titleList: titleLines, bodyList: bodyList, nextButtonAction: _onKeyCreationOrImportOptionSelected);
  }

  void _onKeyCreationOrImportOptionSelected() {
    if (_viewModel.selectedKeyPreparationType == ParentKeyPreparationType.create) {
      _addEmbeddedStep(SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: _addSelectedKeyCreationOrImportScreen));
      return;
    }

    _addSelectedKeyCreationOrImportScreen();
  }

  void _addSelectedKeyCreationOrImportScreen() {
    final embeddedScreen = _buildEmbeddedScreen();
    if (embeddedScreen == null) {
      return;
    }

    _addEmbeddedStep(embeddedScreen);
  }

  void _addMnemonicConfirmationStep() {
    final calledFrom = switch (_viewModel.selectedNewKeyCreationType) {
      ParentNewKeyCreationType.coinFlip => AppRoutes.mnemonicCoinflip,
      ParentNewKeyCreationType.diceRoll => AppRoutes.mnemonicDiceRoll,
      ParentNewKeyCreationType.autoGenerate => AppRoutes.mnemonicVerify,
      ParentNewKeyCreationType.none => AppRoutes.mnemonicAutoGen,
    };

    if (calledFrom == AppRoutes.mnemonicVerify) {
      _addMnemonicVerifyStep();
      return;
    }

    _addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: calledFrom,
        isEmbedded: true,
        isTaprootChild: true,
        onMnemonicReady: _addMnemonicVerifyStep,
      ),
    );
  }

  void _onMnemonicReady() {
    _onKeyPreparationTypeSelected();
  }

  void _addMnemonicVerifyStep() {
    _addEmbeddedStep(
      MnemonicVerifyScreen(
        isEmbedded: true,
        isTaprootChild: true,
        onVerificationSuccess: _addVerifiedMnemonicConfirmationStep,
      ),
    );
  }

  void _addVerifiedMnemonicConfirmationStep() {
    _addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: AppRoutes.mnemonicVerify,
        isEmbedded: true,
        isTaprootChild: true,
        onMnemonicReady: _onMnemonicReady,
      ),
    );
  }

  void _addEmbeddedStep(Widget embeddedScreen) {
    _addStep(
      titleList: const [],
      bodyList: [embeddedScreen],
      nextButtonAction: null,
      ignoreBodyHorizontalPadding: true,
      pauseProgress: true,
    );
  }

  Widget? _buildEmbeddedScreen() {
    final screen = _selectedKeyCreationOrImportScreen();
    if (screen == null) {
      return null;
    }
    return screen;
  }

  Widget? _selectedKeyCreationOrImportScreen() {
    switch (_viewModel.selectedKeyPreparationType) {
      case ParentKeyPreparationType.create:
        return switch (_viewModel.selectedNewKeyCreationType) {
          ParentNewKeyCreationType.coinFlip => MnemonicCoinflipScreen(
            entropyType: EntropyType.manual,
            isEmbedded: true,
            isTaprootChild: true,
            onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
          ),
          ParentNewKeyCreationType.diceRoll => MnemonicDiceRollScreen(
            entropyType: EntropyType.manual,
            isEmbedded: true,
            isTaprootChild: true,
            onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
          ),
          ParentNewKeyCreationType.autoGenerate => MnemonicAutoGenScreen(
            entropyType: EntropyType.auto,
            isEmbedded: true,
            isTaprootChild: true,
            onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
          ),
          ParentNewKeyCreationType.none => null,
        };
      case ParentKeyPreparationType.import:
        return switch (_viewModel.selectedExistingKeyImportType) {
          ParentExistingKeyImportType.currentVault => _buildCurrentVaultSelectionScreen(),
          ParentExistingKeyImportType.mnemonicInput => const MnemonicImportScreen(isEmbedded: true),
          ParentExistingKeyImportType.seedQrScan => const SeedQrImportScreen(isEmbedded: true),
          ParentExistingKeyImportType.none => null,
        };
      case ParentKeyPreparationType.none:
        return null;
    }
  }

  Widget _buildCurrentVaultSelectionScreen() {
    return Center(
      child: Text(
        t.taproot.common.existing_option1,
        style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.black),
        textAlign: TextAlign.center,
      ),
    );
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
                ignoreChildHorizontalPadding: _ignoreBodyHorizontalPaddingList[_currentStep - 1],
                showHeader: !_isProgressPaused,
                scrollChild: !_isProgressPaused,
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
