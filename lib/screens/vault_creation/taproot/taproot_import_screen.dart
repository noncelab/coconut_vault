import 'dart:async';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/taproot_import_view_model.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_scanner_screen.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_setup_summary_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_vault_item_card.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/widgets/text/character_fade_in_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class TaprootImportScreen extends StatefulWidget {
  const TaprootImportScreen({super.key});

  @override
  State<TaprootImportScreen> createState() => _TaprootImportScreenState();
}

class _TaprootImportScreenState extends State<TaprootImportScreen> {
  static const int _initialStepCount = 1;
  static const int _progressTotalStep = 4;

  late final List<List<TextSpan>> _titleList;
  late final List<List<Widget>> _bodyList;
  late final List<FutureOr<void> Function()?> _nextButtonActions;
  late final List<bool> _ignoreBodyHorizontalPaddingList;
  late final List<bool> _pauseProgressList;
  late final List<bool> _scrollChildList;
  final TaprootImportViewModel _viewModel = TaprootImportViewModel();
  int _currentStep = 1;
  int? _roleSelectionStep;
  int? _importWalletStep;
  int? _importResultStep;
  int? _timelineStep;
  int? _createdTaprootVaultId;
  TaprootVaultCreationTimelineInfo? _timelineInfo;
  bool _isProcessingImport = false;
  bool _isTimelineAnimationCompleted = false;

  bool get _isProgressPaused => _pauseProgressList[_currentStep - 1];
  bool get _showHeader => !_isProgressPaused;
  int get _progressCurrentStep =>
      (_pauseProgressList.take(_currentStep).where((isPaused) => !isPaused).length - _initialStepCount).clamp(
        0,
        _progressTotalStep,
      );

  FutureOr<void> Function()? get _currentNextButtonAction {
    final actionIndex = _currentStep - 1;
    if (actionIndex < 0 || actionIndex >= _nextButtonActions.length) {
      return null;
    }
    return _nextButtonActions[actionIndex];
  }

  bool get _showBottomButton {
    if (_isProcessingImport) {
      return false;
    }

    if (_currentStep == _roleSelectionStep) {
      return _viewModel.selectedRole != TaprootImportRole.none;
    }

    return _currentNextButtonAction != null && (!_isTimelineStep || _isTimelineAnimationCompleted);
  }

  bool get _showImportModeToggle {
    return _currentStep == _importWalletStep;
  }

  bool get _isTimelineStep {
    return _currentStep == _timelineStep;
  }

  bool get _runBottomButtonActionWithoutTransition {
    return false;
  }

