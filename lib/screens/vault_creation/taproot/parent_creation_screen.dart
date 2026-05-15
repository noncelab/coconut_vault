import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/extensions/widget_animation_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/parent_creation_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
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
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/mnemonic_view_screen.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParentCreationScreen extends StatefulWidget {
  const ParentCreationScreen({super.key});

  @override
  State<ParentCreationScreen> createState() => _ParentCreationScreenState();
}

class _ParentCreationScreenState extends State<ParentCreationScreen> {
  static const int _initialStepCount = 2;
  static const int _progressTotalStep = 6;

  final ParentCreationViewModel _viewModel = ParentCreationViewModel();
  late final List<List<TextSpan>> _titleList;
  late final List<List<Widget>> _bodyList;
  late final List<VoidCallback?> _nextButtonActions;
  late final List<bool> _ignoreBodyHorizontalPaddingList;
  late final List<bool> _pauseProgressList;
  late final List<bool> _scrollChildList;
  int _currentStep = 1;
  int? _keyPreparationStep;
  int? _keyCreationOrImportOptionStep;
  int? _childWalletSetupStep;

  bool get _hasNextBuiltStep => _currentStep < _titleList.length;

  @override
  void initState() {
    super.initState();
    _titleList = _initialTitleList();
    _bodyList = _initialBodyList();
    _nextButtonActions = [_moveToNextStep, _confirmWalletType];
    _ignoreBodyHorizontalPaddingList = [false, false];
    _pauseProgressList = [false, false];
    _scrollChildList = [true, true];
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
            : _viewModel.hasSelectedKeyCreationOrImportOption,
      5 =>
        _viewModel.selectedWalletType == ParentWalletType.multisig
            ? _viewModel.hasSelectedKeyCreationOrImportOption
            : true,
      _ => true,
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
                  isSelected: viewModel.selectedNewKeyCreationType == ParentNewKeyCreationType.coinFlip,
                  height: 118,
                  onTap: () => viewModel.setNewKeyCreationType(ParentNewKeyCreationType.coinFlip),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.new_option2,
                  bottomAssetPath: 'assets/png/dice.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.selectedNewKeyCreationType == ParentNewKeyCreationType.diceRoll,
                  height: 118,
                  onTap: () => viewModel.setNewKeyCreationType(ParentNewKeyCreationType.diceRoll),
                ),
                SelectableOptionCard(
                  title: t.taproot.common.new_option3,
                  bottomAssetPath: 'assets/png/gear.png',
                  imageScale: 4.0,
                  imageWidth: 67,
                  isSelected: viewModel.selectedNewKeyCreationType == ParentNewKeyCreationType.autoGenerate,
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
                  isSelected: viewModel.selectedExistingKeyImportType == ParentExistingKeyImportType.currentVault,
                  height: 118,
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
        isTaprootChild: false,
        onMnemonicReady: _addMnemonicVerifyStep,
      ),
    );
  }

  void _addMnemonicVerifyStep() {
    _addEmbeddedStep(
      MnemonicVerifyScreen(
        isEmbedded: true,
        isTaprootChild: false,
        onVerificationSuccess: _addVerifiedMnemonicConfirmationStep,
      ),
    );
  }

  void _addVerifiedMnemonicConfirmationStep() {
    _addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: AppRoutes.mnemonicVerify,
        isEmbedded: true,
        isTaprootChild: false,
        onMnemonicReady: () {
          final walletCreationProvider = context.read<WalletCreationProvider>();
          _onParentWalletSet(walletCreationProvider.secret, passphrase: walletCreationProvider.passphrase);
        },
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
            isTaprootChild: false,
            onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
          ),
          ParentNewKeyCreationType.diceRoll => MnemonicDiceRollScreen(
            entropyType: EntropyType.manual,
            isEmbedded: true,
            isTaprootChild: false,
            onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
          ),
          ParentNewKeyCreationType.autoGenerate => MnemonicAutoGenScreen(
            entropyType: EntropyType.auto,
            isEmbedded: true,
            isTaprootChild: false,
            onMnemonicConfirmationRequested: _addMnemonicConfirmationStep,
          ),
          ParentNewKeyCreationType.none => null,
        };
      case ParentKeyPreparationType.import:
        return switch (_viewModel.selectedExistingKeyImportType) {
          ParentExistingKeyImportType.currentVault => null,
          ParentExistingKeyImportType.mnemonicInput => MnemonicImportScreen(
            isEmbedded: true,
            isTaprootChild: false,
            onCompleted: _addImportedMnemonicViewStep,
          ),
          ParentExistingKeyImportType.seedQrScan => SeedQrImportScreen(
            isEmbedded: true,
            isTaprootChild: false,
            onMnemonicConfirmationRequested: (secret, passphrase) {
              _onParentWalletSet(secret, passphrase: passphrase);
            },
          ),
          ParentExistingKeyImportType.none => null,
        };
      case ParentKeyPreparationType.none:
        return null;
    }
  }

  void _addCurrentVaultSelectionStep() {
    final titleList = [
      TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_1),
      TextSpan(text: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_title_2),
    ];
    final bodyList = [Expanded(child: _buildExistingVaultSelectionBody())];

    _addStep(
      titleList: titleList,
      bodyList: bodyList,
      nextButtonAction: _onCurrentVaultSelected,
      scrollChild: false,
      ignoreBodyHorizontalPadding: true,
    );
  }

  void _onCurrentVaultSelected() {
    final selectedExistingVaultId = _viewModel.selectedExistingVaultId;
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
            onAuthCanceled: _returnToPreviousStep,
            onNextButtonPressed: () {
              final mnemonicViewState = mnemonicViewKey.currentState;
              if (mnemonicViewState == null) {
                return;
              }

              _onParentWalletSet(
                mnemonicViewState.mnemonic,
                passphrase: Uint8List.fromList(utf8.encode(mnemonicViewState.passphrase)),
              );
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

  /// STEP 2: 부모 지갑 설정 완료 -> 자식 지갑 설정 차례 진입
  void _onParentWalletSet(Uint8List secret, {Uint8List? passphrase}) {
    debugPrint('Step2로 이동');
    final taprootWalletCreationProvider = context.read<TaprootWalletCreationProvider>();
    taprootWalletCreationProvider.setSecretAndPassphrase(secret, passphrase);

    /// TODO: TaprootWalletCreationProvider에 선택한 기존 니모닉 정보 저장 로직 추가
    debugPrint(taprootWalletCreationProvider.secret.toString());

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
                isSelected: false,
                onTap: () {},
                imageWidth: 100,
                height: 195,
              ),
              SelectableOptionCard(
                title: t.taproot.parent_creation_screen.step_2.creation_script_path_create,
                description: t.taproot.parent_creation_screen.step_2.creation_script_path_create_description,
                bottomAssetPath: 'assets/png/load-wallet.png',
                imageScale: 3.8,
                isSelected: false,
                onTap: () {},
                imageWidth: 100,
                height: 195,
              ),
            ],
          );
        },
      ),
    ];
    _childWalletSetupStep = _addStep(titleList: titleList, bodyList: bodyList, nextButtonAction: () {});
  }

  void _addImportedMnemonicViewStep() {
    final mnemonicViewKey = GlobalKey<MnemonicViewScreenState>();
    _addEmbeddedStep(
      MnemonicViewScreen(
        key: mnemonicViewKey,
        initialMnemonic: context.read<WalletCreationProvider>().secret,
        autoLoadMnemonic: false,
        isEmbedded: true,
        onNextButtonPressed: () {
          final mnemonicViewState = mnemonicViewKey.currentState;
          if (mnemonicViewState == null) {
            return;
          }

          final walletCreationProvider = context.read<WalletCreationProvider>();
          final passphrase =
              mnemonicViewState.passphrase.isNotEmpty
                  ? Uint8List.fromList(utf8.encode(mnemonicViewState.passphrase))
                  : walletCreationProvider.passphrase;

          _onParentWalletSet(mnemonicViewState.mnemonic, passphrase: passphrase);
        },
      ),
    );
  }

  void _showDeviceAuthDialog(GlobalKey<MnemonicViewScreenState> mnemonicViewKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().language,
          title: '기기 인증 진행',
          description: '기기 보안 영역에 저장된 니모닉에 접근하기 위해 기기 인증을 진행합니다.',
          rightButtonText: t.confirm,
          onTapRight: () async {
            final pinCheckResult = await _showPinCheckBottomSheet();
            if (pinCheckResult != true || !context.mounted) {
              return;
            }

            Navigator.of(context).pop();
            mnemonicViewKey.currentState?.setMnemonic();
          },
        );
      },
    );
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

  void _handleBackPressed() {
    if (_currentStep <= 1) {
      Navigator.pop(context);
      return;
    }

    if (_currentStep == _childWalletSetupStep) {
      _showParentWalletResetDialog();
      return;
    }

    _returnToPreviousStep();
  }

  void _showParentWalletResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().language,
          title: t.taproot.parent_creation_screen.step_2.return_dialog_title,
          description: t.taproot.parent_creation_screen.step_2.return_dialog_description,
          leftButtonText: t.cancel,
          rightButtonText: t.confirm,
          onTapLeft: () => Navigator.pop(dialogContext),
          onTapRight: () {
            Navigator.pop(dialogContext);
            _resetParentWalletAndReturnToKeyOptionStep();
          },
        );
      },
    );
  }

  void _resetParentWalletAndReturnToKeyOptionStep() {
    final targetStep = _keyCreationOrImportOptionStep;
    if (targetStep == null || targetStep < 1 || targetStep > _titleList.length) {
      _returnToPreviousStep();
      return;
    }

    context.read<TaprootWalletCreationProvider>().resetSecretAndPassphrase();

    setState(() {
      while (_titleList.length > targetStep) {
        final lastIndex = _titleList.length - 1;
        _titleList.removeAt(lastIndex);
        _bodyList.removeAt(lastIndex);
        _nextButtonActions.removeAt(lastIndex);
        _ignoreBodyHorizontalPaddingList.removeAt(lastIndex);
        _pauseProgressList.removeAt(lastIndex);
        _scrollChildList.removeAt(lastIndex);
      }

      _currentStep = targetStep;
      _childWalletSetupStep = null;
    });
    _resetSelectionForBackNavigation();
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
      _ignoreBodyHorizontalPaddingList.removeAt(currentStepIndex);
      _pauseProgressList.removeAt(currentStepIndex);
      _scrollChildList.removeAt(currentStepIndex);
      _currentStep -= 1;
    });
    _resetSelectionForBackNavigation(previousStep: previousStep);
  }

  void _resetSelectionForBackNavigation({int? previousStep}) {
    if (_currentStep <= 2 || previousStep == 2) {
      _viewModel.resetSelection(ParentSelectionResetScope.walletType);
      _keyPreparationStep = null;
      _keyCreationOrImportOptionStep = null;
      _childWalletSetupStep = null;
      return;
    }

    if (_currentStep == _keyPreparationStep || previousStep == _keyPreparationStep) {
      _viewModel.resetSelection(ParentSelectionResetScope.keyPreparation);
      _keyCreationOrImportOptionStep = null;
      _childWalletSetupStep = null;
      return;
    }

    if (_currentStep == _keyCreationOrImportOptionStep || previousStep == _keyCreationOrImportOptionStep) {
      _viewModel.resetSelection(ParentSelectionResetScope.keyCreationOrImportOption);
      _childWalletSetupStep = null;
    }
  }

  Widget _buildExistingVaultSelectionBody() {
    const gradientHeight = 36.0;

    return Consumer2<WalletProvider, ParentCreationViewModel>(
      builder: (context, walletProvider, viewModel, child) {
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
                          viewModel.setSelectedExistingVaultId(vault.id);
                        },
                        isNextIconVisible: false,
                        isKeyBorderVisible: true,
                        isSelectable: true,
                        isSelected: viewModel.selectedExistingVaultId == vault.id,
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
            backgroundColor: CoconutColors.white,
            onBackPressed: _handleBackPressed,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                TaprootCreationBody(
                  titleLines: _titleLines(),
                  onBottomButtonPressed: _onNextPressed,
                  ignoreChildHorizontalPadding: _ignoreBodyHorizontalPaddingList[_currentStep - 1],
                  showHeader: !_isProgressPaused,
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
      ),
    );
  }
}
