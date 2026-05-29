import 'dart:convert';
import 'dart:typed_data';
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/widgets/box/info_box.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_setup_summary_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_vault_item_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/child_creation_view_model.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/mnemonic_view_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_dice_roll_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/security_self_check_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  int _progressCurrentStep(ChildCreationViewModel viewModel) {
    int embeddedStartIndex = _currentVaultSelectionStep != null ? 4 : 3;

    final currentStep = switch (_currentStep) {
      _ when _currentStep <= embeddedStartIndex => _currentStep - _progressInitialStepCount,
      _ when _currentStep <= embeddedStartIndex + _embeddedWidgets.length =>
        embeddedStartIndex - _progressInitialStepCount,
      _ => _currentStep - _embeddedWidgets.length - _progressInitialStepCount,
    };

    return currentStep.clamp(0, viewModel.progressTotalStep);
  }

  List<TextSpan> _titleLines(ChildCreationViewModel viewModel) {
    int embeddedStartIndex = _currentVaultSelectionStep != null ? 4 : 3;
    final titles = _buildTitleList(viewModel);

    List<TextSpan> textList;
    if (_currentStep <= embeddedStartIndex) {
      textList = titles[_currentStep - 1];
    } else if (_currentStep <= embeddedStartIndex + _embeddedWidgets.length) {
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
    return MenuGrid(
      children: [
        SelectableOptionCard(
          title: t.taproot.common.prepare_key_option1_title,
          description: t.taproot.common.prepare_key_option1_desc,
          bottomAssetPath: 'assets/png/wallet.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: viewModel.keyPreparationType == ChildKeyPreparationType.create,
          height: 217,
          onTap: () {
            viewModel.setKeyPreparationType(ChildKeyPreparationType.create);
          },
        ),
        SelectableOptionCard(
          title: t.taproot.common.prepare_key_option2_title,
          description: t.taproot.common.prepare_key_option2_desc,
          bottomAssetPath: 'assets/png/key-holder.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: viewModel.keyPreparationType == ChildKeyPreparationType.import,
          height: 217,
          onTap: () {
            viewModel.setKeyPreparationType(ChildKeyPreparationType.import);
          },
        ),
      ],
    );
  }

  Widget _buildChildCreationOptionStep(ChildCreationViewModel viewModel) {
    if (viewModel.keyPreparationType == ChildKeyPreparationType.create) {
      return MenuGrid(
        children: [
          SelectableOptionCard(
            title: t.taproot.common.new_option1,
            bottomAssetPath: 'assets/png/coin.png',
            imageScale: 4.0,
            imageWidth: 67,
            isSelected: viewModel.newKeyCreationType == ChildNewKeyCreationType.coinFlip,
            height: 118,
            onTap: () {
              viewModel.setNewKeyCreationType(ChildNewKeyCreationType.coinFlip);
            },
          ),
          SelectableOptionCard(
            title: t.taproot.common.new_option2,
            bottomAssetPath: 'assets/png/dice.png',
            imageScale: 4.0,
            imageWidth: 67,
            isSelected: viewModel.newKeyCreationType == ChildNewKeyCreationType.diceRoll,
            height: 118,
            onTap: () {
              viewModel.setNewKeyCreationType(ChildNewKeyCreationType.diceRoll);
            },
          ),
          SelectableOptionCard(
            title: t.taproot.common.new_option3,
            bottomAssetPath: 'assets/png/gear.png',
            imageScale: 4.0,
            imageWidth: 67,
            isSelected: viewModel.newKeyCreationType == ChildNewKeyCreationType.autoGenerate,
            height: 118,
            onTap: () {
              viewModel.setNewKeyCreationType(ChildNewKeyCreationType.autoGenerate);
            },
          ),
        ],
      );
    } else {
      return Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final hasNoSingleSigVault = walletProvider.getVaultsByWalletType(WalletType.singleSignature).isEmpty;
          return MenuGrid(
            children: [
              SelectableOptionCard(
                title: t.taproot.common.existing_option1,
                isDisabled: hasNoSingleSigVault,
                bottomAssetPath: 'assets/png/finger-picking.png',
                imageScale: 4.0,
                imageWidth: 67,
                isSelected: viewModel.existingKeyImportType == ChildExistingKeyImportType.currentVault,
                height: 118,
                onDisabledTap: () {
                  CoconutToast.showToast(
                    context: context,
                    level: CoconutToastLevel.info,
                    isVisibleIcon: true,
                    text: t.taproot.common.existing_option1_toast,
                  );
                },
                onTap: () {
                  viewModel.setExistingKeyImportType(ChildExistingKeyImportType.currentVault);
                },
              ),
              SelectableOptionCard(
                title: t.taproot.common.existing_option2,
                bottomAssetPath: 'assets/png/word.png',
                imageScale: 4.0,
                imageWidth: 67,
                isSelected: viewModel.existingKeyImportType == ChildExistingKeyImportType.mnemonicInput,
                height: 118,
                onTap: () {
                  viewModel.setExistingKeyImportType(ChildExistingKeyImportType.mnemonicInput);
                },
              ),
              SelectableOptionCard(
                title: t.taproot.common.existing_option3,
                bottomAssetPath: 'assets/png/scan-qr.png',
                imageScale: 4.0,
                imageWidth: 67,
                isSelected: viewModel.existingKeyImportType == ChildExistingKeyImportType.seedQrScan,
                height: 118,
                onTap: () {
                  viewModel.setExistingKeyImportType(ChildExistingKeyImportType.seedQrScan);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildScannerStep(ChildCreationViewModel viewModel) {
    return TaprootScannerScreen(
      hasAppbar: false,
      topGuideWidget: Positioned(top: 80, left: 24, right: 24, child: _buildScannerTitle(viewModel)),
      onTaprootVaultScanned: (beneficiaryVault) async {
        if (_isProcessing) return false;

        vibrateExtraLight();

        final bool isValid = viewModel.setScannedTaprootVault(beneficiaryVault.descriptor);
        if (!isValid) {
          _showInvalidQrToast();
          return false;
        }

        setState(() {
          _isProcessing = true;
        });

        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return false;

        setState(() {
          _isProcessing = false;
        });
        _onNextPressed(viewModel);
        return true;
      },
    );
  }

  Widget _buildScannerTitle(ChildCreationViewModel viewModel) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.white),
        children: _titleLines(viewModel),
      ),
    );
  }

  void _showInvalidQrToast() {
    CoconutToast.showToast(context: context, level: CoconutToastLevel.error, text: t.errors.invalid_qr);
  }

  Widget _buildSummaryStep(ChildCreationViewModel viewModel) {
    if (viewModel.scannedVaultItem == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!viewModel.isBeneficiaryMatch) ...[
          CoconutLayout.spacing_1500h,
          SvgPicture.asset('assets/svg/triangle-warning.svg', width: 25, height: 25),
          CoconutLayout.spacing_200h,
          Text(
            t.taproot.child_creation_screen.step6.title2,
            style: CoconutTypography.heading3_21_Bold.setColor(CoconutColors.hotPink),
            textAlign: TextAlign.center,
          ),
          CoconutLayout.spacing_800h,
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TaprootVaultItemCard(vaultItem: viewModel.scannedVaultItem!, showTaprootWalletInfo: false),
        ),
        CoconutLayout.spacing_200h,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TaprootSetupSummaryCard(
            itemList: [
              ...viewModel.scannedVaultItem!.owners.asMap().entries.map((entry) {
                final index = entry.key;
                final owner = entry.value;
                final isSingleParent = viewModel.scannedVaultItem!.owners.length == 1;
                final parentName =
                    isSingleParent
                        ? t.taproot.parent_wallet
                        : '${t.taproot.parent_wallet} ${String.fromCharCode(65 + index)}';

                return TaprootParticipantCard(
                  role: TaprootParticipantRole.parent,
                  walletName: parentName,
                  mfp: owner.masterFingerprint,
                  derivationPath: viewModel.scannedVaultItem!.derivationPath,
                  hasSingleParent: isSingleParent,
                  hasBackgroundColor: true,
                  isMine: owner.isSeedStored,
                );
              }),
              ...viewModel.scannedVaultItem!.beneficiaries.map(
                (beneficiary) => TaprootParticipantCard(
                  role: TaprootParticipantRole.child,
                  mfp: beneficiary.masterFingerprint,
                  derivationPath: viewModel.scannedVaultItem!.derivationPath,
                  locktime: beneficiary.lockTime,
                  hasBackgroundColor: true,
                  isMine: beneficiary.isSeedStored || beneficiary.masterFingerprint == viewModel.masterFingerprint,
                  isValid: beneficiary.masterFingerprint == viewModel.masterFingerprint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(ChildCreationViewModel viewModel) {
    final lang = context.read<VisibilityProvider>().language;
    final dateString = viewModel.getFormattedLockTime(lang);

    return TimelineStepIndicator(
      timelineStepItemList: [
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.created_wallet,
          description: t.taproot.child_creation_screen.step7.timeline.singlesig_description(
            mfp: viewModel.masterFingerprint ?? '000000',
          ),
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.exported_to_parent,
          description: t.taproot.child_creation_screen.step7.timeline.taproot_description(
            mfp: viewModel.scannedParentMfps,
          ),
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.imported_inheritance_info,
          description:
              '${viewModel.scannedVaultItem?.name ?? 'Name'} | ${viewModel.scannedVaultItem?.owners.length == 1 ? t.taproot.child_creation_screen.step7.timeline.single_sig_wallet : t.taproot.child_creation_screen.step7.timeline.multisig_wallet}',
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.active_inheritance_wallet,
          description: t.taproot.child_creation_screen.step7.timeline.time_after(date: dateString),
          status: TimelineStepStatus.future,
        ),
      ],
    );
  }

  Widget _getCurrentChild(ChildCreationViewModel viewModel) {
    int embeddedStartIndex = _currentVaultSelectionStep != null ? 4 : 3;

    if (_currentStep > embeddedStartIndex && _currentStep <= embeddedStartIndex + _embeddedWidgets.length) {
      return _embeddedWidgets[_currentStep - embeddedStartIndex - 1];
    }

    int baseCurrentStep = _currentStep;
    if (_currentStep > embeddedStartIndex + _embeddedWidgets.length) {
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
    return Padding(
      padding: const EdgeInsets.only(top: 21),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (viewModel.qrData != null && viewModel.qrData!.isNotEmpty)
            AdaptiveQrImage(qrData: viewModel.qrData!)
          else
            const SizedBox(height: 200), // QR 데이터가 없을 때 영역 확보용 위젯
          CoconutLayout.spacing_500h,
          InfoBox(
            infoList: [
              MapEntry(t.wallet_type, t.taproot.child_creation_screen.step4.taproot_single_sig_wallet),
              MapEntry(t.mfp, viewModel.masterFingerprint ?? '00000000'),
            ],
          ),
        ],
      ),
    );
  }

  bool _isNextButtonVisible(ChildCreationViewModel viewModel) {
    if (_currentStep == _currentVaultSelectionStep) {
      return viewModel.existingVaultId != null;
    }
    int embeddedStartIndex = _currentVaultSelectionStep != null ? 4 : 3;
    if (_currentStep > embeddedStartIndex && _currentStep <= embeddedStartIndex + _embeddedWidgets.length) {
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
    int baseCurrentStep = _currentStep > embeddedStartIndex ? _currentStep - _embeddedWidgets.length : _currentStep;

    if (baseCurrentStep == scannerStepIndex) {
      return false;
    }

    return true;
  }

  void _addEmbeddedStep(Widget widget) {
    setState(() {
      _embeddedWidgets.add(widget);
      _currentStep += 1;
    });
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
    final calledFrom = switch (viewModel.newKeyCreationType) {
      ChildNewKeyCreationType.coinFlip => AppRoutes.mnemonicCoinflip,
      ChildNewKeyCreationType.diceRoll => AppRoutes.mnemonicDiceRoll,
      ChildNewKeyCreationType.autoGenerate => AppRoutes.mnemonicVerify,
      ChildNewKeyCreationType.none => AppRoutes.mnemonicAutoGen,
    };

    if (calledFrom == AppRoutes.mnemonicVerify) {
      _addMnemonicVerifyStep();
      return;
    }

    _addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: calledFrom,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicReady: _addMnemonicVerifyStep,
      ),
    );
  }

  void _addImportedMnemonicConfirmationStep() {
    _addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: AppRoutes.mnemonicImport,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicReady: () {
          final viewModel = context.read<ChildCreationViewModel>();
          _onChildWalletSet(viewModel);
        },
      ),
    );
  }

  void _addMnemonicVerifyStep() {
    _addEmbeddedStep(
      MnemonicVerifyScreen(
        isEmbedded: true,
        isTaproot: true,
        onVerificationSuccess: _addVerifiedMnemonicConfirmationStep,
      ),
    );
  }

  void _addVerifiedMnemonicConfirmationStep() {
    _addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: AppRoutes.mnemonicVerify,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicReady: () {
          final viewModel = context.read<ChildCreationViewModel>();
          _onChildWalletSet(viewModel);
        },
      ),
    );
  }

  void _addFirstEmbeddedScreenForCreation(ChildCreationViewModel viewModel) {
    Widget? firstEmbeddedScreen;
    switch (viewModel.newKeyCreationType) {
      case ChildNewKeyCreationType.coinFlip:
        firstEmbeddedScreen = MnemonicCoinflipScreen(
          entropyType: EntropyType.manual,
          isEmbedded: true,
          isTaproot: true,
          onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
        );
        break;
      case ChildNewKeyCreationType.diceRoll:
        firstEmbeddedScreen = MnemonicDiceRollScreen(
          entropyType: EntropyType.manual,
          isEmbedded: true,
          isTaproot: true,
          onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
        );
        break;
      case ChildNewKeyCreationType.autoGenerate:
        firstEmbeddedScreen = MnemonicAutoGenScreen(
          entropyType: EntropyType.auto,
          isEmbedded: true,
          isTaproot: true,
          onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
        );
        break;
      case ChildNewKeyCreationType.none:
        return;
    }
    _addEmbeddedStep(firstEmbeddedScreen);
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
            MnemonicImportScreen(
              isEmbedded: true,
              isTaprootCreationChild: true,
              requirePassphraseConfirmation: true,
              onCompleted: _addImportedMnemonicConfirmationStep,
            ),
          );
          return;
        } else if (viewModel.existingKeyImportType == ChildExistingKeyImportType.seedQrScan) {
          _addEmbeddedStep(
            SeedQrImportScreen(
              isEmbedded: true,
              isTaproot: true,
              requirePassphraseConfirmation: true,
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

    int embeddedStartIndex = _currentVaultSelectionStep != null ? 4 : 3;
    int scannerStepIndex = _currentVaultSelectionStep != null ? 6 : 5;
    int baseCurrentStep = _currentStep > embeddedStartIndex ? _currentStep - _embeddedWidgets.length : _currentStep;

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

  void _showChildWalletResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().language,
          title: t.taproot.child_creation_screen.step4.return_dialog_title,
          description: t.taproot.child_creation_screen.step4.return_dialog_description,
          leftButtonText: t.cancel,
          rightButtonText: t.confirm,
          onTapLeft: () => Navigator.pop(dialogContext),
          onTapRight: () {
            Navigator.pop(dialogContext);
            _resetChildWalletAndReturnToOptionStep();
          },
        );
      },
    );
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

    if (_currentStep == 3 + _embeddedWidgets.length + 1) {
      _showChildWalletResetDialog();
      return;
    }

    if (_currentStep > 1) {
      setState(() {
        int embeddedStartIndex = _currentVaultSelectionStep != null ? 4 : 3;

        if (_currentStep > embeddedStartIndex && _currentStep <= embeddedStartIndex + _embeddedWidgets.length) {
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

  Widget _buildExistingVaultSelectionBody(ChildCreationViewModel viewModel) {
    const gradientHeight = 36.0;

    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final vaultList = walletProvider.getVaultsByWalletType(WalletType.singleSignature);

        return Stack(
          children: [
            ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: gradientHeight, bottom: gradientHeight),
              itemCount: vaultList.length,
              separatorBuilder: (context, index) => CoconutLayout.spacing_300h,
              itemBuilder: (context, index) {
                final vault = vaultList[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      VaultRowItem(
                        vault: vault,
                        onSelected: () {
                          if (_isProcessing) return;
                          viewModel.setExistingVaultId(vault.id);
                        },
                        isNextIconVisible: false,
                        isKeyBorderVisible: true,
                        isSelectable: !_isProcessing,
                        isSelected: viewModel.existingVaultId == vault.id,
                      ),
                      if (index == vaultList.length - 1) CoconutLayout.spacing_2000h,
                    ],
                  ),
                );
              },
            ),
            const Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: gradientHeight,
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CoconutColors.white,
                        CoconutColors.white,
                        Color(0xE6FFFFFF),
                        Color(0x99FFFFFF),
                        Color(0x33FFFFFF),
                      ],
                      stops: [0.0, 0.16, 0.36, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: gradientHeight,
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        CoconutColors.white,
                        CoconutColors.white,
                        Color(0xE6FFFFFF),
                        Color(0x99FFFFFF),
                        Color(0x33FFFFFF),
                      ],
                      stops: [0.0, 0.16, 0.36, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addCurrentVaultSelectionStep(ChildCreationViewModel viewModel) {
    setState(() {
      _currentVaultSelectionStep = 4;
      _currentStep = 4;
    });
  }

  void _switchToSeedQrImport(ChildCreationViewModel viewModel) {
    if (_embeddedWidgets.isEmpty || _embeddedWidgets.last is! MnemonicImportScreen) {
      return;
    }

    setState(() {
      _embeddedWidgets.removeLast();
      viewModel.setExistingKeyImportType(ChildExistingKeyImportType.seedQrScan);

      final taprootProvider = context.read<TaprootWalletCreationProvider>();
      _embeddedWidgets.add(
        SeedQrImportScreen(
          isEmbedded: true,
          isTaproot: true,
          requirePassphraseConfirmation: true,
          onMnemonicConfirmationRequested: (secret, passphrase) {
            taprootProvider.setSecretAndPassphrase(secret, passphrase);
            _onChildWalletSet(viewModel);
          },
        ),
      );
    });
  }

  void _switchToMnemonicImport(ChildCreationViewModel viewModel) {
    if (_embeddedWidgets.isEmpty || _embeddedWidgets.last is! SeedQrImportScreen) {
      return;
    }

    setState(() {
      _embeddedWidgets.removeLast();
      viewModel.setExistingKeyImportType(ChildExistingKeyImportType.mnemonicInput);

      _embeddedWidgets.add(
        MnemonicImportScreen(
          isEmbedded: true,
          isTaprootCreationChild: true,
          requirePassphraseConfirmation: true,
          onCompleted: _addImportedMnemonicConfirmationStep,
        ),
      );
    });
  }

  void _onCurrentVaultSelected(ChildCreationViewModel viewModel) {
    final selectedExistingVaultId = viewModel.existingVaultId;
    if (selectedExistingVaultId == null) {
      return;
    }

    final mnemonicViewKey = GlobalKey<MnemonicViewScreenState>();
    _addEmbeddedStep(
      Stack(
        children: [
          MnemonicViewScreen(
            key: mnemonicViewKey,
            walletId: selectedExistingVaultId,
            autoLoadMnemonic: false,
            isEmbedded: true,
            buildPassphraseToggle: context.read<VisibilityProvider>().isPassphraseUseEnabled,
            requirePassphraseConfirmation: true,
            onAuthCanceled: () {
              _handleBackPressed();
            },
            onNextButtonPressed: () {
              final mnemonicViewState = mnemonicViewKey.currentState;
              if (mnemonicViewState == null) {
                return;
              }

              final taprootProvider = context.read<TaprootWalletCreationProvider>();
              taprootProvider.setSecretAndPassphrase(
                mnemonicViewState.mnemonic,
                mnemonicViewState.passphrase.isNotEmpty
                    ? Uint8List.fromList(utf8.encode(mnemonicViewState.passphrase))
                    : null,
              );
              _onChildWalletSet(viewModel);
            },
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showDeviceAuthDialog(mnemonicViewKey);
    });
  }

  void _showDeviceAuthDialog(GlobalKey<MnemonicViewScreenState> mnemonicViewKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: CoconutPopup(
            languageCode: context.read<VisibilityProvider>().language,
            title: t.taproot.child_creation_screen.step3.device_auth_dialog_title,
            description: t.taproot.child_creation_screen.step3.device_auth_dialog_description,
            rightButtonText: t.confirm,
            onTapRight: () {
              _authenticateWithBiometricOrPin(PinCheckContextEnum.sensitiveAction, () {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                mnemonicViewKey.currentState?.setMnemonic();
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _authenticateWithBiometricOrPin(PinCheckContextEnum pinCheckContext, VoidCallback onSuccess) async {
    final authProvider = context.read<AuthProvider>();

    final isBiometricValid =
        pinCheckContext == PinCheckContextEnum.sensitiveAction
            ? await authProvider.isBiometricsAuthValidToAvoidDoubleAuth()
            : await authProvider.isBiometricsAuthValid();

    if (isBiometricValid && mounted) {
      onSuccess();
      return;
    }

    final pinCheckResult = await _showPinCheckBottomSheet();
    if (pinCheckResult == true && mounted) {
      onSuccess();
    }
  }

  Future<bool?> _showPinCheckBottomSheet() async {
    return await MyBottomSheet.showBottomSheet_90<bool>(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          onSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );
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
    final bool showScanButton = currentEmbeddedWidget is MnemonicImportScreen;
    final bool showTypeButton = currentEmbeddedWidget is SeedQrImportScreen;

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