  String? get _bottomButtonText {
    if (_currentStep == _importResultStep && !_viewModel.isSelectedRoleMatch) {
      return t.taproot.taproot_import_screen.step6.enter_again;
    }

    return _progressCurrentStep >= _progressTotalStep ? t.complete : null;
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
    required FutureOr<void> Function()? nextButtonAction,
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
      bodyList: [_buildVaultSummaryCards()],
      nextButtonAction: _addParentConfigurationStep,
      ignoreBodyHorizontalPadding: true,
    );
  }

  Widget _buildVaultSummaryCards({bool showSelectedRoleState = false}) {
    final scannedVaultItem = _viewModel.scannedVaultItem;
    if (scannedVaultItem == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TaprootVaultItemCard(vaultItem: scannedVaultItem, showTaprootWalletInfo: false),
          ),
          CoconutLayout.spacing_200h,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TaprootSetupSummaryCard(
              itemList: [
                ...scannedVaultItem.owners.asMap().entries.map((entry) {
                  final index = entry.key;
                  final owner = entry.value;
                  final isSingleParent = scannedVaultItem.owners.length == 1;
                  final parentName = isSingleParent
                      ? t.taproot.taproot_import_screen.step4.signer
                      : '${t.taproot.taproot_import_screen.step4.signer} ${String.fromCharCode(65 + index)}';
                  final isMatchedSigner = showSelectedRoleState &&
                      _viewModel.selectedRole == TaprootImportRole.signer &&
                      owner.isSeedStored;

                  return TaprootParticipantCard(
                    role: TaprootParticipantRole.parent,
                    walletName: parentName,
                    mfp: owner.masterFingerprint,
                    derivationPath: scannedVaultItem.derivationPath,
                    hasSingleParent: isSingleParent,
                    hasBackgroundColor: isMatchedSigner,
                    isMine: isMatchedSigner,
                    isValid: true,
                  );
                }),
                ...scannedVaultItem.beneficiaries.map((beneficiary) {
                  final isBeneficiaryRole =
                      showSelectedRoleState && _viewModel.selectedRole == TaprootImportRole.beneficiary;
                  final isMatchedBeneficiary = isBeneficiaryRole &&
                      (beneficiary.isSeedStored || beneficiary.masterFingerprint == _viewModel.masterFingerprint);

                  return TaprootParticipantCard(
                    role: TaprootParticipantRole.child,
                    mfp: beneficiary.masterFingerprint,
                    derivationPath: scannedVaultItem.derivationPath,
                    locktime: beneficiary.lockTime,
                    hasBackgroundColor: isMatchedBeneficiary,
                    isMine: isMatchedBeneficiary,
                    isValid: !isBeneficiaryRole || beneficiary.masterFingerprint == _viewModel.masterFingerprint,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addParentConfigurationStep() {
    _roleSelectionStep = _addStep(
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
        CoconutLayout.spacing_800h,
        Consumer<TaprootImportViewModel>(
          builder: (context, viewModel, child) {
            return MenuGrid(
              children: [
                SelectableOptionCard(
                  title: t.taproot.taproot_import_screen.step4.signer,
                  bottomAssetPath: 'assets/png/single-key.png',
                  isSelected: viewModel.selectedRole == TaprootImportRole.signer,
                  onTap: () => viewModel.setRole(TaprootImportRole.signer),
                  imageScale: 5.5,
                  height: 130,
                ),
                SelectableOptionCard(
                  title: t.taproot.taproot_import_screen.step4.beneficiary,
                  bottomAssetPath: 'assets/png/bitcoin-on-hand.png',
                  isSelected: viewModel.selectedRole == TaprootImportRole.beneficiary,
                  onTap: () => viewModel.setRole(TaprootImportRole.beneficiary),
                  imageScale: 3.5,
                  height: 130,
                ),
              ],
            );
          },
        ),
      ],
      nextButtonAction: _addParentWalletCheckStep,
    );
  }

  void _addParentWalletCheckStep() {
    _viewModel.setImportMode(ImportMode.enter);
    _importWalletStep = _addEmbeddedStep(
      Consumer<TaprootImportViewModel>(
        builder: (context, viewModel, child) {
          return _buildWalletImportScreen(viewModel.currentImportMode);
        },
      ),
    );
  }

  Widget _buildWalletImportScreen(ImportMode importMode) {
    return switch (importMode) {
      ImportMode.enter => MnemonicImportScreen(
          key: const ValueKey('taproot-import-mnemonic'),
          isEmbedded: true,
          isTaprootCreationChild: true,
          requirePassphraseConfirmation: true,
          onMnemonicConfirmationRequested: _setImportedSeed,
        ),
      ImportMode.scan => SeedQrImportScreen(
          key: const ValueKey('taproot-import-seed-qr'),
          isEmbedded: true,
          isTaprootChild: true,
          requirePassphraseConfirmation: true,
          onMnemonicConfirmationRequested: _setImportedSeedFromSeedQr,
        ),
    };
  }

  Widget _buildSummaryStep() {
    if (_viewModel.scannedVaultItem == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildSummaryHeader(), _buildVaultSummaryCards(showSelectedRoleState: true)],
    );
  }

  Widget _buildSummaryHeader() {
    final step6 = t.taproot.taproot_import_screen.step6;
    final isMatch = _viewModel.isSelectedRoleMatch;

    final description = switch (_viewModel.selectedRole) {
      TaprootImportRole.signer => step6.description_signer,
      TaprootImportRole.beneficiary => step6.description_beneficiary,
      TaprootImportRole.none => '',
    };

    return Column(
      children: [
        CoconutLayout.spacing_1500h,
        if (!isMatch) ...[
          SvgPicture.asset('assets/svg/triangle-warning.svg', width: 25, height: 25),
          CoconutLayout.spacing_200h,
        ],
        Text(
          isMatch ? step6.title_match_inheritance_wallet : step6.title_doesnt_match_inheritance_wallet,
          style: CoconutTypography.heading3_21_Bold.setColor(isMatch ? CoconutColors.black : CoconutColors.hotPink),
          textAlign: TextAlign.center,
        ),
        if (isMatch && description.isNotEmpty) ...[
          CoconutLayout.spacing_300h,
          Text(
            description,
            style: CoconutTypography.body2_14.setColor(CoconutColors.gray700),
            textAlign: TextAlign.center,
          ),
        ],
        CoconutLayout.spacing_800h,
      ],
    );
  }

  void _setImportedSeed(Uint8List secret, Uint8List? passphrase) {
    unawaited(_setImportedSeedAsync(secret, passphrase));
  }

  Future<void> _setImportedSeedFromSeedQr(Uint8List secret, Uint8List? passphrase) {
    return _setImportedSeedAsync(secret, passphrase);
  }

  Future<void> _setImportedSeedAsync(Uint8List secret, Uint8List? passphrase) async {
    if (_isProcessingImport) {
      return;
    }

    setState(() {
      _isProcessingImport = true;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    final creationProvider = context.read<TaprootWalletCreationProvider>();
    try {
      final isSeedSet = await _viewModel.setImportedSeed(creationProvider, secret: secret, passphrase: passphrase);
      if (!mounted) return;

      setState(() {
        _isProcessingImport = false;
      });

      if (!isSeedSet) {
        return;
      }
      _addImportResultStep();
    } finally {
      if (mounted && _isProcessingImport) {
        setState(() {
          _isProcessingImport = false;
        });
      }
    }
  }

  void _addImportResultStep() {
    _importResultStep = _addStep(
      titleList: [],
      bodyList: [_buildSummaryStep()],
      nextButtonAction: _handleImportResultNextButton,
      ignoreBodyHorizontalPadding: true,
    );
  }

  Future<void> _handleImportResultNextButton() async {
    if (_isProcessingImport) {
      return;
    }

    if (_viewModel.isSelectedRoleMatch) {
      if (_createdTaprootVaultId == null) {
        await _saveImportedTaprootWallet();
      }
      _addTimelineStep();
      return;
    }

    _viewModel.setImportMode(ImportMode.enter);
    _handleBackPressed();
  }

  Future<void> _handleBeforeBottomButtonFadeOut() async {
    if (_currentStep != _importResultStep || !_viewModel.isSelectedRoleMatch) {
      return;
    }

    await _saveImportedTaprootWallet();
  }

  Future<void> _saveImportedTaprootWallet() async {
    if (_createdTaprootVaultId != null) {
      return;
    }

    // 불러온 Taproot 지갑 추가 후 Timeline으로 이동
    setState(() {
      _isProcessingImport = true;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    final creationProvider = context.read<TaprootWalletCreationProvider>();
    final walletProvider = context.read<WalletProvider>();
    final timelineInfo = TaprootVaultCreationTimelineInfo(
      parentMasterFingerprint: creationProvider.masterFingerprint,
      externalParentMasterFingerprint: creationProvider.externalMultisigParentMasterFingerprint,
      childMasterFingerprint: creationProvider.childWalletMasterFingerprint,
    );

    final walletCreateDto = _viewModel.createWalletCreateDto(creationProvider);

    try {
      final vault = await walletProvider.addTaprootVault(walletCreateDto);
      if (!mounted) return;

      creationProvider.resetAll();
      _createdTaprootVaultId = vault.id;
      _timelineInfo = timelineInfo;
      setState(() {
        _isProcessingImport = false;
      });
    } finally {
      walletCreateDto.wipe();
      if (mounted && _isProcessingImport) {
        setState(() {
          _isProcessingImport = false;
        });
      }
    }
  }

  void _addTimelineStep() {
    _isTimelineAnimationCompleted = false;
    _timelineStep = _addStep(
      titleList: [
        TextSpan(text: t.taproot.taproot_import_screen.step7.title1),
        TextSpan(text: t.taproot.taproot_import_screen.step7.title2),
      ],
      bodyList: [_buildTimelineStepIndicator()],
      nextButtonAction: _navigateToHome,
    );
  }

  Widget _buildTimelineStepIndicator() {
    final timeline = t.taproot.taproot_import_screen.timeline;
    final activationDateTimeText = _activationDateTimeText;
    final isSigner = _viewModel.selectedRole == TaprootImportRole.signer;
    final scannedVaultItem = _viewModel.scannedVaultItem;
    final isSingleParent = scannedVaultItem == null || scannedVaultItem.owners.length == 1;
    final inheritedWalletDescription = isSingleParent
        ? timeline.single_parent_wallet_with_name(name: scannedVaultItem?.name ?? '')
        : timeline.multi_parent_wallet_with_name(name: scannedVaultItem.name);

    return TimelineStepIndicator(
      onCompleted: _handleTimelineAnimationCompleted,
      enableTapToSkip: true,
      timelineStepItemList: [
        TimelineStepItem(
          title: timeline.inheritance_wallet_imported,
          description: inheritedWalletDescription,
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: isSigner ? timeline.signer_wallet_added : timeline.inheritance_wallet_added,
          description: isSigner ? _timelineParentWalletDescription() : _timelineBeneficiaryWalletDescription(),
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: timeline.inheritance_wallet_restored,
          description: '',
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: timeline.inheritance_wallet_activation,
          description: timeline.active_after(dateTime: activationDateTimeText),
          status: TimelineStepStatus.future,
        ),
      ],
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

  String _timelineParentWalletDescription() {
    final masterFingerprint = _timelineInfo?.parentMasterFingerprint ?? '';
    return masterFingerprint.isEmpty
        ? ''
        : t.taproot.taproot_import_screen.timeline.taproot_wallet_with_mfp(mfp: masterFingerprint);
  }

  String _timelineBeneficiaryWalletDescription() {
    final masterFingerprint = _timelineInfo?.childMasterFingerprint ?? '';
    return masterFingerprint.isEmpty
        ? ''
        : t.taproot.taproot_import_screen.timeline.taproot_wallet_with_mfp(mfp: masterFingerprint);
  }

  String get _activationDateTimeText {
    final beneficiaries = _viewModel.scannedVaultItem?.beneficiaries;
    final lockTime = beneficiaries == null || beneficiaries.isEmpty ? null : beneficiaries.first.lockTime;
    if (lockTime == null) {
      return '';
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(lockTime * Duration.millisecondsPerSecond);
    final hourOfPeriod = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final periodText = dateTime.hour < 12 ? t.bottom_sheet.date_picker.am : t.bottom_sheet.date_picker.pm;
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 '
        '$periodText ${hourOfPeriod.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  void _toggleImportMode() {
    if (_viewModel.currentImportMode == ImportMode.enter) {
      _viewModel.setImportMode(ImportMode.scan);
    } else {
      _viewModel.setImportMode(ImportMode.enter);
    }
  }

  Future<void> _handleBottomButtonPressed() async {
    if (_currentStep == _roleSelectionStep && _viewModel.selectedRole == TaprootImportRole.none) {
      return;
    }

    await _currentNextButtonAction?.call();
  }

  void _handleBackPressed() {
    if (_isProcessingImport) {
      return;
    }

    if (_isTimelineStep) {
      _navigateToHome();
      return;
    }

    if (_currentStep <= 1) {
      Navigator.pop(context);
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
      if (_currentStep == _importWalletStep) {
        _importWalletStep = null;
      }
      if (_currentStep == _importResultStep) {
        _importResultStep = null;
      }
      if (_currentStep == _timelineStep) {
        _timelineStep = null;
      }
      _currentStep -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showBottomButton = _showBottomButton;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PopScope(
        canPop: _currentStep <= 1,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }
          _handleBackPressed();
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: CoconutColors.white,
              appBar: CoconutAppBar.build(
                title: t.taproot.taproot_import_screen.title,
                context: context,
                isBottom: _isTimelineStep,
                backgroundColor: CoconutColors.white,
                onBackPressed: _handleBackPressed,
                actionButtonList: [
                  Visibility(
                    visible: _showImportModeToggle,
                    child: IconButton(
                      icon: _viewModel.currentImportMode == ImportMode.enter
                          ? SvgPicture.asset('assets/svg/scan.svg')
                          : SvgPicture.asset('assets/svg/paste.svg'),
                      color: CoconutColors.black,
                      onPressed: _toggleImportMode,
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: Stack(
                  children: [
                    TaprootCreationBody(
                      titleLines: _titleLines(),
                      onBottomButtonPressed: showBottomButton ? _handleBottomButtonPressed : null,
                      onBeforeBottomButtonFadeOut: _handleBeforeBottomButtonFadeOut,
                      bottomButtonText: _bottomButtonText,
                      showBottomButton: showBottomButton,
                      ignoreChildHorizontalPadding: _ignoreBodyHorizontalPaddingList[_currentStep - 1],
                      showHeader: _showHeader,
                      scrollChild: !_isProgressPaused && _scrollChildList[_currentStep - 1],
                      runBottomButtonActionWithoutTransition: _runBottomButtonActionWithoutTransition,
                      keepHeaderVisibleDuringTransition: _isTimelineStep,
                      child: _isProgressPaused
                          ? _bodyList[_currentStep - 1].first
                          : Column(children: _bodyList[_currentStep - 1]),
                    ),
                    TopProgressBar(
                      visible: !_isProgressPaused,
                      total: _progressTotalStep,
                      current: _progressCurrentStep,
                    ),
                  ],
                ),
              ),
            ),
            if (_isProcessingImport)
              const Positioned.fill(child: AbsorbPointer(child: Center(child: CoconutCircularIndicator()))),
          ],
        ),
      ),
    );
  }
}
