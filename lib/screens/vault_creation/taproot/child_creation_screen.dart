import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_overlays.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/child_creation_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/mnemonic_view_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/child_creation_overlays.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/child_creation_step_widgets.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_mnemonic_flow_adapter.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_mnemonic_view_flow_adapter.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_scanner_screen.dart';
import 'package:coconut_vault/utils/vibration_util.dart';

class ChildCreationScreen extends StatelessWidget {
  const ChildCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) =>
              ChildCreationViewModel(context.read<TaprootWalletCreationProvider>(), context.read<WalletProvider>()),
      child: const _ChildCreationScreenContent(),
    );
  }
}

class _ChildCreationScreenContent extends StatefulWidget {
  const _ChildCreationScreenContent();

  @override
  State<_ChildCreationScreenContent> createState() => _ChildCreationScreenContentState();
}

enum ChildCreationStep {
  intro,
  childPreparation,
  childCreationOption,
  securitySelfCheck,
  mnemonicCreation,
  mnemonicImport,
  seedQrImport,
  currentVaultSelection,
  currentVaultMnemonicView,
  mnemonicConfirmation,
  importedMnemonicConfirmation,
  mnemonicVerify,
  verifiedMnemonicConfirmation,
  childWalletQr,
  scanner,
  summary,
  timeline,
}

class _ChildCreationScreenContentState extends State<_ChildCreationScreenContent> {
  static const int _initialStepCount = 2;
  static const int _progressInitialStepCount = 1;

