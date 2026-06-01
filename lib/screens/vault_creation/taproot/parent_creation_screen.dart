import 'dart:async';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/parent_creation_view_model.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/parent_creation_completion_steps.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/parent_creation_overlays.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_mnemonic_flow_adapter.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_mnemonic_view_flow_adapter.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/parent_creation_step_widgets.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/mnemonic_view_screen.dart';
import 'package:coconut_vault/widgets/box/info_box.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:coconut_vault/widgets/text/character_fade_in_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ParentCreationScreen extends StatefulWidget {
  const ParentCreationScreen({super.key});

  @override
  State<ParentCreationScreen> createState() => _ParentCreationScreenState();
}

class _ParentCreationScreenState extends State<ParentCreationScreen> {
  static const int _initialStepCount = 2;
  static const int _progressInitialStepCount = 1;
  static const Color _parentWalletActiveColor = CoconutColors.purple;

  final ParentCreationViewModel _viewModel = ParentCreationViewModel();
  late final List<List<TextSpan>> _titleList;
  late final List<List<Widget>> _bodyList;
  late final List<VoidCallback?> _nextButtonActions;
  late final List<Widget?> _fixedBottomSubWidgetList;
  late final List<bool> _ignoreBodyHorizontalPaddingList;
  late final List<bool> _pauseProgressList;
  late final List<bool> _scrollChildList;
  int _currentStep = 1;
  int? _keyPreparationStep;
  int? _keyCreationOrImportOptionStep;
  int? _parentKeyImportStep;
  int? _currentVaultSelectionStep;
  int? _multisigParentImportStep;
  int? _multisigParentListStep;
  int? _childWalletSetupStep;
  int? _childWalletCreationOptionStep;
  int? _childWalletImportedStep;
  int? _timelockSetupStep;
  int? _timelineStep;
  int? _exportQrStep;
  int? _mnemonicConfirmationStep;
  int? _mnemonicGeneratedReviewStep;
  int? _mnemonicVerifyStep;
  int? _verifiedMnemonicConfirmationStep;
  int? _createdTaprootVaultId;
  TaprootVaultCreationTimelineInfo? _timelineInfo;
  Timer? _titleAnimationTimer;
  bool _isTitleAnimationCompleted = false;
  bool _isTimelineAnimationCompleted = false;
  bool _isDuplicateChildWalletDialogVisible = false;
  bool _isCreatingChildWallet = false;

  bool get _hasNextBuiltStep => _currentStep < _titleList.length;

  @override
  void initState() {
    super.initState();
    _titleList = _initialTitleList();
    _bodyList = _initialBodyList();
    _nextButtonActions = [_moveToNextStep, _confirmWalletType];
    _fixedBottomSubWidgetList = [null, null];
    _ignoreBodyHorizontalPaddingList = [false, false];
    _pauseProgressList = [false, false];
    _scrollChildList = [true, true];
    _viewModel.addListener(_handleViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleTitleAnimationCompletion());
  }

  @override
  void dispose() {
    _titleAnimationTimer?.cancel();
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
                  isSelected: viewModel.selectedWalletType == ParentWalletType.singleSig,
                  onTap: () => viewModel.setWalletType(ParentWalletType.singleSig),
                  imageScale: 3.8,
                  height: 195,
                ),
                SelectableOptionCard(
                  title: t.taproot.parent_creation_screen.step_1.multisig_wallet,
                  description: t.taproot.parent_creation_screen.step_1.wallet_usable_after_signed_all,
                  bottomAssetPath: 'assets/png/multi-keys.png',
                  isSelected: viewModel.selectedWalletType == ParentWalletType.multisig,
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

  bool get _showBottomButton {
    return _onNextPressed != null &&
        (_currentStep <= _initialStepCount || _isTitleAnimationCompleted) &&
        (!_isTimelineStep || _isTimelineAnimationCompleted);
  }

  bool get _runBottomButtonActionWithoutTransition {
    return _currentStep == _childWalletSetupStep &&
        _viewModel.selectedChildWalletSetupType == ChildWalletSetupType.create;
  }

  bool get _isTimelineStep => _currentStep == _timelineStep;

  bool get _isExportQrStep => _currentStep == _exportQrStep;

  bool get _showExistingKeyImportModeToggle {
    return _currentStep == _parentKeyImportStep &&
        _viewModel.selectedKeyPreparationType == ParentKeyPreparationType.import &&
        (_viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput ||
            _viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.seedQrScan);
  }

  bool get _canRunCurrentStepAction {
    if (_currentStep == _currentVaultSelectionStep) {
      return _viewModel.selectedExistingVaultId != null;
    }

    if (_currentStep == _multisigParentListStep) {
      return _viewModel.externalParentSignerBsms != null;
    }

    if (_currentStep == _childWalletSetupStep) {
      return _viewModel.selectedChildWalletSetupType != ChildWalletSetupType.none;
    }

    if (_currentStep == _childWalletCreationOptionStep) {
      return _viewModel.selectedChildNewKeyCreationType != ParentNewKeyCreationType.none;
    }

    if (_currentStep == _timelockSetupStep) {
      return _viewModel.selectedTimelockDateTime != null;
    }

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
            : _viewModel.hasSelectedKeyCreationOrImportOption,
      5 =>
        _viewModel.selectedWalletType == ParentWalletType.multisig
            ? _viewModel.hasSelectedKeyCreationOrImportOption
            : true,
      _ => true,
    };
  }

  bool get _isProgressPaused => _pauseProgressList[_currentStep - 1];

  bool get _showHeader {
    return !_isProgressPaused || _isExportQrStep;
  }

  int get _progressCurrentStep {
    return (_pauseProgressList.take(_currentStep).where((isPaused) => !isPaused).length - _progressInitialStepCount)
        .clamp(0, _viewModel.progressTotalStep);
  }

