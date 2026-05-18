import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/widgets/box/info_box.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/child_creation_view_model.dart';
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

class ChildCreationScreen extends StatelessWidget {
  const ChildCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => ChildCreationViewModel(), child: const _ChildCreationScreenContent());
  }
}

class _ChildCreationScreenContent extends StatefulWidget {
  const _ChildCreationScreenContent();

  @override
  State<_ChildCreationScreenContent> createState() => _ChildCreationScreenContentState();
}

class _ChildCreationScreenContentState extends State<_ChildCreationScreenContent> {
  static const int _baseTotalStep = 5;
  int _currentStep = 1;
  final List<Widget> _embeddedWidgets = [];

  int get _totalStep => _baseTotalStep + _embeddedWidgets.length;

  int get _progressCurrentStep {
    if (_currentStep <= 3) return _currentStep - 1;
    if (_currentStep <= 3 + _embeddedWidgets.length) return 2;
    return _currentStep - _embeddedWidgets.length - 1;
  }

  List<TextSpan> _titleLines(ChildCreationViewModel viewModel) {
    List<TextSpan> textList;
    if (_currentStep <= 3) {
      textList = _titleList(viewModel)[_currentStep - 1];
    } else if (_currentStep <= 3 + _embeddedWidgets.length) {
      return [const TextSpan(text: '')];
    } else {
      textList = _titleList(viewModel)[_currentStep - _embeddedWidgets.length - 1];
    }

    if (textList.length == 1) {
      return [const TextSpan(text: ''), textList[0], const TextSpan(text: '')];
    }
    if (textList.length == 2) {
      return [textList[0], textList[1], const TextSpan(text: '')];
    }
    return textList;
  }

  List<List<TextSpan>> _titleList(ChildCreationViewModel viewModel) => [
    [
      TextSpan(text: t.taproot.child_creation_screen.step1.title1),
      TextSpan(text: t.taproot.child_creation_screen.step1.title2),
    ],
    [
      TextSpan(text: t.taproot.child_creation_screen.step2.title1),
      TextSpan(text: t.taproot.child_creation_screen.step2.title2),
    ],
    viewModel.isCreateKeySelected
        ? [TextSpan(text: t.taproot.child_creation_screen.step3.title_new)]
        : [TextSpan(text: t.taproot.child_creation_screen.step3.title_existing)],
    [
      TextSpan(text: t.taproot.child_creation_screen.step4.title1),
      TextSpan(text: t.taproot.child_creation_screen.step4.title2, style: CoconutTypography.body1_16),
      TextSpan(text: t.taproot.child_creation_screen.step4.title3, style: CoconutTypography.body1_16),
    ],
    [
      TextSpan(text: t.taproot.child_creation_screen.step5.title1),
      TextSpan(text: t.taproot.child_creation_screen.step5.title2),
    ],
    [TextSpan(text: t.taproot.child_creation_screen.step6.title1)],
  ];

