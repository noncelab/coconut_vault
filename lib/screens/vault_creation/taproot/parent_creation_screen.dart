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
import 'package:coconut_vault/widgets/coconut_loading_overlay.dart';
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

enum ParentCreationStep {
  intro,
  selectWalletType,
  multisigStartGuide,
  selectParentKeyPreparation,
  selectParentKeyCreationOrImport,
  parentKeyImport,
  currentVaultSelection,
  currentVaultMnemonicView,
  parentSecuritySelfCheck,
  parentMnemonicEntry,
  parentMnemonicConfirmation,
  parentMnemonicGeneratedReview,
  parentMnemonicVerify,
  parentVerifiedMnemonicConfirmation,
  multisigParentExportQr,
  multisigParentList,
  childWalletSetup,
  childWalletScan,
  childKeyPreparation,
  childKeyImportOption,
  childCurrentVaultSelection,
  childWalletCreationOption,
  childSecuritySelfCheck,
  childMnemonicEntry,
  childMnemonicConfirmation,
  childMnemonicGeneratedReview,
  childMnemonicVerify,
  childVerifiedMnemonicConfirmation,
  childWalletImported,
  timelockSetup,
  vaultNameAndIconSetup,
  timeline,
  exportQr,
}

enum KeyPreparationTarget { parent, child }

class _ParentCreationScreenState extends State<ParentCreationScreen> {
  static const int _initialStepCount = 2;
  static const int _progressInitialStepCount = 1;
  static const Color _parentWalletActiveColor = CoconutColors.purple;

  late final ParentCreationViewModel _viewModel;
  final List<ParentCreationStep> _stepHistory = [ParentCreationStep.intro, ParentCreationStep.selectWalletType];
  int _currentStep = 1;
  int? _keyPreparationStep;
  int? _keyCreationOrImportOptionStep;
  int? _parentKeyImportStep;
  int? _multisigParentImportStep;
  int? _multisigParentListStep;
  int? _childWalletSetupStep;
  int? _childKeyPreparationStep;
  int? _childWalletImportedStep;
  int? _mnemonicConfirmationStep;
  int? _mnemonicGeneratedReviewStep;
  int? _mnemonicVerifyStep;
  int? _verifiedMnemonicConfirmationStep;
  int? _createdTaprootVaultId;
  ParentChildWalletSource? _childWalletSource;
  DateTime? _timelockPickerToday;
  TaprootVaultCreationTimelineInfo? _timelineInfo;
  GlobalKey<MnemonicViewScreenState>? _currentVaultMnemonicViewKey;
  Timer? _titleAnimationTimer;
  bool _isTitleAnimationCompleted = false;
  bool _isTimelineAnimationCompleted = false;
  bool _isDuplicateChildWalletDialogVisible = false;
  bool _isCheckingDuplicateWallet = false;
  bool _isCreatingChildWallet = false;
  bool _currentVaultMnemonicAuthRequested = false;

  bool get _hasNextBuiltStep => _currentStep < _stepHistory.length;