  Duration get _titleAnimationDuration {
    const headerInitialDelay = Duration(milliseconds: 200);
    const headerLineFadeInDuration = Duration(milliseconds: 700);
    return headerInitialDelay + (headerLineFadeInDuration * _titleLines().length);
  }

  void _scheduleTitleAnimationCompletion() {
    _titleAnimationTimer?.cancel();

    if (!mounted) {
      return;
    }

    if (_currentStep <= _initialStepCount ||
        _isProgressPaused ||
        _titleLines().every((line) => line.toPlainText().isEmpty)) {
      setState(() {
        _isTitleAnimationCompleted = true;
      });
      return;
    }

    setState(() {
      _isTitleAnimationCompleted = false;
    });

    _titleAnimationTimer = Timer(_titleAnimationDuration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _isTitleAnimationCompleted = true;
      });
    });
  }

  void _moveToNextStep() {
    debugPrint(
      'Current Step: $_currentStep, Built Step: ${_titleList.length}, '
      'Progress Total Step: ${_viewModel.progressTotalStep}',
    );
    if (!_hasNextBuiltStep) {
      return;
    }

    setState(() {
      _currentStep += 1;
    });
    _scheduleTitleAnimationCompletion();
  }

  void _confirmWalletType() {
    switch (_viewModel.selectedWalletType) {
      case ParentWalletType.singleSig:
        _onWalletTypeGuideConfirmed();
        return;
      case ParentWalletType.multisig:
        _startMultisigParentCreation();
        return;
      case ParentWalletType.none:
        return;
    }
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

  int _addStep({
    required List<TextSpan> titleList,
    required List<Widget> bodyList,
    required VoidCallback? nextButtonAction,
    Widget? fixedBottomSubWidget,
    bool ignoreBodyHorizontalPadding = false,
    bool pauseProgress = false,
    bool scrollChild = true,
  }) {
    final addedStep = _titleList.length + 1;
    setState(() {
      _titleList.add(titleList);
      _bodyList.add(bodyList);
      _nextButtonActions.add(nextButtonAction);
      _fixedBottomSubWidgetList.add(fixedBottomSubWidget);
      _ignoreBodyHorizontalPaddingList.add(ignoreBodyHorizontalPadding);
      _pauseProgressList.add(pauseProgress);
      _scrollChildList.add(scrollChild);
      _currentStep += 1;
    });
    _scheduleTitleAnimationCompletion();
    return addedStep;
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
                isSelected: viewModel.selectedKeyPreparationType == ParentKeyPreparationType.create,
                onTap: () => viewModel.setKeyPreparationType(ParentKeyPreparationType.create),
                imageScale: 3.8,
                height: 217,
              ),
              SelectableOptionCard(
                title: t.taproot.common.prepare_key_option2_title,
                description: t.taproot.common.prepare_key_option2_desc,
                bottomAssetPath: 'assets/png/key-holder.png',
                isSelected: viewModel.selectedKeyPreparationType == ParentKeyPreparationType.import,
                onTap: () => viewModel.setKeyPreparationType(ParentKeyPreparationType.import),
                imageScale: 3.8,
                height: 217,
              ),
            ],
          );
        },
      ),
    ];
    _keyPreparationStep = _addStep(
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
      ParentKeyPreparationType.create => _newWalletCreationOptionTitleList(),
      ParentKeyPreparationType.import => [TextSpan(text: t.taproot.common.existing_mnemonic_title)],
      ParentKeyPreparationType.none => [const TextSpan(text: '')],
    };

    final bodyList = switch (_viewModel.selectedKeyPreparationType) {
      ParentKeyPreparationType.create => [
        ParentNewKeyCreationOptionMenu(
          selectedType: (viewModel) => viewModel.selectedNewKeyCreationType,
          onSelected: (viewModel, type) => viewModel.setNewKeyCreationType(type),
        ),
      ],
      ParentKeyPreparationType.import => [
        Consumer<ParentCreationViewModel>(
          builder: (context, viewModel, child) {
            final hasNoSingleSigVault = context.select<WalletProvider, bool>(
              (walletProvider) => walletProvider.getVaultsByWalletType(WalletType.singleSignature).isEmpty,
            );

            return MenuGrid(
              children: [
                SelectableOptionCard(
                  title: t.taproot.common.existing_option1,
                  isDisabled: hasNoSingleSigVault,
                  bottomAssetPath: 'assets/png/finger-picking.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.currentVault,
                  height: 118,
                  onDisabledTap: () {
                    CoconutToast.showToast(
                      context: context,
                      level: CoconutToastLevel.info,
                      isVisibleIcon: true,
                      text: t.taproot.common.existing_option1_toast,
                    );
                  },
                  onTap: () => viewModel.setExistingKeyImportType(ParentExistingKeyImportType.currentVault),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.existing_option2,
                  bottomAssetPath: 'assets/png/word.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput,
                  height: 118,
                  onTap: () => viewModel.setExistingKeyImportType(ParentExistingKeyImportType.mnemonicInput),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.existing_option3,
                  bottomAssetPath: 'assets/png/scan-qr.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.seedQrScan,
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

    _keyCreationOrImportOptionStep = _addStep(
      titleList: titleLines,
      bodyList: bodyList,
      nextButtonAction: _onKeyCreationOrImportOptionSelected,
    );
  }

  void _onKeyCreationOrImportOptionSelected() {
    if (_viewModel.selectedKeyPreparationType == ParentKeyPreparationType.create) {
      _addEmbeddedStep(SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: _addSelectedKeyCreationOrImportScreen));
      return;
    }

    if (_viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.currentVault) {
      _addCurrentVaultSelectionStep();
      return;
    }

    _addSelectedKeyCreationOrImportScreen();
  }

  void _addSelectedKeyCreationOrImportScreen() {
    final embeddedScreen = _buildSelectedKeyCreationOrImportEmbeddedScreen();
    if (embeddedScreen == null) {
      return;
    }

    if (_viewModel.selectedKeyPreparationType == ParentKeyPreparationType.import &&
        (_viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput ||
            _viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.seedQrScan)) {
      _parentKeyImportStep = _addEmbeddedStep(
        Consumer<ParentCreationViewModel>(
          builder: (context, viewModel, child) {
            return _buildSelectedKeyCreationOrImportEmbeddedScreen() ?? const SizedBox.shrink();
          },
        ),
      );
      return;
    }

    _addEmbeddedStep(embeddedScreen);
  }

  void _toggleExistingKeyImportMode() {
    final nextType = switch (_viewModel.selectedExistingKeyImportType) {
      ParentExistingKeyImportType.mnemonicInput => ParentExistingKeyImportType.seedQrScan,
      ParentExistingKeyImportType.seedQrScan => ParentExistingKeyImportType.mnemonicInput,
      _ => ParentExistingKeyImportType.mnemonicInput,
    };

    _viewModel.setExistingKeyImportType(nextType);
  }

  void _addMnemonicConfirmationStep() {
    _resetMnemonicStepIndexes();
    final selectedCreationType =
        _isCreatingChildWallet ? _viewModel.selectedChildNewKeyCreationType : _viewModel.selectedNewKeyCreationType;
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(selectedCreationType);
    if (mnemonicCreationMethod == null) {
      return;
    }

    final confirmationStep = TaprootMnemonicFlowAdapter.addCreationConfirmationStep(
      addEmbeddedStep: _addEmbeddedStep,
      method: mnemonicCreationMethod,
      onMnemonicReady: _addMnemonicVerifyStep,
      onAutoGenerateReady: _addMnemonicVerifyStep,
    );
    if (confirmationStep != -1) {
      _mnemonicConfirmationStep = confirmationStep;
    }
  }

  void _addMnemonicVerifyStep() {
    if (_mnemonicConfirmationStep == null && _isAutoGenerateMnemonicFlow) {
      _mnemonicGeneratedReviewStep = _currentStep;
    }

    _mnemonicVerifyStep = TaprootMnemonicFlowAdapter.addVerifyStep(
      addEmbeddedStep: _addEmbeddedStep,
      onVerificationSuccess: _addVerifiedMnemonicConfirmationStep,
    );
  }

  bool get _isAutoGenerateMnemonicFlow {
    final selectedCreationType =
        _isCreatingChildWallet ? _viewModel.selectedChildNewKeyCreationType : _viewModel.selectedNewKeyCreationType;
    return selectedCreationType == ParentNewKeyCreationType.autoGenerate;
  }

  void _addVerifiedMnemonicConfirmationStep() {
    _verifiedMnemonicConfirmationStep = TaprootMnemonicFlowAdapter.addVerifiedConfirmationStep(
      addEmbeddedStep: _addEmbeddedStep,
      onMnemonicReady: () {
        if (_isCreatingChildWallet) {
          _onCreatedChildWalletReady();
          return;
        }

        final taprootWalletCreationProvider = context.read<TaprootWalletCreationProvider>();
        if (_viewModel.selectedWalletType == ParentWalletType.multisig) {
          _setParentWalletSecret(
            taprootWalletCreationProvider.secret,
            passphrase: taprootWalletCreationProvider.passphrase,
          );
          _addMultisigParentExportStep();
          return;
        }

        _onParentWalletSet(taprootWalletCreationProvider.secret, passphrase: taprootWalletCreationProvider.passphrase);
      },
    );
  }

  int _addEmbeddedStep(Widget embeddedScreen) {
    return _addStep(
      titleList: const [],
      bodyList: [embeddedScreen],
      nextButtonAction: null,
      ignoreBodyHorizontalPadding: true,
      pauseProgress: true,
    );
  }

  Widget? _buildSelectedKeyCreationOrImportEmbeddedScreen() {
    final screen = _selectedKeyCreationOrImportScreen();
    if (screen == null) {
      return null;
    }
    return screen;
  }

  Widget? _selectedKeyCreationOrImportScreen() {
    switch (_viewModel.selectedKeyPreparationType) {
      case ParentKeyPreparationType.create:
        return _buildNewMnemonicCreationScreen(_viewModel.selectedNewKeyCreationType);
      case ParentKeyPreparationType.import:
        return switch (_viewModel.selectedExistingKeyImportType) {
          ParentExistingKeyImportType.currentVault => null,
          ParentExistingKeyImportType.mnemonicInput => TaprootMnemonicFlowAdapter.buildMnemonicImportScreen(
            key: const ValueKey('parent-creation-mnemonic-import'),
            onMnemonicConfirmationRequested: _onImportedParentMnemonicReady,
          ),
          ParentExistingKeyImportType.seedQrScan => TaprootMnemonicFlowAdapter.buildSeedQrImportScreen(
            key: const ValueKey('parent-creation-seed-qr-import'),
            onMnemonicConfirmationRequested: _onImportedParentMnemonicReady,
          ),
          ParentExistingKeyImportType.none => null,
        };
      case ParentKeyPreparationType.none:
        return null;
    }
  }

  Widget? _buildNewMnemonicCreationScreen(ParentNewKeyCreationType creationType) {
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(creationType);
    if (mnemonicCreationMethod == null) {
      return null;
    }

    return TaprootMnemonicFlowAdapter.buildCreationScreen(
      method: mnemonicCreationMethod,
      onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
    );
  }

  void _onImportedParentMnemonicReady(Uint8List secret, Uint8List? passphrase) {
    if (_viewModel.selectedWalletType == ParentWalletType.multisig) {
      _setParentWalletSecret(secret, passphrase: passphrase);
      _addMultisigParentExportStep();
      return;
    }

    _onParentWalletSet(secret, passphrase: passphrase);
  }

  TaprootMnemonicCreationMethod? _mnemonicCreationMethodFrom(ParentNewKeyCreationType creationType) {
    return switch (creationType) {
      ParentNewKeyCreationType.coinFlip => TaprootMnemonicCreationMethod.coinFlip,
      ParentNewKeyCreationType.diceRoll => TaprootMnemonicCreationMethod.diceRoll,
      ParentNewKeyCreationType.autoGenerate => TaprootMnemonicCreationMethod.autoGenerate,
      ParentNewKeyCreationType.none => null,
    };
  }

  void _addCurrentVaultSelectionStep() {
    final titleList = [
      TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_1),
      TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_2),
    ];
    const bodyList = [Expanded(child: ParentExistingVaultSelectionBody())];

    _currentVaultSelectionStep = _addStep(
      titleList: titleList,
      bodyList: bodyList,
      nextButtonAction: _onCurrentVaultSelected,
      scrollChild: false,
      ignoreBodyHorizontalPadding: true,
    );
  }

  Future<void> _onCurrentVaultSelected() async {
    final selectedExistingVaultId = _viewModel.selectedExistingVaultId;
    if (selectedExistingVaultId == null) {
      return;
    }

    final confirmed = await ParentCreationOverlays.showCurrentVaultConfirmDialog(context);
    if (confirmed == true && mounted) {
      _proceedWithSelectedVault(selectedExistingVaultId);
    }
  }

  void _proceedWithSelectedVault(int selectedExistingVaultId) {
    if (!mounted) return;

    final mnemonicViewKey = GlobalKey<MnemonicViewScreenState>();
    _addEmbeddedStep(
      TaprootMnemonicViewFlowAdapter.buildMnemonicViewStep(
        mnemonicViewKey: mnemonicViewKey,
        walletId: selectedExistingVaultId,
        buildPassphraseToggle: true,
        emptyPassphraseAsNull: false,
        onAuthCanceled: _returnToPreviousStep,
        onMnemonicReady: (mnemonic, passphrase) {
          if (_viewModel.selectedWalletType == ParentWalletType.multisig) {
            _setParentWalletSecret(mnemonic, passphrase: passphrase);
            _addMultisigParentExportStep();
            return;
          }

          _onParentWalletSet(mnemonic, passphrase: passphrase);
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      TaprootMnemonicViewFlowAdapter.showDeviceAuthDialog(
        context: context,
        mnemonicViewKey: mnemonicViewKey,
        showDeviceAuthDialog: ParentCreationOverlays.showDeviceAuthDialog,
        authenticateWithBiometricOrPin: ParentCreationOverlays.authenticateWithBiometricOrPin,
      );
    });
  }

  /// STEP 2: 부모 지갑 설정 완료 -> 자식 지갑 설정 차례 진입
  void _onParentWalletSet(Uint8List secret, {Uint8List? passphrase}) {
    debugPrint('Step2로 이동');
    _setParentWalletSecret(secret, passphrase: passphrase);
    _addChildWalletSetupStep();
  }

  void _onMultisigParentsSet() {
    debugPrint('Step2로 이동');
    _addChildWalletSetupStep();
  }

  void _addChildWalletSetupStep() {
    final titleList = [
      TextSpan(text: t.taproot.parent_creation_screen.step_2.creation_script_path_intro_title_1),
      TextSpan(text: t.taproot.parent_creation_screen.step_2.creation_script_path_intro_title_2),
    ];
    final bodyList = [
      Consumer<ParentCreationViewModel>(
        builder: (context, viewModel, child) {
          return MenuGrid(
            children: [
              SelectableOptionCard(
                title: t.taproot.parent_creation_screen.step_2.creation_script_path_import,
                description: t.taproot.parent_creation_screen.step_2.creation_script_path_import_description,
                bottomAssetPath: 'assets/png/scan-qr-big.png',
                imageScale: 3.8,
                isSelected: viewModel.selectedChildWalletSetupType == ChildWalletSetupType.import,
                onTap: () => viewModel.setChildWalletSetupType(ChildWalletSetupType.import),
                imageWidth: 100,
                height: 195,
              ),
              SelectableOptionCard(
                title: t.taproot.parent_creation_screen.step_2.creation_script_path_create,
                description: t.taproot.parent_creation_screen.step_2.creation_script_path_create_description,
                bottomAssetPath: 'assets/png/load-wallet.png',
                imageScale: 3.8,
                isSelected: viewModel.selectedChildWalletSetupType == ChildWalletSetupType.create,
                onTap: () => viewModel.setChildWalletSetupType(ChildWalletSetupType.create),
                imageWidth: 100,
                height: 195,
              ),
            ],
          );
        },
      ),
    ];
    _childWalletSetupStep = _addStep(
      titleList: titleList,
      bodyList: bodyList,
      nextButtonAction: _onChildWalletSetupSelected,
    );
  }

  void _onChildWalletSetupSelected() {
    switch (_viewModel.selectedChildWalletSetupType) {
      case ChildWalletSetupType.import:
        _addChildWalletScanStep();
        return;
      case ChildWalletSetupType.create:
        _confirmChildWalletCreation();
        return;
      case ChildWalletSetupType.none:
        return;
    }
  }

  Future<void> _confirmChildWalletCreation() async {
    final confirmed = await ParentCreationOverlays.showCreateChildWalletConfirmDialog(context);
    if (confirmed == true && mounted) {
      _startChildWalletCreationFlow();
    }
  }

  void _addChildWalletScanStep() {
    final guideText = Text(
      '${t.taproot.parent_creation_screen.step_2.import_scanner_title_1}\n'
      '${t.taproot.parent_creation_screen.step_2.import_scanner_title_2}',
      style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.white),
      textAlign: TextAlign.center,
    );

    _addEmbeddedStep(
      TaprootScannerScreen(
        topGuideWidget: Positioned(top: 80, left: 24, right: 24, child: guideText),
        onTaprootVaultScanned:
            (beneficiaryVault) => _onChildWalletImported(beneficiaryVault, source: ParentChildWalletSource.scanned),
      ),
    );
  }

  void _startChildWalletCreationFlow() {
    _isCreatingChildWallet = true;
    _viewModel.resetChildNewKeyCreationType();
    _viewModel.resetChildWallet();
    _addChildWalletCreationOptionStep();
  }

  void _addChildWalletCreationOptionStep() {
    _childWalletCreationOptionStep = _addStep(
      titleList: _newWalletCreationOptionTitleList(),
      bodyList: [
        ParentNewKeyCreationOptionMenu(
          selectedType: (viewModel) => viewModel.selectedChildNewKeyCreationType,
          onSelected: (viewModel, type) => viewModel.setChildNewKeyCreationType(type),
        ),
      ],
      nextButtonAction: _onChildWalletCreationOptionSelected,
    );
  }

  List<TextSpan> _newWalletCreationOptionTitleList() {
    return [TextSpan(text: t.taproot.common.create_new_wallet_title)];
  }

  void _onChildWalletCreationOptionSelected() {
    if (_viewModel.selectedChildNewKeyCreationType == ParentNewKeyCreationType.none) {
      return;
    }

    _addEmbeddedStep(SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: _addSelectedChildWalletCreationScreen));
  }

  void _addSelectedChildWalletCreationScreen() {
    final embeddedScreen = _buildNewMnemonicCreationScreen(_viewModel.selectedChildNewKeyCreationType);
    if (embeddedScreen == null) {
      return;
    }

    _addEmbeddedStep(embeddedScreen);
  }

  void _onCreatedChildWalletReady() {
    final taprootWalletCreationProvider = context.read<TaprootWalletCreationProvider>();
    final seed = Seed.fromMnemonic(
      taprootWalletCreationProvider.secret,
      passphrase: taprootWalletCreationProvider.passphrase,
    );
    final childKeyStore = KeyStore.fromSeed(seed, AddressType.p2tr);
    final childVault = TaprootVault.fromKeyStoreList([childKeyStore], []);
    if (_onChildWalletImported(
      childVault,
      source: ParentChildWalletSource.created,
      secret: taprootWalletCreationProvider.secret,
      passphrase: taprootWalletCreationProvider.passphrase,
    )) {
      _isCreatingChildWallet = false;
    }
  }

  bool _onChildWalletImported(
    TaprootVault beneficiaryVault, {
    required ParentChildWalletSource source,
    Uint8List? secret,
    Uint8List? passphrase,
  }) {
    bool isScannedWalletSource = source == ParentChildWalletSource.scanned;
    final setResult = _viewModel.trySetChildWallet(
      beneficiaryVault: beneficiaryVault,
      source: source,
      secret: secret,
      passphrase: passphrase,
    );
    if (setResult == ParentChildWalletSetResult.sameAsParent) {
      _showSameChildWalletAsParentDialog();
      return false;
    }

    final childWalletMasterFingerprint = _viewModel.childWalletMasterFingerprint ?? '';

    final titleList = [
      TextSpan(
        text:
            isScannedWalletSource
                ? t.taproot.parent_creation_screen.step_2.imported_script_path_title
                : t.taproot.parent_creation_screen.step_2.created_script_path_title,
      ),
    ];
    final importedChildVaultGuide = [
      CharacterFadeInText(
        text: t.taproot.parent_creation_screen.step_2.imported_script_path_description_1,
        animationKey: 'taproot-parent-creation-body-imported-script-path-description-1',
        duration: const Duration(milliseconds: 400),
        delay: const Duration(milliseconds: 1700),
      ),
      CharacterFadeInText(
        text: t.taproot.parent_creation_screen.step_2.imported_script_path_description_2,
        animationKey: 'taproot-parent-creation-body-imported-script-path-description-2',
        duration: const Duration(milliseconds: 700),
        delay: const Duration(milliseconds: 2400),
      ),
      CoconutLayout.spacing_600h,
      InfoBox(
        infoList: [
          MapEntry(t.taproot.common.wallet_type, t.taproot.common.taproot_single_sig_wallet),
          MapEntry(t.taproot.common.mfp, childWalletMasterFingerprint),
        ],
      ),
    ];
    final fixedBottomButtonSubWidget = CoconutUnderlinedButton(
      text: t.taproot.parent_creation_screen.step_2.import_again,
      onTap: _resetChildWalletAndReturnToPreviousStep,
    );

    _childWalletImportedStep = _addStep(
      titleList: titleList,
      bodyList: importedChildVaultGuide,
      nextButtonAction: () {
        _addTimelockSetupStep();
      },
      fixedBottomSubWidget: isScannedWalletSource ? fixedBottomButtonSubWidget : null,
    );
    return true;
  }

  void _addTimelockSetupStep() {
    _resetTimelockDate();
    final today = DateTime.now();

    _timelockSetupStep = _addStep(
      titleList: ParentTimelockSetupBody.titleList(),
      bodyList: [_buildTimelockSetupBody(today)],
      nextButtonAction: _addVaultNameAndIconSetupStep,
    );
  }

  void _addVaultNameAndIconSetupStep() {
    _addEmbeddedStep(
      VaultNameAndIconSetupScreen(
        isEmbedded: true,
        isTaproot: true,
        taprootVaultSaveHandler: ({required name, required iconIndex, required colorIndex}) async {
          final result = await _viewModel.saveVault(
            context.read<WalletProvider>(),
            name: name,
            iconIndex: iconIndex,
            colorIndex: colorIndex,
          );
          return VaultNameAndIconSetupSaveResult.navigateToHome(
            addedWalletId: result.vaultId,
            taprootTimelineInfo: result.timelineInfo,
          );
        },
        onEmbeddedVaultSaved: _addTimelineStep,
      ),
    );
  }

  void _addTimelineStep(VaultNameAndIconSetupSaveResult result) {
    _createdTaprootVaultId = result.addedWalletId;
    _timelineInfo = result.taprootTimelineInfo;
    _isTimelineAnimationCompleted = false;

    _timelineStep = _addStep(
      titleList: ParentCreationCompletionSteps.timelineTitleList(),
      bodyList: [
        ParentCreationCompletionSteps.timelineIndicator(
          parentWalletType: _viewModel.selectedWalletType,
          timelineInfo: _timelineInfo,
          timelockDateTimeText: ParentTimelockSetupBody.dateTimeText(_viewModel.selectedTimelockDateTime),
          onCompleted: _handleTimelineAnimationCompleted,
        ),
      ],
      nextButtonAction: _addExportQrStep,
      fixedBottomSubWidget: ParentCreationCompletionSteps.maybeLaterButton(onTap: _navigateToHome),
    );
  }

  void _addExportQrStep() {
    final addedWalletId = _createdTaprootVaultId;
    if (addedWalletId == null) {
      return;
    }

    final qrData = context.read<WalletProvider>().getVaultById(addedWalletId).getWalletSyncString();

    _exportQrStep = _addStep(
      titleList: ParentCreationCompletionSteps.exportQrTitleList(),
      bodyList: [ParentCreationCompletionSteps.exportQrBody(qrData: qrData)],
      nextButtonAction: _navigateToHome,
      pauseProgress: true,
    );
  }

  void _handleTimelineAnimationCompleted() {
    if (!mounted || !_isTimelineStep || _isTimelineAnimationCompleted) {
      return;
    }

    setState(() {
      _isTimelineAnimationCompleted = true;
    });
  }

  void _navigateToHome() {
    final addedWalletId = _createdTaprootVaultId;
    if (addedWalletId == null) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (Route<dynamic> route) => false,
      arguments: VaultHomeNavArgs(addedWalletId: addedWalletId),
    );
  }

  void _resetTimelockDate() {
    _viewModel.resetTimelockDateTime();
  }

  Widget _buildTimelockSetupBody(DateTime today) {
    return ParentTimelockSetupBody(
      selectedDateTime: _viewModel.selectedTimelockDateTime,
      onDatePressed: () => _showDatePicker(today),
    );
  }

  void _showDatePicker(DateTime today) {
    ParentCreationOverlays.showTimelockDatePicker(
      context: context,
      today: today,
      initialDateTime: _viewModel.selectedTimelockDateTime,
      onDateTimeSelected: (selectedDateTime) {
        setState(() {
          _viewModel.setTimelockDateTime(selectedDateTime);
          final timelockStep = _timelockSetupStep;
          if (timelockStep != null) {
            _bodyList[timelockStep - 1] = [_buildTimelockSetupBody(today)];
          }
        });
      },
    );
  }

  void _showSameChildWalletAsParentDialog() {
    if (_isDuplicateChildWalletDialogVisible) {
      return;
    }

    _isDuplicateChildWalletDialogVisible = true;
    ParentCreationOverlays.showSameChildWalletAsParentDialog(
      context,
    ).whenComplete(() => _isDuplicateChildWalletDialogVisible = false);
  }

  void _resetChildWalletAndReturnToPreviousStep() {
    _viewModel.resetChildWallet();
    _returnToPreviousStep();
  }

  void _resetChildWalletAndReturnToSetupStep() {
    _viewModel.resetChildWallet();
    _returnToChildWalletSetupStep();
  }

  void _setParentWalletSecret(Uint8List secret, {Uint8List? passphrase}) {
    _viewModel.setParentWalletSecret(secret, passphrase: passphrase);
  }

  void _addMultisigParentExportStep() {
    // 내 부모 지갑 정보 보여주기
    final titleList = [
      TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_qr_title_1),
      TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_qr_title_2),
    ];
    const bodyList = [ParentMultisigParentExportQr()];
    _multisigParentImportStep = _addStep(
      titleList: titleList,
      bodyList: bodyList,
      nextButtonAction: _addMultisigListStep,
    );
  }

  void _addMultisigListStep() {
    // 다른 볼트의 다중 서명 부모 지갑 정보 가져오기
    final titleList = [
      TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_list_title_1),
      TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_list_title_2),
    ];
    final bodyList = [
      ParentMultisigParentList(
        activeColor: _parentWalletActiveColor,
        onCurrentWalletPressed: _showMultisigParentExportBottomSheet,
        onExternalWalletPressed: _showMultisigParentScannerBottomSheet,
      ),
    ];
    _multisigParentListStep = _addStep(
      titleList: titleList,
      bodyList: bodyList,
      nextButtonAction: _onMultisigParentsSet,
    );
  }

  void _showMultisigParentExportBottomSheet() {
    ParentCreationOverlays.showMultisigParentExportBottomSheet(context);
  }

  Future<void> _showMultisigParentScannerBottomSheet() async {
    final TaprootVault? importedParent = await ParentCreationOverlays.showMultisigParentScannerBottomSheet(context);

    if (importedParent == null) {
      debugPrint('Multisig parent wallet scan canceled or failed.');
      return;
    }

    debugPrint('Scanned multisig parent wallet data: $importedParent');
    if (!mounted) {
      return;
    }
    if (_viewModel.isSameAsParentWalletDescriptor(importedParent.descriptor)) {
      final shouldScanAgain = await _showSameParentWalletDialog();
      if (shouldScanAgain == true && mounted) {
        await _showMultisigParentScannerBottomSheet();
      }
      return;
    }

    try {
      _viewModel.setExternalParentVault(importedParent);
      setState(() {});
    } on NetworkMismatchException catch (e) {
      await ParentCreationOverlays.showParentScanErrorDialog(
        context: context,
        title: t.alert.bsms_network_mismatch.title,
        description: e.message,
      );
    } on FormatException {
      await ParentCreationOverlays.showParentScanErrorDialog(
        context: context,
        title: t.errors.invalid_qr_title,
        description: t.errors.invalid_qr,
      );
    }
  }

  Future<bool?> _showSameParentWalletDialog() {
    return ParentCreationOverlays.showSameParentWalletDialog(context);
  }

  void _handleBackPressed() {
    if (_isTimelineStep || _isExportQrStep) {
      _navigateToHome();
      return;
    }

    if (_currentStep <= 1) {
      Navigator.pop(context);
      return;
    }

    if (_returnToMnemonicConfirmationStepIfNeeded()) {
      return;
    }

    if (_returnToGeneratedMnemonicReviewStepIfNeeded()) {
      return;
    }

    if (_currentStep == _childWalletSetupStep) {
      _showParentWalletResetDialog();
      return;
    }

    if (_currentStep == _childWalletImportedStep) {
      _showChildWalletResetDialog();
      return;
    }

    if (_currentStep == _multisigParentImportStep || _currentStep == _multisigParentListStep) {
      _showParentWalletResetDialog();
      return;
    }

    _returnToPreviousStep();
  }

  bool _returnToMnemonicConfirmationStepIfNeeded() {
    final targetStep = _mnemonicConfirmationStep;
    if (targetStep == null || targetStep < 1 || targetStep > _titleList.length) {
      return false;
    }

    if (_currentStep != _mnemonicVerifyStep && _currentStep != _verifiedMnemonicConfirmationStep) {
      return false;
    }

    setState(() {
      while (_titleList.length > targetStep) {
        final lastIndex = _titleList.length - 1;
        _titleList.removeAt(lastIndex);
        _bodyList.removeAt(lastIndex);
        _nextButtonActions.removeAt(lastIndex);
        _fixedBottomSubWidgetList.removeAt(lastIndex);
        _ignoreBodyHorizontalPaddingList.removeAt(lastIndex);
        _pauseProgressList.removeAt(lastIndex);
        _scrollChildList.removeAt(lastIndex);
      }

      _currentStep = targetStep;
      _mnemonicVerifyStep = null;
      _verifiedMnemonicConfirmationStep = null;
    });
    _scheduleTitleAnimationCompletion();
    return true;
  }

  bool _returnToGeneratedMnemonicReviewStepIfNeeded() {
    final targetStep = _mnemonicGeneratedReviewStep;
    if (targetStep == null || targetStep < 1 || targetStep > _titleList.length) {
      return false;
    }

    if ((_currentStep != _mnemonicVerifyStep && _currentStep != _verifiedMnemonicConfirmationStep) ||
        _mnemonicConfirmationStep != null) {
      return false;
    }

    final taprootWalletCreationProvider = context.read<TaprootWalletCreationProvider>();
    if (taprootWalletCreationProvider.secret.isEmpty) {
      return false;
    }

    setState(() {
      while (_titleList.length > targetStep) {
        final lastIndex = _titleList.length - 1;
        _titleList.removeAt(lastIndex);
        _bodyList.removeAt(lastIndex);
        _nextButtonActions.removeAt(lastIndex);
        _fixedBottomSubWidgetList.removeAt(lastIndex);
        _ignoreBodyHorizontalPaddingList.removeAt(lastIndex);
        _pauseProgressList.removeAt(lastIndex);
        _scrollChildList.removeAt(lastIndex);
      }

      _bodyList[targetStep - 1] = [_buildGeneratedMnemonicReviewBody(taprootWalletCreationProvider.secret)];
      _nextButtonActions[targetStep - 1] = _addMnemonicVerifyStep;
      _fixedBottomSubWidgetList[targetStep - 1] = null;
      _ignoreBodyHorizontalPaddingList[targetStep - 1] = false;
      _pauseProgressList[targetStep - 1] = true;
      _scrollChildList[targetStep - 1] = true;
      _currentStep = targetStep;
      _mnemonicVerifyStep = null;
      _verifiedMnemonicConfirmationStep = null;
    });
    _scheduleTitleAnimationCompletion();
    return true;
  }

  Widget _buildGeneratedMnemonicReviewBody(Uint8List mnemonic) {
    return Padding(padding: const EdgeInsets.only(top: 40), child: MnemonicList(mnemonic: mnemonic));
  }

  Future<void> _showParentWalletResetDialog() async {
    final confirmed = await ParentCreationOverlays.showParentWalletResetDialog(context);
    if (confirmed == true && mounted) {
      _resetParentWalletAndReturnToKeyOptionStep();
    }
  }

  Future<void> _showChildWalletResetDialog() async {
    final confirmed = await ParentCreationOverlays.showChildWalletResetDialog(context);
    if (confirmed == true && mounted) {
      _resetChildWalletAndReturnToSetupStep();
    }
  }

  void _resetParentWalletAndReturnToKeyOptionStep() {
    _returnToKeyCreationOrImportOptionStep(resetParentWallet: true);
  }

  void _returnToKeyCreationOrImportOptionStep({required bool resetParentWallet}) {
    final targetStep = _keyCreationOrImportOptionStep;
    if (targetStep == null || targetStep < 1 || targetStep > _titleList.length) {
      _returnToPreviousStep();
      return;
    }

    if (resetParentWallet) {
      _viewModel.resetParentWalletData();
    }

    setState(() {
      while (_titleList.length > targetStep) {
        final lastIndex = _titleList.length - 1;
        _titleList.removeAt(lastIndex);
        _bodyList.removeAt(lastIndex);
        _nextButtonActions.removeAt(lastIndex);
        _fixedBottomSubWidgetList.removeAt(lastIndex);
        _ignoreBodyHorizontalPaddingList.removeAt(lastIndex);
        _pauseProgressList.removeAt(lastIndex);
        _scrollChildList.removeAt(lastIndex);
      }

      _currentStep = targetStep;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childWalletCreationOptionStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
    });
    _resetSelectionForBackNavigation();
    _scheduleTitleAnimationCompletion();
  }

  void _returnToChildWalletSetupStep() {
    final targetStep = _childWalletSetupStep;
    if (targetStep == null || targetStep < 1 || targetStep > _titleList.length) {
      _returnToPreviousStep();
      return;
    }

    setState(() {
      while (_titleList.length > targetStep) {
        final lastIndex = _titleList.length - 1;
        _titleList.removeAt(lastIndex);
        _bodyList.removeAt(lastIndex);
        _nextButtonActions.removeAt(lastIndex);
        _fixedBottomSubWidgetList.removeAt(lastIndex);
        _ignoreBodyHorizontalPaddingList.removeAt(lastIndex);
        _pauseProgressList.removeAt(lastIndex);
        _scrollChildList.removeAt(lastIndex);
      }

      _currentStep = targetStep;
      _childWalletCreationOptionStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      _viewModel.resetChildNewKeyCreationType();
    });
    _scheduleTitleAnimationCompletion();
  }

  void _returnToPreviousStep() {
    if (_currentStep <= 1) {
      return;
    }

    final previousStep = _currentStep;
    setState(() {
      if (_currentStep <= _initialStepCount) {
        _currentStep -= 1;
        return;
      }

      final currentStepIndex = _currentStep - 1;
      _titleList.removeAt(currentStepIndex);
      _bodyList.removeAt(currentStepIndex);
      _nextButtonActions.removeAt(currentStepIndex);
      _fixedBottomSubWidgetList.removeAt(currentStepIndex);
      _ignoreBodyHorizontalPaddingList.removeAt(currentStepIndex);
      _pauseProgressList.removeAt(currentStepIndex);
      _scrollChildList.removeAt(currentStepIndex);
      if (_currentStep == _parentKeyImportStep) {
        _parentKeyImportStep = null;
      }
      _currentStep -= 1;
    });
    _resetSelectionForBackNavigation(previousStep: previousStep);
    _scheduleTitleAnimationCompletion();
  }

  void _resetSelectionForBackNavigation({int? previousStep}) {
    if (_currentStep <= 2 || previousStep == 2) {
      _viewModel.resetSelection(ParentSelectionResetScope.walletType);
      _keyPreparationStep = null;
      _keyCreationOrImportOptionStep = null;
      _parentKeyImportStep = null;
      _currentVaultSelectionStep = null;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childWalletCreationOptionStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      return;
    }

    if (_currentStep == _keyPreparationStep || previousStep == _keyPreparationStep) {
      _viewModel.resetSelection(ParentSelectionResetScope.keyPreparation);
      _keyCreationOrImportOptionStep = null;
      _parentKeyImportStep = null;
      _currentVaultSelectionStep = null;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childWalletCreationOptionStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      return;
    }

    if (_currentStep == _keyCreationOrImportOptionStep || previousStep == _keyCreationOrImportOptionStep) {
      _viewModel.resetSelection(ParentSelectionResetScope.keyCreationOrImportOption);
      _parentKeyImportStep = null;
      _currentVaultSelectionStep = null;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childWalletCreationOptionStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
    }
  }

  void _resetMnemonicStepIndexes() {
    _mnemonicConfirmationStep = null;
    _mnemonicGeneratedReviewStep = null;
    _mnemonicVerifyStep = null;
    _verifiedMnemonicConfirmationStep = null;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PopScope(
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
            title: t.taproot.parent_creation_screen.title,
            context: context,
            isBottom: _isTimelineStep || _isExportQrStep,
            backgroundColor: CoconutColors.white,
            onBackPressed: _handleBackPressed,
            actionButtonList: [
              Visibility(
                visible: _showExistingKeyImportModeToggle,
                child: IconButton(
                  icon:
                      _viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput
                          ? SvgPicture.asset('assets/svg/scan.svg')
                          : SvgPicture.asset('assets/svg/paste.svg'),
                  color: CoconutColors.black,
                  onPressed: _toggleExistingKeyImportMode,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                TaprootCreationBody(
                  titleLines: _titleLines(),
                  onBottomButtonPressed: _onNextPressed,
                  bottomButtonText:
                      _isTimelineStep
                          ? t.taproot.parent_creation_screen.step_4.timeline.export_wallet_info
                          : _isExportQrStep
                          ? t.complete
                          : null,
                  fixedBottomSubWidget: _fixedBottomSubWidgetList[_currentStep - 1],
                  runBottomButtonActionWithoutTransition: _runBottomButtonActionWithoutTransition,
                  keepHeaderVisibleDuringTransition: _isTimelineStep,
                  animateHeader: !_isExportQrStep,
                  showBottomButton: _showBottomButton,
                  ignoreChildHorizontalPadding: _ignoreBodyHorizontalPaddingList[_currentStep - 1],
                  showHeader: _showHeader,
                  scrollChild: !_isProgressPaused && _scrollChildList[_currentStep - 1],
                  child:
                      _isProgressPaused
                          ? _bodyList[_currentStep - 1].first
                          : Column(children: _bodyList[_currentStep - 1]),
                ),
                TopProgressBar(
                  visible: !_isProgressPaused,
                  total: _viewModel.progressTotalStep,
                  current: _progressCurrentStep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