  List<Widget> _childList(ChildCreationViewModel viewModel) => [
    Center(child: Image.asset('assets/png/load-wallet.png', scale: 4.0, width: 210)),
    MenuGrid(
      children: [
        SelectableOptionCard(
          title: t.taproot.common.prepare_key_option1_title,
          description: t.taproot.common.prepare_key_option1_desc,
          bottomAssetPath: 'assets/png/wallet.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: viewModel.isCreateKeySelected,
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
          isSelected: viewModel.isImportKeySelected,
          height: 217,
          onTap: () {
            viewModel.setKeyPreparationType(ChildKeyPreparationType.import);
          },
        ),
      ],
    ),
    viewModel.isCreateKeySelected
        ? MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.common.new_option1,
              bottomAssetPath: 'assets/png/coin.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isCoinFlipSelected,
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
              isSelected: viewModel.isDiceRollSelected,
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
              isSelected: viewModel.isAutoGenerateSelected,
              height: 118,
              onTap: () {
                viewModel.setNewKeyCreationType(ChildNewKeyCreationType.autoGenerate);
              },
            ),
          ],
        )
        : MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.common.existing_option1,
              bottomAssetPath: 'assets/png/finger-picking.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isCurrentVaultSelected,
              height: 118,
              onTap: () {
                viewModel.setExistingKeyImportType(ChildExistingKeyImportType.currentVault);
              },
            ),
            SelectableOptionCard(
              title: t.taproot.common.existing_option2,
              bottomAssetPath: 'assets/png/word.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isMnemonicInputSelected,
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
              isSelected: viewModel.isSeedQrScanSelected,
              height: 118,
              onTap: () {
                viewModel.setExistingKeyImportType(ChildExistingKeyImportType.seedQrScan);
              },
            ),
          ],
        ),
    _buildQrSection(viewModel),
    const TimelineStepIndicator(
      timelineStepItemList: [
        TimelineStepItem(
          title: '부모 지갑 연결',
          description: '단일 서명 지갑과 연결됨 (MFP: 000000)',
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: '자식 지갑 설정',
          description: '탭루트 자식 지갑 (MFP: 000000)',
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(title: '기간 설정', description: '2030년 2월 16일 오전 09:21', status: TimelineStepStatus.upcoming),
        TimelineStepItem(
          title: '자식 지갑 활성화',
          description: '2030년 2월 16일 오전 09:21 이후',
          status: TimelineStepStatus.future,
        ),
      ],
    ),
  ];

  Widget _getCurrentChild(ChildCreationViewModel viewModel) {
    if (_currentStep <= 3) {
      return _childList(viewModel)[_currentStep - 1];
    }
    if (_currentStep <= 3 + _embeddedWidgets.length) {
      return _embeddedWidgets[_currentStep - 4];
    }
    return _childList(viewModel)[_currentStep - _embeddedWidgets.length - 1];
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
    if (_currentStep > 3 && _currentStep <= 3 + _embeddedWidgets.length) {
      return false;
    }
    if (_currentStep == 2) {
      return viewModel.selectedKeyPreparationType != ChildKeyPreparationType.none;
    }
    if (_currentStep == 3) {
      if (viewModel.isCreateKeySelected) {
        return viewModel.selectedNewKeyCreationType != ChildNewKeyCreationType.none;
      } else {
        return viewModel.selectedExistingKeyImportType != ChildExistingKeyImportType.none;
      }
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
    final taprootProvider = context.read<TaprootWalletCreationProvider>();
    try {
      viewModel.generateKeyData(taprootProvider.secret, taprootProvider.passphrase);
      setState(() {
        _currentStep += 1;
      });
    } catch (e) {
      Logger.error('Failed to generate child wallet: $e');
    }
  }

  void _addMnemonicConfirmationStep() {
    final viewModel = context.read<ChildCreationViewModel>();
    final calledFrom = switch (viewModel.selectedNewKeyCreationType) {
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
    switch (viewModel.selectedNewKeyCreationType) {
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
    final taprootProvider = context.read<TaprootWalletCreationProvider>();

    if (_currentStep == 3) {
      taprootProvider.setCreationType(TaprootCreationType.child);

      if (viewModel.isCreateKeySelected) {
        _addEmbeddedStep(
          SecuritySelfCheckScreen(
            isEmbedded: true,
            onNextPressed: () {
              _addFirstEmbeddedScreenForCreation(viewModel);
            },
          ),
        );
        return;
      } else if (viewModel.isImportKeySelected) {
        if (viewModel.isMnemonicInputSelected) {
          _addEmbeddedStep(
            MnemonicImportScreen(isEmbedded: true, isTaproot: true, onCompleted: () => _onChildWalletSet(viewModel)),
          );
          return;
        } else if (viewModel.isSeedQrScanSelected) {
          _addEmbeddedStep(
            SeedQrImportScreen(
              isEmbedded: true,
              isTaproot: true,
              onMnemonicConfirmationRequested: (secret, passphrase) {
                taprootProvider.setSecretAndPassphrase(secret, passphrase);
                _onChildWalletSet(viewModel);
              },
            ),
          );
          return;
        }
      }
    }

    if (_currentStep >= _totalStep) {
      return;
    }

    setState(() {
      _currentStep += 1;
    });
  }

  void _handleBackPressed() {
    if (_currentStep > 1) {
      setState(() {
        if (_currentStep > 3 && _currentStep <= 3 + _embeddedWidgets.length) {
          _embeddedWidgets.removeLast();
        }
        _currentStep -= 1;
      });

      final viewModel = context.read<ChildCreationViewModel>();
      if (_currentStep == 1) {
        viewModel.setKeyPreparationType(ChildKeyPreparationType.none);
      } else if (_currentStep == 2) {
        viewModel.setNewKeyCreationType(ChildNewKeyCreationType.none);
        viewModel.setExistingKeyImportType(ChildExistingKeyImportType.none);
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChildCreationViewModel>();
    final isEmbeddedActive = _currentStep > 3 && _currentStep <= 3 + _embeddedWidgets.length;

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
        ),
        body: SafeArea(
          child: Stack(
            children: [
              TaprootCreationBody(
                key: ValueKey(_currentStep),
                titleLines: _titleLines(viewModel),
                showBottomButton: _isNextButtonVisible(viewModel),
                ignoreChildHorizontalPadding: isEmbeddedActive,
                showHeader: !isEmbeddedActive,
                scrollChild: !isEmbeddedActive,
                onBottomButtonPressed: () => _onNextPressed(viewModel),
                child: Container(child: _getCurrentChild(viewModel)),
              ),
              TopProgressBar(visible: !isEmbeddedActive, total: _baseTotalStep - 1, current: _progressCurrentStep),
            ],
          ),
        ),
      ),
    );
  }
}
