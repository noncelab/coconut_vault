import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
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
      create: (context) => ChildCreationViewModel(context.read<TaprootWalletCreationProvider>()),
      child: const _ChildCreationScreenContent(),
    );
  }
}

class _ChildCreationScreenContent extends StatefulWidget {
  const _ChildCreationScreenContent();

  @override
  State<_ChildCreationScreenContent> createState() => _ChildCreationScreenContentState();
}

class _ChildCreationScreenContentState extends State<_ChildCreationScreenContent> {
  static const int _progressInitialStepCount = 1;

  int _currentStep = 1;
  final List<Widget> _embeddedWidgets = [];
  int? _currentVaultSelectionStep;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChildCreationViewModel>().resetChildWalletData();
      }
    });
  }

  int _totalStep(ChildCreationViewModel viewModel) => viewModel.visibleProgressStepCount + _embeddedWidgets.length;

  int get _embeddedStartIndex => _currentVaultSelectionStep != null ? 4 : 3;

  int _progressCurrentStep(ChildCreationViewModel viewModel) {
    final currentStep = switch (_currentStep) {
      _ when _currentStep <= _embeddedStartIndex => _currentStep - _progressInitialStepCount,
      _ when _currentStep <= _embeddedStartIndex + _embeddedWidgets.length =>
        _embeddedStartIndex - _progressInitialStepCount,
      _ => _currentStep - _embeddedWidgets.length - _progressInitialStepCount,
    };

    return currentStep.clamp(0, viewModel.progressTotalStep);
  }

  List<TextSpan> _titleLines(ChildCreationViewModel viewModel) {
    final titles = _buildTitleList(viewModel);

    List<TextSpan> textList;
    if (_currentStep <= _embeddedStartIndex) {
      textList = titles[_currentStep - 1];
    } else if (_currentStep <= _embeddedStartIndex + _embeddedWidgets.length) {
      return [const TextSpan(text: '')];
    } else {
      textList = titles[_currentStep - _embeddedWidgets.length - 1];
    }

    if (textList.length == 1) {
      return [const TextSpan(text: ''), textList[0], const TextSpan(text: '')];
    }
    if (textList.length == 2) {
      return [textList[0], textList[1], const TextSpan(text: '')];
    }
    return textList;
  }

  List<List<TextSpan>> _buildTitleList(ChildCreationViewModel viewModel) {
    List<List<TextSpan>> list = [
      [
        TextSpan(text: t.taproot.child_creation_screen.step1.title1),
        TextSpan(text: t.taproot.child_creation_screen.step1.title2),
      ],
      [
        TextSpan(text: t.taproot.child_creation_screen.step2.title1),
        TextSpan(text: t.taproot.child_creation_screen.step2.title2),
      ],
      viewModel.keyPreparationType == ChildKeyPreparationType.create
          ? [TextSpan(text: t.taproot.child_creation_screen.step3.title_new)]
          : [TextSpan(text: t.taproot.child_creation_screen.step3.title_existing)],
    ];

    if (_currentVaultSelectionStep != null) {
      list.add([
        TextSpan(text: t.taproot.child_creation_screen.step3.single_sig_select_from_vault_title_1),
        TextSpan(text: t.taproot.child_creation_screen.step3.single_sig_select_from_vault_title_2),
      ]);
    }

    list.addAll([
      [
        TextSpan(text: t.taproot.child_creation_screen.step4.title1),
        TextSpan(text: t.taproot.child_creation_screen.step4.title2, style: CoconutTypography.body1_16),
        TextSpan(text: t.taproot.child_creation_screen.step4.title3, style: CoconutTypography.body1_16),
      ],
      [
        TextSpan(text: t.taproot.child_creation_screen.step5.title1),
        TextSpan(text: t.taproot.child_creation_screen.step5.title2),
      ],
      viewModel.isBeneficiaryMatch
          ? [TextSpan(text: t.taproot.child_creation_screen.step6.title1)]
          : [
            TextSpan(
              text: t.taproot.child_creation_screen.step6.title2,
              style: const TextStyle(color: CoconutColors.hotPink),
            ),
          ],
      [
        TextSpan(text: t.taproot.child_creation_screen.step7.title1),
        TextSpan(text: t.taproot.child_creation_screen.step7.title2),
      ],
    ]);

    return list;
  }

  Widget _buildChildPreparationStep(ChildCreationViewModel viewModel) {
    return ChildPreparationOptionStep(viewModel: viewModel);
  }

  Widget _buildChildCreationOptionStep(ChildCreationViewModel viewModel) {
    return ChildCreationOptionStep(viewModel: viewModel);
  }

  Widget _buildScannerStep(ChildCreationViewModel viewModel) {
    return _buildScannerScreen(viewModel);
  }

  Widget _buildScannerScreen(ChildCreationViewModel viewModel) {
    return TaprootScannerScreen(
      topGuideWidget: Positioned(top: 80, left: 24, right: 24, child: _buildScannerTitle(viewModel)),
      onTaprootVaultScanned: (beneficiaryVault) async {
        if (_isProcessing) return false;

        vibrateExtraLight();

        final bool isValid = viewModel.setScannedTaprootVault(beneficiaryVault.descriptor);
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
    );
  }

  void _addScannerStep(ChildCreationViewModel viewModel) {
    setState(() {
      _embeddedWidgets.add(_buildScannerScreen(viewModel));
      _currentStep = _embeddedStartIndex + _embeddedWidgets.length;
    });
  }

  void _completeScannerStep() {
    setState(() {
      _isProcessing = false;
      _currentStep += 3;
    });
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
    final scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;
    final titleList = _buildTitleList(viewModel);
    final textList = titleList[scannerStepIndex - 1];
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

  Widget _getCurrentChild(ChildCreationViewModel viewModel) {
    if (_currentStep > _embeddedStartIndex && _currentStep <= _embeddedStartIndex + _embeddedWidgets.length) {
      return _embeddedWidgets[_currentStep - _embeddedStartIndex - 1];
    }

    int baseCurrentStep = _currentStep;
    if (_currentStep > _embeddedStartIndex + _embeddedWidgets.length) {
      baseCurrentStep = _currentStep - _embeddedWidgets.length;
    }

    switch (baseCurrentStep) {
      case 1:
        return Center(child: Image.asset('assets/png/load-wallet.png', scale: 4.0, width: 210));
      case 2:
        return _buildChildPreparationStep(viewModel);
      case 3:
        return _buildChildCreationOptionStep(viewModel);
      default:
        int scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;

        if (_currentVaultSelectionStep != null && baseCurrentStep == 4) {
          return _buildExistingVaultSelectionBody(viewModel);
        }

        if (baseCurrentStep == scannerStepIndex - 1) {
          return _buildQrSection(viewModel);
        } else if (baseCurrentStep == scannerStepIndex) {
          return _buildScannerStep(viewModel);
        } else if (baseCurrentStep == scannerStepIndex + 1) {
          return _buildSummaryStep(viewModel);
        } else if (baseCurrentStep == scannerStepIndex + 2) {
          return _buildTimelineStep(viewModel);
        }

        return const SizedBox.shrink();
    }
  }

  Widget _buildQrSection(ChildCreationViewModel viewModel) {
    return ChildWalletQrSection(viewModel: viewModel);
  }

  bool _isNextButtonVisible(ChildCreationViewModel viewModel) {
    if (_currentStep == _currentVaultSelectionStep) {
      return viewModel.existingVaultId != null;
    }
    if (_currentStep > _embeddedStartIndex && _currentStep <= _embeddedStartIndex + _embeddedWidgets.length) {
      return false;
    }
    if (_currentStep == 2) {
      return viewModel.keyPreparationType != ChildKeyPreparationType.none;
    }
    if (_currentStep == 3) {
      if (viewModel.keyPreparationType == ChildKeyPreparationType.create) {
        return viewModel.newKeyCreationType != ChildNewKeyCreationType.none;
      } else {
        return viewModel.existingKeyImportType != ChildExistingKeyImportType.none;
      }
    }

    int scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;
    int baseCurrentStep = _currentStep > _embeddedStartIndex ? _currentStep - _embeddedWidgets.length : _currentStep;

    if (baseCurrentStep == scannerStepIndex) {
      return false;
    }

    return true;
  }

  int _addEmbeddedStep(Widget widget) {
    setState(() {
      _embeddedWidgets.add(widget);
      _currentStep += 1;
    });
    return _currentStep;
  }

  void _onChildWalletSet(ChildCreationViewModel viewModel) {
    try {
      viewModel.setupChildWalletInfo();
      setState(() {
        _isProcessing = false;
        _currentStep += 1;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      Logger.error('Failed to generate child wallet: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _addMnemonicConfirmationStep() {
    final viewModel = context.read<ChildCreationViewModel>();
    final mnemonicCreationMethod = _mnemonicCreationMethodFrom(viewModel.newKeyCreationType);
    if (mnemonicCreationMethod == null) {
      return;
    }

    TaprootMnemonicFlowAdapter.addCreationConfirmationStep(
      addEmbeddedStep: _addEmbeddedStep,
      method: mnemonicCreationMethod,
      onMnemonicReady: _addMnemonicVerifyStep,
      onAutoGenerateReady: _addMnemonicVerifyStep,
    );
  }

  void _addImportedMnemonicConfirmationStep() {
    TaprootMnemonicFlowAdapter.addImportedConfirmationStep(
      addEmbeddedStep: _addEmbeddedStep,
      onMnemonicReady: () {
        final viewModel = context.read<ChildCreationViewModel>();
        _onChildWalletSet(viewModel);
      },
    );
  }

  void _addMnemonicVerifyStep() {
    TaprootMnemonicFlowAdapter.addVerifyStep(
      addEmbeddedStep: _addEmbeddedStep,
      onVerificationSuccess: _addVerifiedMnemonicConfirmationStep,
    );
  }

  void _addVerifiedMnemonicConfirmationStep() {
    TaprootMnemonicFlowAdapter.addVerifiedConfirmationStep(
      addEmbeddedStep: _addEmbeddedStep,
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

    _addEmbeddedStep(
      TaprootMnemonicFlowAdapter.buildCreationScreen(
        method: mnemonicCreationMethod,
        onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
      ),
    );
  }

  TaprootMnemonicCreationMethod? _mnemonicCreationMethodFrom(ChildNewKeyCreationType creationType) {
    return switch (creationType) {
      ChildNewKeyCreationType.coinFlip => TaprootMnemonicCreationMethod.coinFlip,
      ChildNewKeyCreationType.diceRoll => TaprootMnemonicCreationMethod.diceRoll,
      ChildNewKeyCreationType.autoGenerate => TaprootMnemonicCreationMethod.autoGenerate,
      ChildNewKeyCreationType.none => null,
    };
  }

  void _onNextPressed(ChildCreationViewModel viewModel) async {
    if (_isProcessing) return;

    if (_currentStep == _currentVaultSelectionStep) {
      if (viewModel.existingVaultId != null) {
        setState(() {
          _isProcessing = true;
        });
        _onCurrentVaultSelected(viewModel);
      }
      return;
    }

    if (_currentStep == 3) {
      viewModel.setCreationTypeToChild();

      if (viewModel.keyPreparationType == ChildKeyPreparationType.create) {
        _addEmbeddedStep(
          SecuritySelfCheckScreen(
            isEmbedded: true,
            onNextPressed: () {
              _addFirstEmbeddedScreenForCreation(viewModel);
            },
          ),
        );
        return;
      } else if (viewModel.keyPreparationType == ChildKeyPreparationType.import) {
        if (viewModel.existingKeyImportType == ChildExistingKeyImportType.currentVault) {
          _addCurrentVaultSelectionStep(viewModel);
          return;
        } else if (viewModel.existingKeyImportType == ChildExistingKeyImportType.mnemonicInput) {
          _addEmbeddedStep(
            TaprootMnemonicFlowAdapter.buildMnemonicImportScreen(onCompleted: _addImportedMnemonicConfirmationStep),
          );
          return;
        } else if (viewModel.existingKeyImportType == ChildExistingKeyImportType.seedQrScan) {
          _addEmbeddedStep(
            TaprootMnemonicFlowAdapter.buildSeedQrImportScreen(
              onMnemonicConfirmationRequested: (secret, passphrase) {
                viewModel.setSecretAndPassphrase(secret, passphrase);
                _onChildWalletSet(viewModel);
              },
            ),
          );
          return;
        }
      }
    }

    int scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;
    int baseCurrentStep = _currentStep > _embeddedStartIndex ? _currentStep - _embeddedWidgets.length : _currentStep;

    if (baseCurrentStep == scannerStepIndex - 1) {
      _addScannerStep(viewModel);
      return;
    }

    if (baseCurrentStep == scannerStepIndex + 1) {
      if (!viewModel.isBeneficiaryMatch) {
        _handleBackPressed();
        return;
      }
    }

    if (_currentStep >= _totalStep(viewModel)) {
      vibrateExtraLight();

      setState(() => _isProcessing = true);
      try {
        await viewModel.saveVault(context.read<WalletProvider>());
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    setState(() {
      _currentStep += 1;
    });
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
      _embeddedWidgets.clear();
      _currentStep = 3;

      if (viewModel.keyPreparationType == ChildKeyPreparationType.create) {
        viewModel.setNewKeyCreationType(ChildNewKeyCreationType.none);
      } else {
        viewModel.setExistingKeyImportType(ChildExistingKeyImportType.none);
      }
    });
  }

  void _handleBackPressed() {
    final viewModel = context.read<ChildCreationViewModel>();

    if (_isScannerEmbeddedStep) {
      _returnToChildWalletQrStep();
      return;
    }

    if (_isChildWalletQrStep) {
      _showChildWalletResetDialog();
      return;
    }

    if (_currentStep > 1) {
      setState(() {
        if (_currentStep > _embeddedStartIndex && _currentStep <= _embeddedStartIndex + _embeddedWidgets.length) {
          _embeddedWidgets.removeLast();
        }
        _currentStep -= 1;

        if (_currentVaultSelectionStep != null && _currentStep < _currentVaultSelectionStep!) {
          _currentVaultSelectionStep = null;
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

  bool get _isScannerEmbeddedStep {
    return _embeddedWidgets.isNotEmpty &&
        _embeddedWidgets.last is TaprootScannerScreen &&
        _currentStep == _embeddedStartIndex + _embeddedWidgets.length;
  }

  void _returnToChildWalletQrStep() {
    setState(() {
      _embeddedWidgets.removeLast();
      final scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;
      _currentStep = _embeddedWidgets.length + scannerStepIndex - 1;
      _isProcessing = false;
    });
  }

  bool get _isChildWalletQrStep {
    final isEmbeddedActive =
        _currentStep > _embeddedStartIndex && _currentStep <= _embeddedStartIndex + _embeddedWidgets.length;
    if (isEmbeddedActive) {
      return false;
    }

    final baseCurrentStep =
        _currentStep > _embeddedStartIndex + _embeddedWidgets.length
            ? _currentStep - _embeddedWidgets.length
            : _currentStep;
    final scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;
    return baseCurrentStep == scannerStepIndex - 1;
  }

  Widget _buildExistingVaultSelectionBody(ChildCreationViewModel viewModel) {
    return ChildExistingVaultSelectionBody(viewModel: viewModel, isProcessing: _isProcessing);
  }

  void _addCurrentVaultSelectionStep(ChildCreationViewModel viewModel) {
    setState(() {
      _currentVaultSelectionStep = 4;
      _currentStep = 4;
    });
  }

  void _switchToSeedQrImport(ChildCreationViewModel viewModel) {
    if (_embeddedWidgets.isEmpty || !TaprootMnemonicFlowAdapter.isMnemonicImportScreen(_embeddedWidgets.last)) {
      return;
    }

    setState(() {
      _embeddedWidgets.removeLast();
      viewModel.setExistingKeyImportType(ChildExistingKeyImportType.seedQrScan);

      final taprootProvider = context.read<TaprootWalletCreationProvider>();
      _embeddedWidgets.add(
        TaprootMnemonicFlowAdapter.buildSeedQrImportScreen(
          onMnemonicConfirmationRequested: (secret, passphrase) {
            taprootProvider.setSecretAndPassphrase(secret, passphrase);
            _onChildWalletSet(viewModel);
          },
        ),
      );
    });
  }

  void _switchToMnemonicImport(ChildCreationViewModel viewModel) {
    if (_embeddedWidgets.isEmpty || !TaprootMnemonicFlowAdapter.isSeedQrImportScreen(_embeddedWidgets.last)) {
      return;
    }

    setState(() {
      _embeddedWidgets.removeLast();
      viewModel.setExistingKeyImportType(ChildExistingKeyImportType.mnemonicInput);

      _embeddedWidgets.add(
        TaprootMnemonicFlowAdapter.buildMnemonicImportScreen(onCompleted: _addImportedMnemonicConfirmationStep),
      );
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
      _proceedWithSelectedVault(viewModel, selectedExistingVaultId);
      return;
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _proceedWithSelectedVault(ChildCreationViewModel viewModel, int selectedExistingVaultId) {
    if (!mounted) {
      return;
    }

    final mnemonicViewKey = GlobalKey<MnemonicViewScreenState>();
    _addEmbeddedStep(
      TaprootMnemonicViewFlowAdapter.buildMnemonicViewStep(
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
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChildCreationViewModel>();
    final isVaultSelectionStep = _currentStep == _currentVaultSelectionStep;

    int embeddedStartIndex = _currentVaultSelectionStep != null ? 4 : 3;
    final isEmbeddedActive =
        _currentStep > embeddedStartIndex && _currentStep <= embeddedStartIndex + _embeddedWidgets.length;

    int scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;
    int baseCurrentStep = _currentStep > embeddedStartIndex ? _currentStep - _embeddedWidgets.length : _currentStep;
    final isScannerStep = baseCurrentStep == scannerStepIndex;
    final isSummaryStep = baseCurrentStep == scannerStepIndex + 1;
    final isLastStep = _currentStep == _totalStep(viewModel);

    Widget? currentEmbeddedWidget;
    if (isEmbeddedActive) {
      currentEmbeddedWidget = _embeddedWidgets[_currentStep - embeddedStartIndex - 1];
    }
    final bool showScanButton =
        currentEmbeddedWidget != null && TaprootMnemonicFlowAdapter.isMnemonicImportScreen(currentEmbeddedWidget);
    final bool showTypeButton =
        currentEmbeddedWidget != null && TaprootMnemonicFlowAdapter.isSeedQrImportScreen(currentEmbeddedWidget);

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
                titleLines: _titleLines(viewModel),
                showBottomButton: _isNextButtonVisible(viewModel),
                bottomButtonText:
                    isSummaryStep && !viewModel.isBeneficiaryMatch ? t.rescan : (isLastStep ? t.complete : null),
                ignoreChildHorizontalPadding:
                    isEmbeddedActive || isVaultSelectionStep || isScannerStep || isSummaryStep,
                showHeader: !isEmbeddedActive && !isScannerStep && !(isSummaryStep && !viewModel.isBeneficiaryMatch),
                scrollChild: !isEmbeddedActive && !isVaultSelectionStep && !isScannerStep,
                onBottomButtonPressed: () => _onNextPressed(viewModel),
                child: _getCurrentChild(viewModel),
              ),
              TopProgressBar(
                visible: !isEmbeddedActive,
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