  @override
  void initState() {
    super.initState();
    _viewModel = ParentCreationViewModel(context.read<WalletProvider>());
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

  ParentCreationStep get _currentStepType => _stepHistory[_currentStep - 1];

  int _stepIndexOf(ParentCreationStep step) {
    return _stepHistory.lastIndexOf(step);
  }

  List<TextSpan> _titleLines() {
    final textList = _getTitleList(_currentStepType);
    if (textList.length == 1) {
      return [const TextSpan(text: ''), textList[0], const TextSpan(text: '')];
    }
    if (textList.length == 2) {
      return [textList[0], textList[1], const TextSpan(text: '')];
    }
    return textList;
  }

  List<TextSpan> _getTitleList(ParentCreationStep step) {
    return switch (step) {
      ParentCreationStep.intro => [
        TextSpan(text: t.taproot.parent_creation_screen.creation_intro_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.creation_intro_title_2),
      ],
      ParentCreationStep.selectWalletType => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.title_2),
      ],
      ParentCreationStep.multisigStartGuide => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_start_with_another_vault_title_2),
      ],
      ParentCreationStep.selectParentKeyPreparation => switch (_viewModel.selectedWalletType) {
        ParentWalletType.singleSig => [
          TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_how_to_prepare_key_title_1),
          TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_how_to_prepare_key_title_2),
        ],
        ParentWalletType.multisig => [
          TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_how_to_prepare_key_title_1),
          TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_how_to_prepare_key_title_2),
        ],
        ParentWalletType.none => [const TextSpan(text: '')],
      },
      ParentCreationStep.selectParentKeyCreationOrImport => switch (_viewModel.selectedKeyPreparationType) {
        ParentKeyPreparationType.create => _newWalletCreationOptionTitleList(),
        ParentKeyPreparationType.import => [TextSpan(text: t.taproot.common.existing_mnemonic_title)],
        ParentKeyPreparationType.none => [const TextSpan(text: '')],
      },
      ParentCreationStep.currentVaultSelection => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_2),
      ],
      ParentCreationStep.multisigParentExportQr => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_qr_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_qr_title_2),
      ],
      ParentCreationStep.multisigParentList => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_list_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.multisig_list_title_2),
      ],
      ParentCreationStep.childWalletSetup => [
        TextSpan(text: t.taproot.parent_creation_screen.step_2.creation_script_path_intro_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_2.creation_script_path_intro_title_2),
      ],
      ParentCreationStep.childKeyPreparation => [
        TextSpan(text: t.taproot.parent_creation_screen.step_2.create_script_path_how_to_prepare_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_2.create_script_path_how_to_prepare_title_2),
      ],
      ParentCreationStep.childKeyImportOption => [TextSpan(text: t.taproot.common.existing_mnemonic_title)],
      ParentCreationStep.childCurrentVaultSelection => [
        TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_1),
        TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_2),
      ],
      ParentCreationStep.childWalletCreationOption => _newWalletCreationOptionTitleList(),
      ParentCreationStep.childWalletImported => [
        TextSpan(
          text:
              _childWalletSource == ParentChildWalletSource.scanned
                  ? t.taproot.parent_creation_screen.step_2.imported_script_path_title
                  : t.taproot.parent_creation_screen.step_2.created_script_path_title,
        ),
      ],
      ParentCreationStep.timelockSetup => ParentTimelockSetupBody.titleList(),
      ParentCreationStep.timeline => ParentCreationCompletionSteps.timelineTitleList(),
      ParentCreationStep.exportQr => ParentCreationCompletionSteps.exportQrTitleList(),
      _ => const [],
    };
  }

  List<Widget> _getBodyList(ParentCreationStep step) {
    return switch (step) {
      ParentCreationStep.intro => [_buildIntroBody()],
      ParentCreationStep.selectWalletType => [_buildWalletTypeSelectionBody()],
      ParentCreationStep.multisigStartGuide => _buildMultisigStartGuideBody(),
      ParentCreationStep.selectParentKeyPreparation => [_buildKeyPreparationBody()],
      ParentCreationStep.selectParentKeyCreationOrImport => [_buildParentKeyCreationOrImportOptionBody()],
      ParentCreationStep.parentSecuritySelfCheck => [
        SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: _addSelectedKeyCreationOrImportScreen),
      ],
      ParentCreationStep.parentKeyImport => [
        Consumer<ParentCreationViewModel>(
          builder: (context, viewModel, child) {
            return _buildSelectedKeyCreationOrImportEmbeddedScreen() ?? const SizedBox.shrink();
          },
        ),
      ],
      ParentCreationStep.parentMnemonicEntry => [
        _buildSelectedKeyCreationOrImportEmbeddedScreen() ?? const SizedBox.shrink(),
      ],
      ParentCreationStep.currentVaultSelection => [Expanded(child: _buildParentExistingVaultSelectionBody())],
      ParentCreationStep.currentVaultMnemonicView => [_buildCurrentVaultMnemonicViewBody()],
      ParentCreationStep.multisigParentExportQr => [const ParentMultisigParentExportQr()],
      ParentCreationStep.multisigParentList => [_buildMultisigParentListBody()],
      ParentCreationStep.childWalletSetup => [_buildChildWalletSetupBody()],
      ParentCreationStep.childWalletScan => [_buildChildWalletScanBody()],
      ParentCreationStep.childKeyPreparation => [_buildKeyPreparationBody(target: KeyPreparationTarget.child)],
      ParentCreationStep.childKeyImportOption => [
        _buildExistingKeyImportOptionBody(target: KeyPreparationTarget.child),
      ],
      ParentCreationStep.childCurrentVaultSelection => [Expanded(child: _buildChildExistingVaultSelectionBody())],
      ParentCreationStep.childWalletCreationOption => [_buildChildWalletCreationOptionBody()],
      ParentCreationStep.childSecuritySelfCheck => [
        SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: _addSelectedChildWalletCreationScreen),
      ],
      ParentCreationStep.childMnemonicEntry => [_buildChildMnemonicEntryBody()],
      ParentCreationStep.parentMnemonicConfirmation ||
      ParentCreationStep.childMnemonicConfirmation => [_buildMnemonicConfirmationBody()],
      ParentCreationStep.parentMnemonicGeneratedReview || ParentCreationStep.childMnemonicGeneratedReview => [
        _buildGeneratedMnemonicReviewBody(context.read<TaprootWalletCreationProvider>().secret),
      ],
      ParentCreationStep.parentMnemonicVerify || ParentCreationStep.childMnemonicVerify => [_buildMnemonicVerifyBody()],
      ParentCreationStep.parentVerifiedMnemonicConfirmation ||
      ParentCreationStep.childVerifiedMnemonicConfirmation => [_buildVerifiedMnemonicConfirmationBody()],
      ParentCreationStep.childWalletImported => _buildChildWalletImportedBody(),
      ParentCreationStep.timelockSetup => [_buildTimelockSetupBody(_timelockPickerToday ?? DateTime.now())],
      ParentCreationStep.vaultNameAndIconSetup => [_buildVaultNameAndIconSetupBody()],
      ParentCreationStep.timeline => [_buildTimelineBody()],
      ParentCreationStep.exportQr => [_buildExportQrBody()],
    };
  }

  VoidCallback? _getNextButtonAction(ParentCreationStep step) {
    return switch (step) {
      ParentCreationStep.intro => _moveToNextStep,
      ParentCreationStep.selectWalletType => _confirmWalletType,
      ParentCreationStep.multisigStartGuide => _onWalletTypeGuideConfirmed,
      ParentCreationStep.selectParentKeyPreparation => _onKeyPreparationTypeSelected,
      ParentCreationStep.selectParentKeyCreationOrImport => _onKeyCreationOrImportOptionSelected,
      ParentCreationStep.currentVaultSelection => _onCurrentVaultSelected,
      ParentCreationStep.multisigParentExportQr => _addMultisigListStep,
      ParentCreationStep.multisigParentList => _onMultisigParentsSet,
      ParentCreationStep.childWalletSetup => _onChildWalletSetupSelected,
      ParentCreationStep.childKeyPreparation => _onChildKeyPreparationTypeSelected,
      ParentCreationStep.childKeyImportOption => _onChildKeyImportOptionSelected,
      ParentCreationStep.childCurrentVaultSelection => _onChildCurrentVaultSelected,
      ParentCreationStep.childWalletCreationOption => _onChildWalletCreationOptionSelected,
      ParentCreationStep.parentMnemonicGeneratedReview ||
      ParentCreationStep.childMnemonicGeneratedReview => _addMnemonicVerifyStep,
      ParentCreationStep.childWalletImported => _addTimelockSetupStep,
      ParentCreationStep.timelockSetup => _addVaultNameAndIconSetupStep,
      ParentCreationStep.timeline => _addExportQrStep,
      ParentCreationStep.exportQr => _navigateToHome,
      _ => null,
    };
  }

  Widget? _getFixedBottomSubWidget(ParentCreationStep step) {
    if (step == ParentCreationStep.timeline) {
      return ParentCreationCompletionSteps.maybeLaterButton(onTap: _navigateToHome);
    }
    if (step == ParentCreationStep.childWalletImported && _childWalletSource == ParentChildWalletSource.scanned) {
      return CoconutUnderlinedButton(
        text: t.taproot.parent_creation_screen.step_2.import_again,
        onTap: _resetChildWalletAndReturnToPreviousStep,
      );
    }
    return null;
  }

  bool _shouldIgnoreBodyHorizontalPadding(ParentCreationStep step) {
    return switch (step) {
      ParentCreationStep.currentVaultSelection ||
      ParentCreationStep.childCurrentVaultSelection ||
      ParentCreationStep.parentSecuritySelfCheck ||
      ParentCreationStep.parentKeyImport ||
      ParentCreationStep.parentMnemonicEntry ||
      ParentCreationStep.parentMnemonicConfirmation ||
      ParentCreationStep.parentMnemonicGeneratedReview ||
      ParentCreationStep.parentMnemonicVerify ||
      ParentCreationStep.parentVerifiedMnemonicConfirmation ||
      ParentCreationStep.currentVaultMnemonicView ||
      ParentCreationStep.childWalletScan ||
      ParentCreationStep.childSecuritySelfCheck ||
      ParentCreationStep.childMnemonicEntry ||
      ParentCreationStep.childMnemonicConfirmation ||
      ParentCreationStep.childMnemonicGeneratedReview ||
      ParentCreationStep.childMnemonicVerify ||
      ParentCreationStep.childVerifiedMnemonicConfirmation ||
      ParentCreationStep.vaultNameAndIconSetup => true,
      _ => false,
    };
  }

  bool _shouldPauseProgress(ParentCreationStep step) {
    return _isEmbeddedStep(step) || step == ParentCreationStep.exportQr;
  }

  bool _shouldScrollChild(ParentCreationStep step) {
    return switch (step) {
      ParentCreationStep.currentVaultSelection || ParentCreationStep.childCurrentVaultSelection => false,
      _ => true,
    };
  }

  bool _isEmbeddedStep(ParentCreationStep step) {
    return switch (step) {
      ParentCreationStep.parentSecuritySelfCheck ||
      ParentCreationStep.parentKeyImport ||
      ParentCreationStep.parentMnemonicEntry ||
      ParentCreationStep.parentMnemonicConfirmation ||
      ParentCreationStep.parentMnemonicGeneratedReview ||
      ParentCreationStep.parentMnemonicVerify ||
      ParentCreationStep.parentVerifiedMnemonicConfirmation ||
      ParentCreationStep.currentVaultMnemonicView ||
      ParentCreationStep.childWalletScan ||
      ParentCreationStep.childSecuritySelfCheck ||
      ParentCreationStep.childMnemonicEntry ||
      ParentCreationStep.childMnemonicConfirmation ||
      ParentCreationStep.childMnemonicGeneratedReview ||
      ParentCreationStep.childMnemonicVerify ||
      ParentCreationStep.childVerifiedMnemonicConfirmation ||
      ParentCreationStep.vaultNameAndIconSetup => true,
      _ => false,
    };
  }

  Widget _buildIntroBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 64, top: 36, right: 64),
      child: Image.asset('assets/png/hand-bitcoin.png'),
    );
  }

  Widget _buildWalletTypeSelectionBody() {
    return Consumer<ParentCreationViewModel>(
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
    );
  }

  List<Widget> _buildMultisigStartGuideBody() {
    return [
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
  }

  Widget _buildKeyPreparationBody({KeyPreparationTarget target = KeyPreparationTarget.parent}) {
    return Consumer<ParentCreationViewModel>(
      builder: (context, viewModel, child) {
        final selectedType =
            target == KeyPreparationTarget.child
                ? viewModel.selectedChildKeyPreparationType
                : viewModel.selectedKeyPreparationType;
        void onSelected(ParentKeyPreparationType type) {
          if (target == KeyPreparationTarget.child) {
            viewModel.setChildKeyPreparationType(type);
            return;
          }

          viewModel.setKeyPreparationType(type);
        }

        return MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.common.prepare_key_option1_title,
              description: t.taproot.common.prepare_key_option1_desc,
              bottomAssetPath: 'assets/png/wallet.png',
              isSelected: selectedType == ParentKeyPreparationType.create,
              onTap: () => onSelected(ParentKeyPreparationType.create),
              imageScale: 3.8,
              height: 217,
            ),
            SelectableOptionCard(
              title: t.taproot.common.prepare_key_option2_title,
              description: t.taproot.common.prepare_key_option2_desc,
              bottomAssetPath: 'assets/png/key-holder.png',
              isSelected: selectedType == ParentKeyPreparationType.import,
              onTap: () => onSelected(ParentKeyPreparationType.import),
              imageScale: 3.8,
              height: 217,
            ),
          ],
        );
      },
    );
  }

  Widget _buildParentKeyCreationOrImportOptionBody() {
    return switch (_viewModel.selectedKeyPreparationType) {
      ParentKeyPreparationType.create => ParentNewKeyCreationOptionMenu(
        selectedType: (viewModel) => viewModel.selectedNewKeyCreationType,
        onSelected: (viewModel, type) => viewModel.setNewKeyCreationType(type),
      ),
      ParentKeyPreparationType.import => _buildExistingKeyImportOptionBody(),
      ParentKeyPreparationType.none => const SizedBox.shrink(),
    };
  }

  Widget _buildExistingKeyImportOptionBody({KeyPreparationTarget target = KeyPreparationTarget.parent}) {
    return Consumer<ParentCreationViewModel>(
      builder: (context, viewModel, child) {
        final hasNoSingleSigVault = context.select<WalletProvider, bool>(
          (walletProvider) => walletProvider.getVaultsByWalletType(WalletType.singleSignature).isEmpty,
        );
        final selectedType =
            target == KeyPreparationTarget.child
                ? viewModel.selectedChildExistingKeyImportType
                : viewModel.selectedExistingKeyImportType;

        void onSelected(ParentExistingKeyImportType type) {
          if (target == KeyPreparationTarget.child) {
            viewModel.setChildExistingKeyImportType(type);
            return;
          }

          viewModel.setExistingKeyImportType(type);
        }

        return MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.common.existing_option1,
              isDisabled: hasNoSingleSigVault,
              bottomAssetPath: 'assets/png/finger-picking.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: selectedType == ParentExistingKeyImportType.currentVault,
              height: 118,
              onDisabledTap: () {
                CoconutToast.showToast(
                  context: context,
                  level: CoconutToastLevel.info,
                  isVisibleIcon: true,
                  text: t.taproot.common.existing_option1_toast,
                );
              },
              onTap: () => onSelected(ParentExistingKeyImportType.currentVault),
            ),
            SelectableOptionCard(
              title: t.taproot.common.existing_option2,
              bottomAssetPath: 'assets/png/word.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: selectedType == ParentExistingKeyImportType.mnemonicInput,
              height: 118,
              onTap: () => onSelected(ParentExistingKeyImportType.mnemonicInput),
            ),
            SelectableOptionCard(
              title: t.taproot.common.existing_option3,
              bottomAssetPath: 'assets/png/scan-qr.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: selectedType == ParentExistingKeyImportType.seedQrScan,
              height: 118,
              onTap: () => onSelected(ParentExistingKeyImportType.seedQrScan),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentVaultMnemonicViewBody() {
    final selectedExistingVaultId = _viewModel.selectedExistingVaultId;
    if (selectedExistingVaultId == null) {
      return const SizedBox.shrink();
    }

    final mnemonicViewKey = _currentVaultMnemonicViewKey ??= GlobalKey<MnemonicViewScreenState>();
    if (!_currentVaultMnemonicAuthRequested) {
      _currentVaultMnemonicAuthRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentStepType != ParentCreationStep.currentVaultMnemonicView) {
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

    return TaprootMnemonicViewFlowAdapter.buildMnemonicViewStep(
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
    );
  }

  Widget _buildParentExistingVaultSelectionBody() {
    return ParentExistingVaultSelectionBody(
      selectedVaultId: (viewModel) => viewModel.selectedExistingVaultId,
      onSelected: (viewModel, vaultId) => viewModel.setSelectedExistingVaultId(vaultId),
    );
  }

  Widget _buildChildExistingVaultSelectionBody() {
    return ParentExistingVaultSelectionBody(
      selectedVaultId: (viewModel) => viewModel.selectedChildExistingVaultId,
      onSelected: (viewModel, vaultId) => viewModel.setSelectedChildExistingVaultId(vaultId),
    );
  }

  Widget _buildChildCurrentVaultMnemonicViewBody() {
    final selectedExistingVaultId = _viewModel.selectedChildExistingVaultId;
    if (selectedExistingVaultId == null) {
      return const SizedBox.shrink();
    }

    final mnemonicViewKey = _currentVaultMnemonicViewKey ??= GlobalKey<MnemonicViewScreenState>();
    if (!_currentVaultMnemonicAuthRequested) {
      _currentVaultMnemonicAuthRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentStepType != ParentCreationStep.childMnemonicEntry) {
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

    return TaprootMnemonicViewFlowAdapter.buildMnemonicViewStep(
      mnemonicViewKey: mnemonicViewKey,
      walletId: selectedExistingVaultId,
      buildPassphraseToggle: true,
      emptyPassphraseAsNull: false,
      onAuthCanceled: _returnToPreviousStep,
      onMnemonicReady: _onCurrentVaultChildMnemonicReady,
    );
  }

  Widget _buildMultisigParentListBody() {
    return ParentMultisigParentList(
      activeColor: _parentWalletActiveColor,
      onCurrentWalletPressed: _showMultisigParentExportBottomSheet,
      onExternalWalletPressed: _showMultisigParentScannerBottomSheet,
    );
  }

  Widget _buildChildWalletSetupBody() {
    return Consumer<ParentCreationViewModel>(
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
    );
  }

  Widget _buildChildWalletScanBody() {
    final guideText = Text(
      '${t.taproot.parent_creation_screen.step_2.import_scanner_title_1}\n'
      '${t.taproot.parent_creation_screen.step_2.import_scanner_title_2}',
      style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.white),
      textAlign: TextAlign.center,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
        return SizedBox(
          height: height,
          child: TaprootScannerScreen(
            topGuideWidget: Positioned(top: 80, left: 24, right: 24, child: guideText),
            onTaprootVaultScanned:
                (beneficiaryVault) => _onChildWalletImported(beneficiaryVault, source: ParentChildWalletSource.scanned),
          ),
        );
      },
    );
  }

  Widget _buildChildWalletCreationOptionBody() {
    return ParentNewKeyCreationOptionMenu(
      selectedType: (viewModel) => viewModel.selectedChildNewKeyCreationType,
      onSelected: (viewModel, type) => viewModel.setChildNewKeyCreationType(type),
    );
  }

  Widget _buildChildMnemonicEntryBody() {
    return switch (_viewModel.selectedChildKeyPreparationType) {
      ParentKeyPreparationType.create =>
        _buildNewMnemonicCreationScreen(_viewModel.selectedChildNewKeyCreationType) ?? const SizedBox.shrink(),
      ParentKeyPreparationType.import => switch (_viewModel.selectedChildExistingKeyImportType) {
        ParentExistingKeyImportType.currentVault => _buildChildCurrentVaultMnemonicViewBody(),
        ParentExistingKeyImportType.mnemonicInput => TaprootMnemonicFlowAdapter.buildMnemonicImportScreen(
          key: const ValueKey('parent-creation-child-mnemonic-import'),
          onMnemonicConfirmationRequested: _onImportedChildMnemonicReady,
        ),
        ParentExistingKeyImportType.seedQrScan => _buildSeedQrImportScreen(
          key: const ValueKey('parent-creation-child-seed-qr-import'),
          onMnemonicScanned: _validateScannedChildSeedQrMnemonic,
          onMnemonicConfirmationRequested: _onSeedQrChildMnemonicReady,
        ),
        ParentExistingKeyImportType.none => const SizedBox.shrink(),
      },
      ParentKeyPreparationType.none => const SizedBox.shrink(),
    };
  }

  Widget _buildMnemonicConfirmationBody() {
    if (_currentStepType == ParentCreationStep.childMnemonicConfirmation &&
        _viewModel.selectedChildKeyPreparationType == ParentKeyPreparationType.import) {
      return TaprootMnemonicFlowAdapter.buildImportedConfirmationScreen(onMnemonicReady: _onCreatedChildWalletReady);
    }

    final selectedCreationType =
        _isCreatingChildWallet ? _viewModel.selectedChildNewKeyCreationType : _viewModel.selectedNewKeyCreationType;
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(selectedCreationType);
    if (mnemonicCreationMethod == null) {
      return const SizedBox.shrink();
    }

    return TaprootMnemonicFlowAdapter.buildCreationConfirmationScreen(
      method: mnemonicCreationMethod,
      onMnemonicReady: _addMnemonicVerifyStep,
    );
  }

  Widget _buildMnemonicVerifyBody() {
    return TaprootMnemonicFlowAdapter.buildVerifyScreen(onVerificationSuccess: _addVerifiedMnemonicConfirmationStep);
  }

  Widget _buildVerifiedMnemonicConfirmationBody() {
    return TaprootMnemonicFlowAdapter.buildVerifiedConfirmationScreen(
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

  List<Widget> _buildChildWalletImportedBody() {
    final childWalletMasterFingerprint = _viewModel.childWalletMasterFingerprint ?? '';
    return [
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
  }

  Widget _buildVaultNameAndIconSetupBody() {
    return VaultNameAndIconSetupScreen(
      isEmbedded: true,
      isTaproot: true,
      taprootVaultSaveHandler: ({required name, required iconIndex, required colorIndex}) async {
        final result = await _viewModel.saveVault(name: name, iconIndex: iconIndex, colorIndex: colorIndex);
        return VaultNameAndIconSetupSaveResult.navigateToHome(
          addedWalletId: result.vaultId,
          taprootTimelineInfo: result.timelineInfo,
        );
      },
      onEmbeddedVaultSaved: _addTimelineStep,
    );
  }

  Widget _buildTimelineBody() {
    return ParentCreationCompletionSteps.timelineIndicator(
      parentWalletType: _viewModel.selectedWalletType,
      timelineInfo: _timelineInfo,
      timelockDateTimeText: ParentTimelockSetupBody.dateTimeText(_viewModel.selectedTimelockDateTime),
      onCompleted: _handleTimelineAnimationCompleted,
    );
  }

  Widget _buildExportQrBody() {
    final addedWalletId = _createdTaprootVaultId;
    if (addedWalletId == null) {
      return const SizedBox.shrink();
    }

    final qrData = _viewModel.getWalletSyncString(addedWalletId);
    return ParentCreationCompletionSteps.exportQrBody(qrData: qrData);
  }

  VoidCallback? get _onNextPressed {
    if (!_canRunCurrentStepAction) {
      return null;
    }

    return _getNextButtonAction(_currentStepType);
  }

  bool get _showBottomButton {
    return _onNextPressed != null &&
        (_currentStep <= _initialStepCount || _isTitleAnimationCompleted) &&
        (!_isTimelineStep || _isTimelineAnimationCompleted);
  }

  bool get _runBottomButtonActionWithoutTransition {
    return _currentStepType == ParentCreationStep.childWalletSetup &&
        _viewModel.selectedChildWalletSetupType == ChildWalletSetupType.create;
  }

  bool get _isTimelineStep => _currentStepType == ParentCreationStep.timeline;

  bool get _isExportQrStep => _currentStepType == ParentCreationStep.exportQr;

  bool get _showExistingKeyImportModeToggle {
    return (_currentStepType == ParentCreationStep.parentKeyImport &&
            _viewModel.selectedKeyPreparationType == ParentKeyPreparationType.import &&
            (_viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput ||
                _viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.seedQrScan)) ||
        (_currentStepType == ParentCreationStep.childMnemonicEntry &&
            _viewModel.selectedChildKeyPreparationType == ParentKeyPreparationType.import &&
            (_viewModel.selectedChildExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput ||
                _viewModel.selectedChildExistingKeyImportType == ParentExistingKeyImportType.seedQrScan));
  }

  ParentExistingKeyImportType get _currentExistingKeyImportType {
    return _currentStepType == ParentCreationStep.childMnemonicEntry
        ? _viewModel.selectedChildExistingKeyImportType
        : _viewModel.selectedExistingKeyImportType;
  }

  bool get _canRunCurrentStepAction {
    return switch (_currentStepType) {
      ParentCreationStep.intro => true,
      ParentCreationStep.selectWalletType => _viewModel.selectedWalletType != ParentWalletType.none,
      ParentCreationStep.multisigStartGuide => true,
      ParentCreationStep.selectParentKeyPreparation =>
        _viewModel.selectedKeyPreparationType != ParentKeyPreparationType.none,
      ParentCreationStep.selectParentKeyCreationOrImport => _viewModel.hasSelectedKeyCreationOrImportOption,
      ParentCreationStep.currentVaultSelection => _viewModel.selectedExistingVaultId != null,
      ParentCreationStep.multisigParentList => _viewModel.externalParentSignerBsms != null,
      ParentCreationStep.childWalletSetup => _viewModel.selectedChildWalletSetupType != ChildWalletSetupType.none,
      ParentCreationStep.childKeyPreparation =>
        _viewModel.selectedChildKeyPreparationType != ParentKeyPreparationType.none,
      ParentCreationStep.childKeyImportOption =>
        _viewModel.selectedChildExistingKeyImportType != ParentExistingKeyImportType.none,
      ParentCreationStep.childCurrentVaultSelection => _viewModel.selectedChildExistingVaultId != null,
      ParentCreationStep.childWalletCreationOption =>
        _viewModel.selectedChildNewKeyCreationType != ParentNewKeyCreationType.none,
      ParentCreationStep.timelockSetup => _viewModel.selectedTimelockDateTime != null,
      _ => true,
    };
  }

  bool get _isProgressPaused => _shouldPauseProgress(_currentStepType);

  bool get _showHeader {
    return !_isProgressPaused || _isExportQrStep;
  }

  int get _progressCurrentStep {
    return (_stepHistory.take(_currentStep).where((step) => !_shouldPauseProgress(step)).length -
            _progressInitialStepCount)
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
      'Current Step: $_currentStep, Built Step: ${_stepHistory.length}, '
      'Progress Total Step: ${_viewModel.progressTotalStep}',
    );
    if (!_hasNextBuiltStep) {
      return;
    }

    _moveToStep(_stepHistory[_currentStep]);
  }

  void _moveToStep(ParentCreationStep step) {
    final existingIndex = _stepIndexOf(step);
    if (existingIndex >= 0) {
      setState(() {
        _currentStep = existingIndex + 1;
      });
      _scheduleTitleAnimationCompletion();
      return;
    }

    switch (step) {
      case ParentCreationStep.selectParentKeyPreparation:
        _onWalletTypeGuideConfirmed();
        return;
      case ParentCreationStep.selectParentKeyCreationOrImport:
        _onKeyPreparationTypeSelected();
        return;
      case ParentCreationStep.currentVaultSelection:
        _addCurrentVaultSelectionStep();
        return;
      case ParentCreationStep.childWalletSetup:
        _addChildWalletSetupStep();
        return;
      case ParentCreationStep.childWalletScan:
        _addChildWalletScanStep();
        return;
      case ParentCreationStep.childKeyPreparation:
        _addChildKeyPreparationStep();
        return;
      case ParentCreationStep.childKeyImportOption:
        _addChildKeyImportOptionStep();
        return;
      case ParentCreationStep.childCurrentVaultSelection:
        _addStep(ParentCreationStep.childCurrentVaultSelection);
        return;
      case ParentCreationStep.childWalletCreationOption:
        _addChildWalletCreationOptionStep();
        return;
      case ParentCreationStep.timelockSetup:
        _addTimelockSetupStep();
        return;
      case ParentCreationStep.vaultNameAndIconSetup:
        _addVaultNameAndIconSetupStep();
        return;
      case ParentCreationStep.exportQr:
        _addExportQrStep();
        return;
      case ParentCreationStep.multisigParentExportQr:
        _addMultisigParentExportStep();
        return;
      case ParentCreationStep.multisigParentList:
        _addMultisigListStep();
        return;
      default:
        return;
    }
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
    _addStep(ParentCreationStep.multisigStartGuide);
  }

  int _addStep(ParentCreationStep step) {
    return _appendStep(step);
  }

  int _appendStep(ParentCreationStep step) {
    final addedStep = _stepHistory.length + 1;
    setState(() {
      _stepHistory.add(step);
      _currentStep = addedStep;
    });
    _scheduleTitleAnimationCompletion();
    return addedStep;
  }

  bool _isValidStepIndex(int? step) {
    return step != null && step >= 1 && step <= _stepHistory.length;
  }

  void _removeStepsAfter(int targetStep) {
    while (_stepHistory.length > targetStep) {
      _stepHistory.removeLast();
    }

    if ((_parentKeyImportStep ?? 0) > targetStep) {
      _parentKeyImportStep = null;
    }
    if ((_multisigParentImportStep ?? 0) > targetStep) {
      _multisigParentImportStep = null;
    }
    if ((_multisigParentListStep ?? 0) > targetStep) {
      _multisigParentListStep = null;
    }
    if ((_childWalletSetupStep ?? 0) > targetStep) {
      _childWalletSetupStep = null;
    }
    if ((_childKeyPreparationStep ?? 0) > targetStep) {
      _childKeyPreparationStep = null;
    }
    if ((_childWalletImportedStep ?? 0) > targetStep) {
      _childWalletImportedStep = null;
    }
  }

  void _onWalletTypeGuideConfirmed() {
    _keyPreparationStep = _addStep(ParentCreationStep.selectParentKeyPreparation);
  }

  void _onKeyPreparationTypeSelected() {
    if (_viewModel.selectedKeyPreparationType == ParentKeyPreparationType.none) {
      return;
    }

    _keyCreationOrImportOptionStep = _addStep(ParentCreationStep.selectParentKeyCreationOrImport);
  }

  void _onKeyCreationOrImportOptionSelected() {
    if (_viewModel.selectedKeyPreparationType == ParentKeyPreparationType.create) {
      _addEmbeddedStep(
        step: ParentCreationStep.parentSecuritySelfCheck,
        embeddedScreen: SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: _addSelectedKeyCreationOrImportScreen),
      );
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
        step: ParentCreationStep.parentKeyImport,
        embeddedScreen: Consumer<ParentCreationViewModel>(
          builder: (context, viewModel, child) {
            return _buildSelectedKeyCreationOrImportEmbeddedScreen() ?? const SizedBox.shrink();
          },
        ),
      );
      return;
    }

    _addEmbeddedStep(step: ParentCreationStep.parentMnemonicEntry, embeddedScreen: embeddedScreen);
  }

  void _toggleExistingKeyImportMode() {
    final currentType = _currentExistingKeyImportType;
    final nextType = switch (currentType) {
      ParentExistingKeyImportType.mnemonicInput => ParentExistingKeyImportType.seedQrScan,
      ParentExistingKeyImportType.seedQrScan => ParentExistingKeyImportType.mnemonicInput,
      _ => ParentExistingKeyImportType.mnemonicInput,
    };

    if (_currentStepType == ParentCreationStep.childMnemonicEntry) {
      _viewModel.setChildExistingKeyImportType(nextType);
      return;
    }

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
      addEmbeddedStep:
          (widget) => _addEmbeddedStep(
            step:
                _isCreatingChildWallet
                    ? ParentCreationStep.childMnemonicConfirmation
                    : ParentCreationStep.parentMnemonicConfirmation,
            embeddedScreen: widget,
          ),
      method: mnemonicCreationMethod,
      onMnemonicReady: _addMnemonicVerifyStep,
      onAutoGenerateReady: _addMnemonicVerifyStep,
    );
    if (confirmationStep != -1) {
      _mnemonicConfirmationStep = confirmationStep;
    }
  }

  void _addImportedChildMnemonicConfirmationStep() {
    _mnemonicConfirmationStep = TaprootMnemonicFlowAdapter.addImportedConfirmationStep(
      addEmbeddedStep:
          (widget) => _addEmbeddedStep(step: ParentCreationStep.childMnemonicConfirmation, embeddedScreen: widget),
      onMnemonicReady: _onCreatedChildWalletReady,
    );
  }

  void _addMnemonicVerifyStep() {
    if (_mnemonicConfirmationStep == null && _isAutoGenerateMnemonicFlow) {
      _mnemonicGeneratedReviewStep = _currentStep;
    }

    _mnemonicVerifyStep = TaprootMnemonicFlowAdapter.addVerifyStep(
      addEmbeddedStep:
          (widget) => _addEmbeddedStep(
            step:
                _isCreatingChildWallet
                    ? ParentCreationStep.childMnemonicVerify
                    : ParentCreationStep.parentMnemonicVerify,
            embeddedScreen: widget,
          ),
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
      addEmbeddedStep:
          (widget) => _addEmbeddedStep(
            step:
                _isCreatingChildWallet
                    ? ParentCreationStep.childVerifiedMnemonicConfirmation
                    : ParentCreationStep.parentVerifiedMnemonicConfirmation,
            embeddedScreen: widget,
          ),
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

  int _addEmbeddedStep({required ParentCreationStep step, required Widget embeddedScreen}) {
    return _addStep(step);
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
          ParentExistingKeyImportType.seedQrScan => _buildSeedQrImportScreen(
            key: const ValueKey('parent-creation-seed-qr-import'),
            onMnemonicConfirmationRequested: _onImportedParentMnemonicReady,
          ),
          ParentExistingKeyImportType.none => null,
        };
      case ParentKeyPreparationType.none:
        return null;
    }
  }

  Widget _buildSeedQrImportScreen({
    Key? key,
    TaprootScannedMnemonicCallback? onMnemonicScanned,
    required TaprootImportedMnemonicCallback onMnemonicConfirmationRequested,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
        return SizedBox(
          height: height,
          child: TaprootMnemonicFlowAdapter.buildSeedQrImportScreen(
            key: key,
            onMnemonicScanned: onMnemonicScanned,
            onMnemonicConfirmationRequested: onMnemonicConfirmationRequested,
          ),
        );
      },
    );
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

  void _onImportedChildMnemonicReady(Uint8List secret, Uint8List? passphrase) {
    _setImportedChildMnemonic(secret, passphrase);
    _addImportedChildMnemonicConfirmationStep();
  }

  Future<bool> _validateScannedChildSeedQrMnemonic(Uint8List secret) async {
    if (!_viewModel.isSameAsParentMnemonicSecret(secret)) {
      return true;
    }

    await _showSameChildWalletAsParentDialog(ParentChildWalletSource.created);
    return false;
  }

  void _onCurrentVaultChildMnemonicReady(Uint8List secret, Uint8List? passphrase) {
    _setImportedChildMnemonic(secret, passphrase);
    _onCreatedChildWalletReady();
  }

  void _onSeedQrChildMnemonicReady(Uint8List secret, Uint8List? passphrase) {
    _setImportedChildMnemonic(secret, passphrase);
    Future<void>.delayed(Duration.zero, () {
      if (!mounted) {
        return;
      }

      _onCreatedChildWalletReady();
    });
  }

  void _setImportedChildMnemonic(Uint8List secret, Uint8List? passphrase) {
    final taprootWalletCreationProvider = context.read<TaprootWalletCreationProvider>();
    taprootWalletCreationProvider.setCreationType(TaprootCreationType.child);
    taprootWalletCreationProvider.setSecretAndPassphrase(secret, passphrase);
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
    _addStep(ParentCreationStep.currentVaultSelection);
  }

  Future<void> _onCurrentVaultSelected() async {
    final selectedExistingVaultId = _viewModel.selectedExistingVaultId;
    if (selectedExistingVaultId == null) {
      return;
    }

    final confirmed = await ParentCreationOverlays.showCurrentVaultConfirmDialog(context);
    if (confirmed == true && mounted) {
      _proceedWithSelectedVault();
    }
  }

  void _proceedWithSelectedVault() {
    if (!mounted) return;

    _currentVaultMnemonicViewKey = GlobalKey<MnemonicViewScreenState>();
    _currentVaultMnemonicAuthRequested = false;
    _addEmbeddedStep(step: ParentCreationStep.currentVaultMnemonicView, embeddedScreen: const SizedBox.shrink());
  }

  Future<void> _onChildCurrentVaultSelected() async {
    final selectedExistingVaultId = _viewModel.selectedChildExistingVaultId;
    if (selectedExistingVaultId == null) {
      return;
    }

    final confirmed = await ParentCreationOverlays.showCurrentVaultConfirmDialog(context);
    if (confirmed == true && mounted) {
      _proceedWithSelectedChildVault();
    }
  }

  void _proceedWithSelectedChildVault() {
    if (!mounted) return;

    _currentVaultMnemonicViewKey = GlobalKey<MnemonicViewScreenState>();
    _currentVaultMnemonicAuthRequested = false;
    _addEmbeddedStep(step: ParentCreationStep.childMnemonicEntry, embeddedScreen: const SizedBox.shrink());
  }

  /// STEP 2: 부모 지갑 설정 완료 -> 자식 지갑 설정 차례 진입
  void _onParentWalletSet(Uint8List secret, {Uint8List? passphrase}) {
    _setParentWalletSecret(secret, passphrase: passphrase);
    _addChildWalletSetupStep();
  }

  void _onMultisigParentsSet() {
    _addChildWalletSetupStep();
  }

  void _addChildWalletSetupStep() {
    _childWalletSetupStep = _addStep(ParentCreationStep.childWalletSetup);
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
    _addEmbeddedStep(step: ParentCreationStep.childWalletScan, embeddedScreen: const SizedBox.shrink());
  }

  void _startChildWalletCreationFlow() {
    _isCreatingChildWallet = true;
    _viewModel.resetChildKeyPreparationType();
    _viewModel.resetChildNewKeyCreationType();
    _viewModel.resetChildWallet();
    _addChildKeyPreparationStep();
  }

  void _addChildKeyPreparationStep() {
    _childKeyPreparationStep = _addStep(ParentCreationStep.childKeyPreparation);
  }

  void _addChildWalletCreationOptionStep() {
    _addStep(ParentCreationStep.childWalletCreationOption);
  }

  void _addChildKeyImportOptionStep() {
    _addStep(ParentCreationStep.childKeyImportOption);
  }

  void _onChildKeyPreparationTypeSelected() {
    switch (_viewModel.selectedChildKeyPreparationType) {
      case ParentKeyPreparationType.create:
        _addChildWalletCreationOptionStep();
        return;
      case ParentKeyPreparationType.import:
        _addChildKeyImportOptionStep();
        return;
      case ParentKeyPreparationType.none:
        return;
    }
  }

  void _onChildKeyImportOptionSelected() {
    switch (_viewModel.selectedChildExistingKeyImportType) {
      case ParentExistingKeyImportType.currentVault:
        _addStep(ParentCreationStep.childCurrentVaultSelection);
        return;
      case ParentExistingKeyImportType.mnemonicInput || ParentExistingKeyImportType.seedQrScan:
        _addEmbeddedStep(step: ParentCreationStep.childMnemonicEntry, embeddedScreen: const SizedBox.shrink());
        return;
      case ParentExistingKeyImportType.none:
        return;
    }
  }

  List<TextSpan> _newWalletCreationOptionTitleList() {
    return [TextSpan(text: t.taproot.common.create_new_wallet_title)];
  }

  void _onChildWalletCreationOptionSelected() {
    if (_viewModel.selectedChildNewKeyCreationType == ParentNewKeyCreationType.none) {
      return;
    }

    _addEmbeddedStep(
      step: ParentCreationStep.childSecuritySelfCheck,
      embeddedScreen: SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: _addSelectedChildWalletCreationScreen),
    );
  }

  void _addSelectedChildWalletCreationScreen() {
    final embeddedScreen = _buildNewMnemonicCreationScreen(_viewModel.selectedChildNewKeyCreationType);
    if (embeddedScreen == null) {
      return;
    }

    _addEmbeddedStep(step: ParentCreationStep.childMnemonicEntry, embeddedScreen: embeddedScreen);
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
    final setResult = _viewModel.trySetChildWallet(
      beneficiaryVault: beneficiaryVault,
      source: source,
      secret: secret,
      passphrase: passphrase,
    );
    if (setResult == ParentChildWalletSetResult.sameAsParent) {
      _showSameChildWalletAsParentDialog(source);
      return false;
    }

    _childWalletSource = source;
    _childWalletImportedStep = _addStep(ParentCreationStep.childWalletImported);
    return true;
  }

  void _addTimelockSetupStep() {
    _resetTimelockDate();
    _timelockPickerToday = DateTime.now();

    _addStep(ParentCreationStep.timelockSetup);
  }

  Future<void> _addVaultNameAndIconSetupStep() async {
    if (_isCheckingDuplicateWallet) {
      return;
    }

    _setCheckingDuplicateWallet(true);

    try {
      final sameWalletName = await _viewModel.findSameWalletName();
      if (!mounted) {
        return;
      }

      _setCheckingDuplicateWallet(false);

      if (sameWalletName != null) {
        await ParentCreationOverlays.showDuplicateWalletDialog(context, sameWalletName);
        return;
      }

      if (!mounted) {
        return;
      }

      _addEmbeddedStep(step: ParentCreationStep.vaultNameAndIconSetup, embeddedScreen: const SizedBox.shrink());
    } finally {
      _setCheckingDuplicateWallet(false);
    }
  }

  void _setCheckingDuplicateWallet(bool isChecking) {
    if (!mounted || _isCheckingDuplicateWallet == isChecking) {
      return;
    }

    setState(() {
      _isCheckingDuplicateWallet = isChecking;
    });
  }

  void _addTimelineStep(VaultNameAndIconSetupSaveResult result) {
    _createdTaprootVaultId = result.addedWalletId;
    _timelineInfo = result.taprootTimelineInfo;
    _isTimelineAnimationCompleted = false;

    _addStep(ParentCreationStep.timeline);
  }

  void _addExportQrStep() {
    final addedWalletId = _createdTaprootVaultId;
    if (addedWalletId == null) {
      return;
    }

    _addStep(ParentCreationStep.exportQr);
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
        });
      },
    );
  }

  Future<void> _showSameChildWalletAsParentDialog(ParentChildWalletSource source) {
    if (_isDuplicateChildWalletDialogVisible) {
      return Future<void>.value();
    }

    _isDuplicateChildWalletDialogVisible = true;
    return ParentCreationOverlays.showSameChildWalletAsParentDialog(
      context,
      description: _sameChildWalletAsParentDialogDescription(source),
    ).whenComplete(() => _isDuplicateChildWalletDialogVisible = false);
  }

  String _sameChildWalletAsParentDialogDescription(ParentChildWalletSource source) {
    final step2 = t.taproot.parent_creation_screen.step_2;
    if (source == ParentChildWalletSource.scanned) {
      return step2.same_child_wallet_as_parent_dialog_description_scan;
    }

    if (_viewModel.selectedChildKeyPreparationType != ParentKeyPreparationType.import) {
      return step2.same_child_wallet_as_parent_dialog_description_enter;
    }

    return switch (_viewModel.selectedChildExistingKeyImportType) {
      ParentExistingKeyImportType.currentVault => step2.same_child_wallet_as_parent_dialog_description_select,
      ParentExistingKeyImportType.mnemonicInput => step2.same_child_wallet_as_parent_dialog_description_enter,
      ParentExistingKeyImportType.seedQrScan => step2.same_child_wallet_as_parent_dialog_description_scan,
      ParentExistingKeyImportType.none => step2.same_child_wallet_as_parent_dialog_description_enter,
    };
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
    _multisigParentImportStep = _addStep(ParentCreationStep.multisigParentExportQr);
  }

  void _addMultisigListStep() {
    _multisigParentListStep = _addStep(ParentCreationStep.multisigParentList);
  }

  void _showMultisigParentExportBottomSheet() {
    ParentCreationOverlays.showMultisigParentExportBottomSheet(context, qrData: _viewModel.parentWalletQrData);
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
    if (!_isValidStepIndex(targetStep)) {
      return false;
    }

    if (_currentStep != _mnemonicVerifyStep && _currentStep != _verifiedMnemonicConfirmationStep) {
      return false;
    }

    setState(() {
      _removeStepsAfter(targetStep!);
      _currentStep = targetStep;
      _mnemonicVerifyStep = null;
      _verifiedMnemonicConfirmationStep = null;
    });
    _scheduleTitleAnimationCompletion();
    return true;
  }

  bool _returnToGeneratedMnemonicReviewStepIfNeeded() {
    final targetStep = _mnemonicGeneratedReviewStep;
    if (!_isValidStepIndex(targetStep)) {
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
      _removeStepsAfter(targetStep!);
      _stepHistory[targetStep - 1] =
          _isCreatingChildWallet
              ? ParentCreationStep.childMnemonicGeneratedReview
              : ParentCreationStep.parentMnemonicGeneratedReview;
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
    if (!_isValidStepIndex(targetStep)) {
      _returnToPreviousStep();
      return;
    }

    if (resetParentWallet) {
      _viewModel.resetParentWalletData();
    }

    setState(() {
      _removeStepsAfter(targetStep!);
      _currentStep = targetStep;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childKeyPreparationStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      _viewModel.resetChildKeyPreparationType();
    });
    _resetSelectionForBackNavigation();
    _scheduleTitleAnimationCompletion();
  }

  void _returnToChildWalletSetupStep() {
    final targetStep = _childWalletSetupStep;
    if (!_isValidStepIndex(targetStep)) {
      _returnToPreviousStep();
      return;
    }

    setState(() {
      _removeStepsAfter(targetStep!);
      _currentStep = targetStep;
      _childWalletImportedStep = null;
      _childKeyPreparationStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      _viewModel.resetChildKeyPreparationType();
      _viewModel.resetChildNewKeyCreationType();
    });
    _scheduleTitleAnimationCompletion();
  }

  void _returnToPreviousStep() {
    if (_currentStep <= 1) {
      return;
    }

    final previousStep = _currentStep;
    final previousStepType = _currentStepType;
    setState(() {
      if (_currentStep <= _initialStepCount) {
        _currentStep -= 1;
        return;
      }

      final currentStepIndex = _currentStep - 1;
      _stepHistory.removeAt(currentStepIndex);
      if (_currentStep == _parentKeyImportStep) {
        _parentKeyImportStep = null;
      }
      _currentStep -= 1;
    });
    _resetSelectionForBackNavigation(previousStep: previousStep, previousStepType: previousStepType);
    _scheduleTitleAnimationCompletion();
  }

  void _resetSelectionForBackNavigation({int? previousStep, ParentCreationStep? previousStepType}) {
    if (_currentStep <= 2 || previousStep == 2) {
      _viewModel.resetSelection(ParentSelectionResetScope.walletType);
      _keyPreparationStep = null;
      _keyCreationOrImportOptionStep = null;
      _parentKeyImportStep = null;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childKeyPreparationStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      _viewModel.resetChildKeyPreparationType();
      return;
    }

    if (_currentStep == _keyPreparationStep || previousStep == _keyPreparationStep) {
      _viewModel.resetSelection(ParentSelectionResetScope.keyPreparation);
      _keyCreationOrImportOptionStep = null;
      _parentKeyImportStep = null;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childKeyPreparationStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      _viewModel.resetChildKeyPreparationType();
      return;
    }

    if (_currentStep == _keyCreationOrImportOptionStep || previousStep == _keyCreationOrImportOptionStep) {
      _viewModel.resetSelection(ParentSelectionResetScope.keyCreationOrImportOption);
      _parentKeyImportStep = null;
      _multisigParentImportStep = null;
      _multisigParentListStep = null;
      _childWalletSetupStep = null;
      _childKeyPreparationStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      _viewModel.resetChildKeyPreparationType();
      return;
    }

    if (_currentStep == _childWalletSetupStep || previousStep == _childWalletSetupStep) {
      _childKeyPreparationStep = null;
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _isCreatingChildWallet = false;
      _viewModel.setChildWalletSetupType(ChildWalletSetupType.none);
      _viewModel.resetChildKeyPreparationType();
      return;
    }

    if (_currentStep == _childKeyPreparationStep || previousStep == _childKeyPreparationStep) {
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _viewModel.resetChildKeyPreparationType();
      return;
    }

    if (_currentStepType == ParentCreationStep.childKeyImportOption ||
        previousStepType == ParentCreationStep.childKeyImportOption) {
      _childWalletImportedStep = null;
      _resetMnemonicStepIndexes();
      _viewModel.resetChildExistingKeyImportType();
    }

    if (previousStepType == ParentCreationStep.timelockSetup) {
      _resetTimelockDate();
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
                      _currentExistingKeyImportType == ParentExistingKeyImportType.mnemonicInput
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
                  fixedBottomSubWidget: _getFixedBottomSubWidget(_currentStepType),
                  runBottomButtonActionWithoutTransition: _runBottomButtonActionWithoutTransition,
                  keepHeaderVisibleDuringTransition: _isTimelineStep,
                  animateHeader: !_isExportQrStep,
                  showBottomButton: _showBottomButton,
                  ignoreChildHorizontalPadding: _shouldIgnoreBodyHorizontalPadding(_currentStepType),
                  showHeader: _showHeader,
                  scrollChild: !_isProgressPaused && _shouldScrollChild(_currentStepType),
                  child:
                      _isProgressPaused
                          ? _getBodyList(_currentStepType).first
                          : Column(children: _getBodyList(_currentStepType)),
                ),
                TopProgressBar(
                  visible: !_isProgressPaused,
                  total: _viewModel.progressTotalStep,
                  current: _progressCurrentStep,
                ),
                if (_isCheckingDuplicateWallet)
                  const Positioned.fill(child: CoconutLoadingOverlay(applyFullScreen: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