  int _currentStep = 1;
  final List<ChildCreationStep> _stepHistory = [ChildCreationStep.intro, ChildCreationStep.childPreparation];
  int? _childWalletQrStep;
  int? _scannerStep;
  GlobalKey<MnemonicViewScreenState>? _currentVaultMnemonicViewKey;
  bool _isProcessing = false;
  bool _currentVaultMnemonicAuthRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChildCreationViewModel>().resetChildWalletData();
      }
    });
  }

  ChildCreationStep get _currentStepType => _stepHistory[_currentStep - 1];

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

  List<TextSpan> _getTitleList(ChildCreationStep step) {
    final viewModel = context.read<ChildCreationViewModel>();
    return switch (step) {
      ChildCreationStep.intro => [
        TextSpan(text: t.taproot.child_creation_screen.step1.title1),
        TextSpan(text: t.taproot.child_creation_screen.step1.title2),
      ],
      ChildCreationStep.childPreparation => [
        TextSpan(text: t.taproot.child_creation_screen.step2.title1),
        TextSpan(text: t.taproot.child_creation_screen.step2.title2),
      ],
      ChildCreationStep.childCreationOption =>
        viewModel.keyPreparationType == ChildKeyPreparationType.create
            ? [TextSpan(text: t.taproot.child_creation_screen.step3.title_new)]
            : [TextSpan(text: t.taproot.child_creation_screen.step3.title_existing)],
      ChildCreationStep.currentVaultSelection => [
        TextSpan(text: t.taproot.child_creation_screen.step3.single_sig_select_from_vault_title_1),
        TextSpan(text: t.taproot.child_creation_screen.step3.single_sig_select_from_vault_title_2),
      ],
      ChildCreationStep.childWalletQr => [
        TextSpan(text: t.taproot.child_creation_screen.step4.title1),
        TextSpan(text: t.taproot.child_creation_screen.step4.title2, style: CoconutTypography.body1_16),
        TextSpan(text: t.taproot.child_creation_screen.step4.title3, style: CoconutTypography.body1_16),
      ],
      ChildCreationStep.summary =>
        viewModel.isBeneficiaryMatch
            ? [TextSpan(text: t.taproot.child_creation_screen.step6.title1)]
            : [
              TextSpan(
                text: t.taproot.child_creation_screen.step6.title2,
                style: const TextStyle(color: CoconutColors.hotPink),
              ),
            ],
      ChildCreationStep.timeline => [
        TextSpan(text: t.taproot.child_creation_screen.step7.title1),
        TextSpan(text: t.taproot.child_creation_screen.step7.title2),
      ],
      _ => const [],
    };
  }

  List<Widget> _getBodyList(ChildCreationStep step, ChildCreationViewModel viewModel) {
    return switch (step) {
      ChildCreationStep.intro => [Center(child: Image.asset('assets/png/load-wallet.png', scale: 4.0, width: 210))],
      ChildCreationStep.childPreparation => [_buildChildPreparationStep(viewModel)],
      ChildCreationStep.childCreationOption => [_buildChildCreationOptionStep(viewModel)],
      ChildCreationStep.securitySelfCheck => [
        SecuritySelfCheckScreen(isEmbedded: true, onNextPressed: () => _addFirstEmbeddedScreenForCreation(viewModel)),
      ],
      ChildCreationStep.mnemonicCreation => [_buildMnemonicCreationScreen(viewModel)],
      ChildCreationStep.mnemonicImport => [_buildMnemonicImportScreen()],
      ChildCreationStep.seedQrImport => [_buildSeedQrImportScreen(viewModel)],
      ChildCreationStep.currentVaultSelection => [_buildExistingVaultSelectionBody(viewModel)],
      ChildCreationStep.currentVaultMnemonicView => [_buildCurrentVaultMnemonicViewBody(viewModel)],
      ChildCreationStep.mnemonicConfirmation => [_buildMnemonicConfirmationBody(viewModel)],
      ChildCreationStep.importedMnemonicConfirmation => [_buildImportedMnemonicConfirmationBody(viewModel)],
      ChildCreationStep.mnemonicVerify => [_buildMnemonicVerifyBody()],
      ChildCreationStep.verifiedMnemonicConfirmation => [_buildVerifiedMnemonicConfirmationBody(viewModel)],
      ChildCreationStep.childWalletQr => [_buildQrSection(viewModel)],
      ChildCreationStep.scanner => [_buildScannerScreen(viewModel)],
      ChildCreationStep.summary => [_buildSummaryStep(viewModel)],
      ChildCreationStep.timeline => [_buildTimelineStep(viewModel)],
    };
  }

  FutureOr<void> Function()? _getNextButtonAction(ChildCreationStep step, ChildCreationViewModel viewModel) {
    return switch (step) {
      ChildCreationStep.intro => _moveToNextStep,
      ChildCreationStep.childPreparation => _addChildCreationOptionStep,
      ChildCreationStep.childCreationOption => _onChildCreationOptionSelected,
      ChildCreationStep.currentVaultSelection => () {
        setState(() => _isProcessing = true);
        _onCurrentVaultSelected(viewModel);
      },
      ChildCreationStep.childWalletQr => () => _addScannerStep(viewModel),
      ChildCreationStep.summary =>
        viewModel.isBeneficiaryMatch ? () => _saveVaultAndProceedToTimeline(viewModel) : _handleBackPressed,
      ChildCreationStep.timeline => () => _navigateToHome(viewModel),
      _ => null,
    };
  }

  FutureOr<void> Function()? _currentStepAction(ChildCreationViewModel viewModel) {
    if (!_canRunCurrentStepAction(viewModel)) {
      return null;
    }
    return _getNextButtonAction(_currentStepType, viewModel);
  }

  bool _canRunCurrentStepAction(ChildCreationViewModel viewModel) {
    return switch (_currentStepType) {
      ChildCreationStep.childPreparation => viewModel.keyPreparationType != ChildKeyPreparationType.none,
      ChildCreationStep.childCreationOption => switch (viewModel.keyPreparationType) {
        ChildKeyPreparationType.create => viewModel.newKeyCreationType != ChildNewKeyCreationType.none,
        ChildKeyPreparationType.import => viewModel.existingKeyImportType != ChildExistingKeyImportType.none,
        ChildKeyPreparationType.none => false,
      },
      ChildCreationStep.currentVaultSelection => viewModel.existingVaultId != null,
      _ => true,
    };
  }

  bool _showBottomButton(ChildCreationViewModel viewModel) {
    return _currentStepAction(viewModel) != null;
  }

  bool get _isProgressPaused => _shouldPauseProgress(_currentStepType);

  bool get _isSummaryStep => _currentStepType == ChildCreationStep.summary;

  bool get _isTimelineStep => _currentStepType == ChildCreationStep.timeline;

  int _progressCurrentStep(ChildCreationViewModel viewModel) {
    return (_stepHistory.take(_currentStep).where((step) => !_shouldPauseProgress(step)).length -
            _progressInitialStepCount)
        .clamp(0, viewModel.progressTotalStep);
  }

  bool _shouldIgnoreBodyHorizontalPadding(ChildCreationStep step) {
    return switch (step) {
      ChildCreationStep.currentVaultSelection ||
      ChildCreationStep.scanner ||
      ChildCreationStep.summary ||
      ChildCreationStep.securitySelfCheck ||
      ChildCreationStep.mnemonicCreation ||
      ChildCreationStep.mnemonicImport ||
      ChildCreationStep.seedQrImport ||
      ChildCreationStep.currentVaultMnemonicView ||
      ChildCreationStep.mnemonicConfirmation ||
      ChildCreationStep.importedMnemonicConfirmation ||
      ChildCreationStep.mnemonicVerify ||
      ChildCreationStep.verifiedMnemonicConfirmation => true,
      _ => false,
    };
  }

  bool _shouldPauseProgress(ChildCreationStep step) {
    return switch (step) {
      ChildCreationStep.securitySelfCheck ||
      ChildCreationStep.mnemonicCreation ||
      ChildCreationStep.mnemonicImport ||
      ChildCreationStep.seedQrImport ||
      ChildCreationStep.currentVaultMnemonicView ||
      ChildCreationStep.mnemonicConfirmation ||
      ChildCreationStep.importedMnemonicConfirmation ||
      ChildCreationStep.mnemonicVerify ||
      ChildCreationStep.verifiedMnemonicConfirmation ||
      ChildCreationStep.scanner => true,
      _ => false,
    };
  }

  bool _shouldScrollChild(ChildCreationStep step) {
    return switch (step) {
      ChildCreationStep.currentVaultSelection => false,
      _ => true,
    };
  }

  void _moveToNextStep() {
    setState(() {
      _currentStep += 1;
    });
  }

  Widget _buildChildPreparationStep(ChildCreationViewModel viewModel) {
    return ChildPreparationOptionStep(viewModel: viewModel);
  }

  Widget _buildChildCreationOptionStep(ChildCreationViewModel viewModel) {
    return ChildCreationOptionStep(viewModel: viewModel);
  }

  Widget _buildScannerScreen(ChildCreationViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
        return SizedBox(
          height: height,
          child: TaprootScannerScreen(
            dataType: TaprootScannerDataType.walletSync,
            topGuideWidget: Positioned(top: 80, left: 24, right: 24, child: _buildScannerTitle(viewModel)),
            onWalletSyncScanned: (TaprootWalletSyncData syncData) async {
              if (_isProcessing) return false;

              vibrateExtraLight();

              final bool isValid = viewModel.setScannedTaprootVault(syncData);
              if (!isValid) {
                throw FormatException(t.errors.invalid_qr);
              }

              setState(() {
                _isProcessing = true;
              });

              await Future.delayed(const Duration(milliseconds: 1000));
              if (!mounted) return false;

              _completeScannerStep();
              return true;
            },
          ),
        );
      },
    );
  }

  void _addScannerStep(ChildCreationViewModel viewModel) {
    _scannerStep = _addEmbeddedStep(ChildCreationStep.scanner);
  }

  void _completeScannerStep() {
    setState(() => _isProcessing = false);
    _addSummaryStep(context.read<ChildCreationViewModel>());
  }

  Widget _buildScannerTitle(ChildCreationViewModel viewModel) {
    final defaultStyle = CoconutTypography.heading4_18_Bold.setColor(CoconutColors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in _scannerTitleLines(viewModel))
          Text.rich(
            TextSpan(text: line.toPlainText(), style: defaultStyle.merge(line.style)),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  List<TextSpan> _scannerTitleLines(ChildCreationViewModel viewModel) {
    final textList = [
      TextSpan(text: t.taproot.child_creation_screen.step5.title1),
      TextSpan(text: t.taproot.child_creation_screen.step5.title2),
    ];
    if (textList.length == 1) {
      return [const TextSpan(text: ''), textList[0], const TextSpan(text: '')];
    }
    if (textList.length == 2) {
      return [textList[0], textList[1], const TextSpan(text: '')];
    }
    return textList;
  }

  Widget _buildSummaryStep(ChildCreationViewModel viewModel) {
    return ChildImportSummaryStep(viewModel: viewModel);
  }

  Widget _buildTimelineStep(ChildCreationViewModel viewModel) {
    return ChildCreationTimelineStep(viewModel: viewModel);
  }

  Widget _buildQrSection(ChildCreationViewModel viewModel) {
    return ChildWalletQrSection(viewModel: viewModel);
  }

  Widget _buildMnemonicCreationScreen(ChildCreationViewModel viewModel) {
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(viewModel.newKeyCreationType);
    if (mnemonicCreationMethod == null) {
      return const SizedBox.shrink();
    }

    return TaprootMnemonicFlowAdapter.buildCreationScreen(
      method: mnemonicCreationMethod,
      onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
    );
  }

  Widget _buildMnemonicImportScreen() {
    return TaprootMnemonicFlowAdapter.buildMnemonicImportScreen(onCompleted: _addImportedMnemonicConfirmationStep);
  }

  Widget _buildSeedQrImportScreen(ChildCreationViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
        return SizedBox(
          height: height,
          child: TaprootMnemonicFlowAdapter.buildSeedQrImportScreen(
            onMnemonicConfirmationRequested: (secret, passphrase) {
              viewModel.setSecretAndPassphrase(secret, passphrase);
              _onChildWalletSet(viewModel);
            },
          ),
        );
      },
    );
  }

  Widget _buildMnemonicConfirmationBody(ChildCreationViewModel viewModel) {
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(viewModel.newKeyCreationType);
    if (mnemonicCreationMethod == null) {
      return const SizedBox.shrink();
    }

    return TaprootMnemonicFlowAdapter.buildCreationConfirmationScreen(
      method: mnemonicCreationMethod,
      onMnemonicReady: _addMnemonicVerifyStep,
    );
  }

  Widget _buildImportedMnemonicConfirmationBody(ChildCreationViewModel viewModel) {
    return TaprootMnemonicFlowAdapter.buildImportedConfirmationScreen(
      onMnemonicReady: () => _onChildWalletSet(viewModel),
    );
  }

  Widget _buildMnemonicVerifyBody() {
    return TaprootMnemonicFlowAdapter.buildVerifyScreen(onVerificationSuccess: _addVerifiedMnemonicConfirmationStep);
  }

  Widget _buildVerifiedMnemonicConfirmationBody(ChildCreationViewModel viewModel) {
    return TaprootMnemonicFlowAdapter.buildVerifiedConfirmationScreen(
      onMnemonicReady: () => _onChildWalletSet(viewModel),
    );
  }

  Widget _buildCurrentVaultMnemonicViewBody(ChildCreationViewModel viewModel) {
    final selectedExistingVaultId = viewModel.existingVaultId;
    if (selectedExistingVaultId == null) {
      return const SizedBox.shrink();
    }

    final mnemonicViewKey = _currentVaultMnemonicViewKey ??= GlobalKey<MnemonicViewScreenState>();
    if (!_currentVaultMnemonicAuthRequested) {
      _currentVaultMnemonicAuthRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentStepType != ChildCreationStep.currentVaultMnemonicView) {
          return;
        }
        TaprootMnemonicViewFlowAdapter.showDeviceAuthDialog(
          context: context,
          mnemonicViewKey: mnemonicViewKey,
          showDeviceAuthDialog: ChildCreationOverlays.showDeviceAuthDialog,
          authenticateWithBiometricOrPin: ChildCreationOverlays.authenticateWithBiometricOrPin,
        );
      });
    }

    return TaprootMnemonicViewFlowAdapter.buildMnemonicViewStep(
      mnemonicViewKey: mnemonicViewKey,
      walletId: selectedExistingVaultId,
      buildPassphraseToggle: context.read<VisibilityProvider>().isPassphraseUseEnabled,
      emptyPassphraseAsNull: true,
      onAuthCanceled: _handleBackPressed,
      onMnemonicReady: (mnemonic, passphrase) {
        final taprootProvider = context.read<TaprootWalletCreationProvider>();
        taprootProvider.setSecretAndPassphrase(mnemonic, passphrase);
        _onChildWalletSet(viewModel);
      },
    );
  }

  int _addStep(ChildCreationStep step) {
    final addedStep = _stepHistory.length + 1;
    setState(() {
      _stepHistory.add(step);
      _currentStep += 1;
    });
    return addedStep;
  }

  int _addEmbeddedStep(ChildCreationStep step) {
    return _addStep(step);
  }

  void _onChildWalletSet(ChildCreationViewModel viewModel) {
    try {
      viewModel.setupChildWalletInfo();
      setState(() => _isProcessing = false);
      _addChildWalletQrStep(viewModel);
    } catch (e) {
      Logger.error('Failed to generate child wallet: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _addChildCreationOptionStep() {
    _addStep(ChildCreationStep.childCreationOption);
  }

  void _onChildCreationOptionSelected() {
    final viewModel = context.read<ChildCreationViewModel>();
    viewModel.setCreationTypeToChild();

    if (viewModel.keyPreparationType == ChildKeyPreparationType.create) {
      _addEmbeddedStep(ChildCreationStep.securitySelfCheck);
      return;
    }

    if (viewModel.keyPreparationType != ChildKeyPreparationType.import) {
      return;
    }

    switch (viewModel.existingKeyImportType) {
      case ChildExistingKeyImportType.currentVault:
        _addCurrentVaultSelectionStep(viewModel);
        return;
      case ChildExistingKeyImportType.mnemonicInput:
        _addEmbeddedStep(ChildCreationStep.mnemonicImport);
        return;
      case ChildExistingKeyImportType.seedQrScan:
        _addEmbeddedStep(ChildCreationStep.seedQrImport);
        return;
      case ChildExistingKeyImportType.none:
        return;
    }
  }

  void _addChildWalletQrStep(ChildCreationViewModel viewModel) {
    _childWalletQrStep = _addStep(ChildCreationStep.childWalletQr);
  }

  void _addSummaryStep(ChildCreationViewModel viewModel) {
    _addStep(ChildCreationStep.summary);
  }

  Future<void> _saveVaultAndProceedToTimeline(ChildCreationViewModel viewModel) async {
    vibrateExtraLight();
    _isProcessing = true;
    try {
      throw 'test';
      await viewModel.saveVault();
    } catch (e) {
      // TODO: 에러 핸들링
      _isProcessing = false;
      rethrow;
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _stepHistory.add(ChildCreationStep.timeline);
      _currentStep += 1;
    });
  }

  void _addMnemonicConfirmationStep() {
    final viewModel = context.read<ChildCreationViewModel>();
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(viewModel.newKeyCreationType);
    if (mnemonicCreationMethod == null) {
      return;
    }

    TaprootMnemonicFlowAdapter.addCreationConfirmationStep(
      addEmbeddedStep: (widget) => _addEmbeddedStep(ChildCreationStep.mnemonicConfirmation),
      method: mnemonicCreationMethod,
      onMnemonicReady: _addMnemonicVerifyStep,
      onAutoGenerateReady: _addMnemonicVerifyStep,
    );
  }

  void _addImportedMnemonicConfirmationStep() {
    TaprootMnemonicFlowAdapter.addImportedConfirmationStep(
      addEmbeddedStep: (widget) => _addEmbeddedStep(ChildCreationStep.importedMnemonicConfirmation),
      onMnemonicReady: () {
        final viewModel = context.read<ChildCreationViewModel>();
        _onChildWalletSet(viewModel);
      },
    );
  }

  void _addMnemonicVerifyStep() {
    TaprootMnemonicFlowAdapter.addVerifyStep(
      addEmbeddedStep: (widget) => _addEmbeddedStep(ChildCreationStep.mnemonicVerify),
      onVerificationSuccess: _addVerifiedMnemonicConfirmationStep,
    );
  }

  void _addVerifiedMnemonicConfirmationStep() {
    TaprootMnemonicFlowAdapter.addVerifiedConfirmationStep(
      addEmbeddedStep: (widget) => _addEmbeddedStep(ChildCreationStep.verifiedMnemonicConfirmation),
      onMnemonicReady: () {
        final viewModel = context.read<ChildCreationViewModel>();
        _onChildWalletSet(viewModel);
      },
    );
  }

  void _addFirstEmbeddedScreenForCreation(ChildCreationViewModel viewModel) {
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(viewModel.newKeyCreationType);
    if (mnemonicCreationMethod == null) {
      return;
    }

    _addEmbeddedStep(ChildCreationStep.mnemonicCreation);
  }

  TaprootMnemonicCreationMethod? _mnemonicCreationMethodFrom(ChildNewKeyCreationType creationType) {
    return switch (creationType) {
      ChildNewKeyCreationType.coinFlip => TaprootMnemonicCreationMethod.coinFlip,
      ChildNewKeyCreationType.diceRoll => TaprootMnemonicCreationMethod.diceRoll,
      ChildNewKeyCreationType.autoGenerate => TaprootMnemonicCreationMethod.autoGenerate,
      ChildNewKeyCreationType.none => null,
    };
  }

  Future<void> _onNextPressed(ChildCreationViewModel viewModel) async {
    if (_isProcessing) return;
    try {
      await _currentStepAction(viewModel)?.call();
    } catch (e) {
      Logger.error(e);
      TaprootCreationOverlays.showInfoDialog(
        context: context,
        title: t.errors.unexpected_error_title,
        description: e.toString(),
        rightButtonText: t.confirm,
      );
    }
  }

  Future<void> _showChildWalletResetDialog() async {
    final shouldReset = await ChildCreationOverlays.showChildWalletResetDialog(context);
    if (shouldReset == true && mounted) {
      _resetChildWalletAndReturnToOptionStep();
    }
  }

  void _resetChildWalletAndReturnToOptionStep() {
    final viewModel = context.read<ChildCreationViewModel>();
    viewModel.resetChildWalletData();

    setState(() {
      // 자식 지갑 준비 방법 선택 step으로 Back
      _currentStep = 3;
      _removeStepsAfter(_currentStep);

      if (viewModel.keyPreparationType == ChildKeyPreparationType.create) {
        viewModel.setNewKeyCreationType(ChildNewKeyCreationType.none);
      } else {
        viewModel.setExistingKeyImportType(ChildExistingKeyImportType.none);
      }
    });
  }

  void _navigateToHome(ChildCreationViewModel viewModel) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (Route<dynamic> route) => false,
      arguments: viewModel.addedWalletId == null ? null : VaultHomeNavArgs(addedWalletId: viewModel.addedWalletId!),
    );
  }

  void _handleBackPressed() {
    final viewModel = context.read<ChildCreationViewModel>();

    if (_isTimelineStep) {
      _navigateToHome(viewModel);
      return;
    }

    if (_currentStep == _scannerStep) {
      _returnToChildWalletQrStep();
      return;
    }

    if (_currentStep == _childWalletQrStep) {
      _showChildWalletResetDialog();
      return;
    }

    if (_currentStep > 1) {
      setState(() {
        // 현재 step의 바로 이전 step으로 이동. embedded step이면 마지막 embedded 화면도 함께 제거
        final removedStep = _currentStep;
        _currentStep -= 1;
        if (removedStep > _initialStepCount) {
          _removeStepsAfter(_currentStep);
        }

        _isProcessing = false;
      });

      if (_currentStep == 1) {
        viewModel.setKeyPreparationType(ChildKeyPreparationType.none);
      } else if (_currentStep == 2) {
        viewModel.setNewKeyCreationType(ChildNewKeyCreationType.none);
        viewModel.setExistingKeyImportType(ChildExistingKeyImportType.none);
      }

      if (_currentStep <= 3) {
        viewModel.resetChildWalletData();
      }
    } else {
      viewModel.resetChildWalletData();
      Navigator.pop(context);
    }
  }

  void _returnToChildWalletQrStep() {
    setState(() {
      // 스캐너 embedded step에서 뒤로 가면 부모 지갑 QR 표시 step으로 Back
      final childWalletQrStep = _childWalletQrStep;
      if (childWalletQrStep != null) {
        _currentStep = childWalletQrStep;
        _removeStepsAfter(childWalletQrStep);
      }
      _isProcessing = false;
    });
  }

  void _removeStepsAfter(int step) {
    while (_stepHistory.length > step) {
      _stepHistory.removeLast();
    }

    _resetStepIndexesAfter(step);
  }

  void _resetStepIndexesAfter(int step) {
    if ((_childWalletQrStep ?? 0) > step) _childWalletQrStep = null;
    if ((_scannerStep ?? 0) > step) _scannerStep = null;
  }

  Widget _buildExistingVaultSelectionBody(ChildCreationViewModel viewModel) {
    return ChildExistingVaultSelectionBody(viewModel: viewModel, isProcessing: _isProcessing);
  }

  void _addCurrentVaultSelectionStep(ChildCreationViewModel viewModel) {
    _addStep(ChildCreationStep.currentVaultSelection);
  }

  void _switchToSeedQrImport(ChildCreationViewModel viewModel) {
    if (_currentStepType != ChildCreationStep.mnemonicImport) {
      return;
    }

    setState(() {
      viewModel.setExistingKeyImportType(ChildExistingKeyImportType.seedQrScan);
      _stepHistory[_currentStep - 1] = ChildCreationStep.seedQrImport;
    });
  }

  void _switchToMnemonicImport(ChildCreationViewModel viewModel) {
    if (_currentStepType != ChildCreationStep.seedQrImport) {
      return;
    }

    setState(() {
      viewModel.setExistingKeyImportType(ChildExistingKeyImportType.mnemonicInput);
      _stepHistory[_currentStep - 1] = ChildCreationStep.mnemonicImport;
    });
  }

  Future<void> _onCurrentVaultSelected(ChildCreationViewModel viewModel) async {
    final selectedExistingVaultId = viewModel.existingVaultId;
    if (selectedExistingVaultId == null) {
      return;
    }

    final shouldProceed = await ChildCreationOverlays.showCurrentVaultConfirmDialog(context);
    if (!mounted) {
      return;
    }

    if (shouldProceed == true) {
      _proceedWithSelectedVault();
      return;
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _proceedWithSelectedVault() {
    if (!mounted) {
      return;
    }

    _currentVaultMnemonicViewKey = GlobalKey<MnemonicViewScreenState>();
    _currentVaultMnemonicAuthRequested = false;
    _addEmbeddedStep(ChildCreationStep.currentVaultMnemonicView);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChildCreationViewModel>();
    final isScannerStep = _currentStepType == ChildCreationStep.scanner;
    final bool showScanButton = _currentStepType == ChildCreationStep.mnemonicImport;
    final bool showTypeButton = _currentStepType == ChildCreationStep.seedQrImport;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: t.taproot.child_creation_screen.title,
          isBottom: _isTimelineStep,
          isBackButton: !_isTimelineStep,
          context: context,
          backgroundColor: CoconutColors.white,
          onBackPressed: _handleBackPressed,
          actionButtonList: [
            if (showScanButton)
              IconButton(
                icon: SvgPicture.asset(
                  'assets/svg/scan.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(CoconutColors.black, BlendMode.srcIn),
                ),
                onPressed: () => _switchToSeedQrImport(viewModel),
                tooltip: t.taproot.common.existing_option3,
              ),
            if (showTypeButton)
              IconButton(
                icon: SvgPicture.asset(
                  'assets/svg/paste.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(CoconutColors.black, BlendMode.srcIn),
                ),
                onPressed: () => _switchToMnemonicImport(viewModel),
                tooltip: t.taproot.common.existing_option2,
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              TaprootCreationBody(
                key: ValueKey(_currentStep),
                titleLines: _titleLines(),
                showBottomButton: _showBottomButton(viewModel),
                bottomButtonText:
                    _isSummaryStep && !viewModel.isBeneficiaryMatch ? t.rescan : (_isTimelineStep ? t.complete : null),
                ignoreChildHorizontalPadding: _shouldIgnoreBodyHorizontalPadding(_currentStepType),
                showHeader: !_isProgressPaused && !isScannerStep && !(_isSummaryStep && !viewModel.isBeneficiaryMatch),
                scrollChild: !_isProgressPaused && _shouldScrollChild(_currentStepType),
                runBottomButtonActionWithoutTransition: _isSummaryStep && viewModel.isBeneficiaryMatch,
                onBottomButtonPressed: () => _onNextPressed(viewModel),
                child:
                    _isProgressPaused
                        ? _getBodyList(_currentStepType, viewModel).first
                        : Column(children: _getBodyList(_currentStepType, viewModel)),
              ),
              TopProgressBar(
                visible: !_isProgressPaused,
                total: viewModel.progressTotalStep,
                current: _progressCurrentStep(viewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
