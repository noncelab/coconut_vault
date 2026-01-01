import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/signer_assignment_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/select_external_wallet_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/import_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_key_list_bottom_sheet.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AssignedVaultListItem {
  int index;
  SignerBsms? bsms;
  SingleSigVaultListItem? singleSigVaultListItem;
  String? memo;
  HardwareWalletType? signerSource;
  ImportKeyType? importKeyType;

  AssignedVaultListItem({
    required this.index,
    required this.importKeyType,
    required this.singleSigVaultListItem,
    this.bsms,
  });
  void reset() {
    bsms = singleSigVaultListItem = importKeyType = memo = signerSource = null;
  }

  @override
  String toString() =>
      '[index]: ${t.multisig.nth_key(index: index + 1)}\n[item]: ${singleSigVaultListItem.toString()}\nmemo: $memo\nsignerSource: $signerSource';
}

enum DialogType {
  reselectQuorum,
  quit,
  back,
  notAvailable,
  deleteKey,
  alreadyExist,
  cancelImport,
  sameWithInternalOne, // '가져오기' 한 지갑이 내부에 있는 지갑 중 하나일 때
}

// internal = 이 볼트에 있는 키 사용 external = 외부에서 가져오기
enum ImportKeyType { internal, external }

class SignerAssignmentScreen extends StatefulWidget {
  const SignerAssignmentScreen({super.key});

  @override
  State<SignerAssignmentScreen> createState() => _SignerAssignmentScreenState();
}

class SignerOption {
  final SingleSigVaultListItem singlesigVaultListItem;
  final SignerBsms signerBsms;
  late final String masterFingerprint;

  SignerOption(this.singlesigVaultListItem, this.signerBsms) {
    masterFingerprint = (singlesigVaultListItem.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
  }
}

class _SignerAssignmentScreenState extends State<SignerAssignmentScreen> {
  bool _isFinishing = false;
  bool _isNextProcessing = false;
  bool _alreadyDialogShown = false;
  late SignerAssignmentViewModel _viewModel;
  late DraggableScrollableController _draggableController;
  final ValueNotifier<bool> _isButtonActiveNotifier = ValueNotifier<bool>(false);

  String _getDisplayName(AssignedVaultListItem item) {
    assert(item.importKeyType != null);

    if (item.importKeyType == ImportKeyType.internal) {
      return item.singleSigVaultListItem!.name;
    }
    if (item.importKeyType == ImportKeyType.external) {
      return item.bsms!.fingerprint.toUpperCase();
    }

    throw ArgumentError('Invalid import key type: ${item.importKeyType}');
  }

  // 아이콘 경로를 결정하는 헬퍼 함수
  String _getIconPath(AssignedVaultListItem item) {
    // 1. 내부 지갑인 경우
    if (item.importKeyType == ImportKeyType.internal) {
      return CustomIcons.getPathByIndex(item.singleSigVaultListItem!.iconIndex);
    }

    assert(item.signerSource != null);
    return item.signerSource!.iconPath;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!_isFinishing) _onBackPressed(context);
      },
      child: ChangeNotifierProvider<SignerAssignmentViewModel>(
        create:
            (context) =>
                _viewModel = SignerAssignmentViewModel(
                  Provider.of<WalletProvider>(context, listen: false),
                  Provider.of<WalletCreationProvider>(context, listen: false),
                ),
        child: Consumer<SignerAssignmentViewModel>(
          builder:
              (context, viewModel, child) => Scaffold(
                backgroundColor: CoconutColors.white,
                appBar: CoconutAppBar.build(
                  title: t.multisig_wallet_creation,
                  context: context,
                  onBackPressed: () => _onBackPressed(context),
                  backgroundColor: CoconutColors.white,
                ),
                body: SafeArea(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    child: Container(height: 6, color: CoconutColors.black.withValues(alpha: 0.06)),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ClipRRect(
                                        borderRadius:
                                            viewModel.getAssignedVaultListLength() / viewModel.totalSignatureCount == 1
                                                ? BorderRadius.zero
                                                : const BorderRadius.only(
                                                  topRight: Radius.circular(6),
                                                  bottomRight: Radius.circular(6),
                                                ),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                          height: 6,
                                          width:
                                              (constraints.maxWidth) *
                                              (viewModel.getAssignedVaultListLength() == 0
                                                  ? 0
                                                  : viewModel.getAssignedVaultListLength() /
                                                      viewModel.totalSignatureCount),
                                          color: CoconutColors.black,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 78),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        t.assign_signers_screen.create_multisig_wallet_by_quorum(
                                          requiredSignatureCount: viewModel.requiredSignatureCount,
                                          totalSignatureCount: viewModel.totalSignatureCount,
                                        ),
                                        style: CoconutTypography.heading4_18_Bold,
                                      ),
                                      CoconutLayout.spacing_900h,
                                      for (int i = 0; i < viewModel.assignedVaultList.length; i++) ...[
                                        Builder(
                                          builder: (context) {
                                            final signer = viewModel.assignedVaultList[i];

                                            return Column(
                                              children: [
                                                ShrinkAnimationButton(
                                                  onPressed: () {
                                                    if (signer.importKeyType != null) {
                                                      _showDialog(DialogType.deleteKey, keyIndex: i);
                                                      return;
                                                    }
                                                    MyBottomSheet.showBottomSheet_ratio(
                                                      showDragHandle: false,
                                                      context: context,
                                                      child: _buildSelectKeyOptionBottomSheet(i),
                                                    );
                                                  },
                                                  defaultColor:
                                                      signer.importKeyType != null
                                                          ? signer.importKeyType == ImportKeyType.internal
                                                              ? CoconutColors.backgroundColorPaletteLight[signer
                                                                  .singleSigVaultListItem!
                                                                  .colorIndex]
                                                              : CoconutColors.backgroundColorPaletteLight[8]
                                                          : CoconutColors.white,
                                                  pressedColor:
                                                      signer.importKeyType != null
                                                          ? signer.importKeyType == ImportKeyType.internal
                                                              ? CoconutColors
                                                                  .backgroundColorPaletteLight[signer
                                                                      .singleSigVaultListItem!
                                                                      .colorIndex]
                                                                  .withAlpha(70)
                                                              : CoconutColors.backgroundColorPaletteLight[8].withAlpha(
                                                                70,
                                                              )
                                                          : CoconutColors.gray150,
                                                  borderRadius: 100,
                                                  borderWidth: 1,
                                                  border: Border.all(
                                                    color:
                                                        signer.importKeyType != null
                                                            ? CoconutColors
                                                                .backgroundColorPaletteLight[signer
                                                                        .singleSigVaultListItem
                                                                        ?.colorIndex ??
                                                                    8]
                                                                .withAlpha(70)
                                                            : CoconutColors.gray200,
                                                    width: 1,
                                                  ),
                                                  child: Container(
                                                    width: 210,
                                                    height: 64,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    child:
                                                        signer.importKeyType != null
                                                            ? Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                SvgPicture.asset(
                                                                  _getIconPath(signer),
                                                                  colorFilter: ColorFilter.mode(
                                                                    signer.importKeyType == ImportKeyType.internal
                                                                        ? CoconutColors.colorPalette[signer
                                                                            .singleSigVaultListItem!
                                                                            .colorIndex]
                                                                        : CoconutColors.black,
                                                                    BlendMode.srcIn,
                                                                  ),
                                                                  width: 14.0,
                                                                ),
                                                                CoconutLayout.spacing_200w,
                                                                Flexible(
                                                                  child: Text(
                                                                    t.multisig.nth_key_with_name(
                                                                      name: _getDisplayName(signer),
                                                                      index: signer.index + 1,
                                                                    ),
                                                                    style: CoconutTypography.body1_16,
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    textAlign: TextAlign.center,
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                            : Center(
                                                              child: Text(
                                                                t.multisig.select_nth_key(index: signer.index + 1),
                                                                style: CoconutTypography.body1_16,
                                                              ),
                                                            ),
                                                  ),
                                                ),
                                                CoconutLayout.spacing_500h,
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Builder(
                            builder: (context) {
                              return FixedBottomButton(
                                showGradient: false,
                                backgroundColor: CoconutColors.black,
                                onButtonClicked: onNextPressed,
                                text: t.next,
                                isActive: viewModel.isAssignedKeyCompletely(),
                              );
                            },
                          ),
                        ),
                        _buildProgressIndicator(),
                        Visibility(
                          visible: _isNextProcessing,
                          child: Container(
                            decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                            child: Center(child: MessageActivityIndicator(message: viewModel.loadingMessage)),
                          ),
                        ),
                        Visibility(
                          visible: viewModel.isInitializing,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                            child: const Center(child: CircularProgressIndicator(color: CoconutColors.gray800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Stack(
        children: [
          ClipRRect(child: Container(height: 6, color: CoconutColors.black.withValues(alpha: 0.06))),
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius:
                    _viewModel.getAssignedVaultListLength() / _viewModel.totalSignatureCount == 1
                        ? BorderRadius.zero
                        : const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 6,
                  width:
                      (constraints.maxWidth) *
                      (_viewModel.getAssignedVaultListLength() == 0
                          ? 0
                          : _viewModel.getAssignedVaultListLength() / _viewModel.totalSignatureCount),
                  color: CoconutColors.black,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectKeyOptionBottomSheet(int index) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      resizeToAvoidBottomInset: false,
      appBar: CoconutAppBar.build(
        title: t.assign_signers_screen.select_key_option,
        context: context,
        onBackPressed: () => Navigator.pop(context),
        backgroundColor: CoconutColors.white,
        isBottom: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: Column(
          children: [
            _buildKeyOptionButton(
              title: t.assign_signers_screen.use_internal_key_option,
              onPressed: () => _onUseInternalKeyPressed(index),
            ),
            CoconutLayout.spacing_300h,
            _buildKeyOptionButton(
              title: t.assign_signers_screen.import_from_other_vault,
              onPressed: () => _onImportFromOtherVaultPressed(index),
            ),
            CoconutLayout.spacing_300h,
            _buildKeyOptionButton(
              title: t.assign_signers_screen.import_from_hww,
              onPressed: () => _onImportFromHwwPressed(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyOptionButton({required String title, required VoidCallback onPressed}) {
    return ShrinkAnimationButton(
      borderGradientColors: [CoconutColors.black.withValues(alpha: 0.08), CoconutColors.black.withValues(alpha: 0.08)],
      borderWidth: 1,
      borderRadius: 12,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 37),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: CoconutTypography.body1_16_Bold, textAlign: TextAlign.left),
            ),
          ),
        ),
      ),
    );
  }

  void _onUseInternalKeyPressed(int index) {
    if (_viewModel.unselectedSignerOptions.isEmpty) {
      _showDialog(DialogType.notAvailable);
      return;
    }
    MyBottomSheet.showDraggableBottomSheet(
      minChildSize: 0.5,
      maxChildSize: 0.9,
      showDragHandle: true,
      context: context,
      title: t.assign_signers_screen.use_internal_key_option,
      childBuilder:
          (scrollController) => KeyListBottomSheet(
            // 키 옵션 중 하나 선택했을 때
            onPressed: (int vaultIndex) {
              _viewModel.assignInternalSigner(vaultIndex, index);
              Navigator.pop(context); // 이 볼트에 있는 키 사용하기 다이얼로그 닫기
              Navigator.pop(context); // 키 종류 선택 다이얼로그 닫기
            },
            vaultList: _viewModel.unselectedSignerOptions.map((o) => o.singlesigVaultListItem).toList(),
            scrollController: scrollController,
          ),
    );
  }

  void _onImportFromOtherVaultPressed(int index) async {
    final SignerBsms? externalImported = await MyBottomSheet.showDraggableScrollableSheet(
      topWidget: true,
      context: context,
      physics: const ClampingScrollPhysics(),
      enableSingleChildScroll: false,
      hideAppBar: true,
      child: const SignerBsmsScannerScreen(hardwareWalletType: HardwareWalletType.coconutVault),
    );

    if (externalImported != null) {
      /// 이미 추가된 signer와 중복 비교
      if (_viewModel.isAlreadyImported(externalImported)) {
        return _showDialog(DialogType.alreadyExist);
      }

      String? sameVaultName = _viewModel.findVaultNameByBsms(externalImported);
      if (sameVaultName != null) {
        _showDialog(DialogType.sameWithInternalOne, vaultName: sameVaultName);
        return;
      }
      if (!mounted) return;
      final Map<String, String>? bsmsAndMemo = await MyBottomSheet.showBottomSheet_90(
        context: context,
        child: ImportConfirmationScreen(importingBsms: externalImported.toString(), memo: externalImported.label),
      );
      if (bsmsAndMemo != null) {
        assert(bsmsAndMemo['bsms']!.isNotEmpty);
        _viewModel.setAssignedVaultList(
          index,
          ImportKeyType.external,
          false,
          externalImported,
          bsmsAndMemo['memo'],
          HardwareWalletType.coconutVault,
        );
        if (!mounted) return;
        Navigator.pop(context); // 키 종류 선택 다이얼로그 닫기
      }
    }
  }

  void _onImportFromHwwPressed(int index) async {
    HardwareWalletType? selectedWalletType;
    final List<ExternalWalletButton> walletButtons = [];
    for (final walletType in HardwareWalletType.values) {
      if (walletType == HardwareWalletType.coconutVault) continue;
      walletButtons.add(ExternalWalletButton(name: walletType.displayName, iconSource: walletType.iconPath));
    }

    await MyBottomSheet.showBottomSheet_ratio(
      context: context,
      child: SelectExternalWalletBottomSheet(
        title: t.assign_signers_screen.hardware_wallet_type_selection,
        externalWalletButtonList: walletButtons,
        onSelected: (index) {
          selectedWalletType = HardwareWalletTypeExtension.fromDisplayName(walletButtons[index].name);
        },
      ),
    );

    if (selectedWalletType == null) return;

    if (!mounted) return;
    final SignerBsms? externalImported = await MyBottomSheet.showDraggableScrollableSheet(
      topWidget: true,
      context: context,
      physics: const ClampingScrollPhysics(),
      enableSingleChildScroll: false,
      hideAppBar: true,
      child: SignerBsmsScannerScreen(hardwareWalletType: selectedWalletType!),
    );

    Logger.log('--> SignerAssignmentScreen: externalImported: $externalImported');
    if (externalImported == null) return;

    if (_viewModel.isAlreadyImported(externalImported)) {
      return _showDialog(DialogType.alreadyExist);
    }

    String? sameVaultName = _viewModel.findVaultNameByBsms(externalImported);

    if (sameVaultName != null) {
      _showDialog(DialogType.sameWithInternalOne, vaultName: sameVaultName);
      return;
    }

    if (!mounted) return;

    final Map<String, String>? bsmsAndMemo = await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: ImportConfirmationScreen(
        importingBsms: externalImported.toString(),
        hwwType: selectedWalletType!,
        memo: externalImported.label,
      ),
    );

    if (bsmsAndMemo != null) {
      assert(bsmsAndMemo['bsms']!.isNotEmpty);

      _viewModel.setAssignedVaultList(
        index,
        ImportKeyType.external,
        false,
        externalImported,
        bsmsAndMemo['memo'],
        selectedWalletType,
      );

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _isButtonActiveNotifier.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _draggableController = DraggableScrollableController();
    _draggableController.addListener(() {
      if (_draggableController.size <= 0.71 && !_alreadyDialogShown) {
        _showDialog(DialogType.cancelImport);
      }
    });
  }

  // 외부지갑은 추가 시 올바른 signerBsms 인지 미리 확인이 되어 있어야 합니다.

  Future<void> onNextPressed() async {
    setState(() {
      _isNextProcessing = true;
    });
    _viewModel.setLoadingMessage(t.assign_signers_screen.data_verifying);

    await Future.delayed(const Duration(seconds: 2));
    List<MultisigSigner> signers = [];
    try {
      signers = await _viewModel.onSelectionCompleted();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isNextProcessing = false;
        });
        showAlertDialog(
          context: context,
          title: t.alert.wallet_creation_failed.title,
          content: t.alert.wallet_creation_failed.description,
        );
      }
      return;
    }

    // multisig 지갑 리스트에서 중복 체크 하기
    MultisigVaultListItem? existingWallet = _viewModel.findSameWallet(
      NormalizedMultisigConfig(
        name: '',
        requiredCount: _viewModel.requiredSignatureCount,
        signerBsms: signers.map((s) => s.signerBsms!).toList(),
      ),
    );
    if (existingWallet != null) {
      if (mounted) {
        CoconutToast.showToast(
          context: context,
          text: t.toast.multisig_already_added(name: existingWallet.name),
          isVisibleIcon: true,
        );
        setState(() {
          _isNextProcessing = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isNextProcessing = false;
      });
    }

    _viewModel.saveSignersToProvider(signers);
    Navigator.pushNamed(context, AppRoutes.vaultNameSetup);
  }

  void _onBackPressed(BuildContext context) {
    if (_viewModel.getAssignedVaultListLength() > 0) {
      _showDialog(DialogType.back);
    } else {
      _viewModel.resetWalletCreationProvider();
      _isFinishing = true;
      Navigator.pop(context);
    }
  }

  void _showDialog(DialogType type, {int keyIndex = 0, String? vaultName}) {
    String title = '';
    String message = '';
    String cancelButtonText = '';
    String confirmButtonText = '';
    Color confirmButtonColor = CoconutColors.black;
    VoidCallback? onCancel;
    VoidCallback onConfirm;
    bool barrierDismissible = true;

    cancelButtonText = t.no;
    confirmButtonText = t.yes;

    switch (type) {
      case DialogType.reselectQuorum:
        {
          title = t.alert.reselect.title;
          message = t.alert.reselect.description;
          confirmButtonColor = CoconutColors.warningText;
          onConfirm = () {
            _viewModel.resetWalletCreationProvider();
            _isFinishing = true;
            Navigator.popUntil(context, (route) => route.settings.name == AppRoutes.multisigQuorumSelection);
          };
          break;
        }
      case DialogType.back:
        {
          title = t.alert.back.title;
          message = t.alert.back.description;
          confirmButtonColor = CoconutColors.warningText;
          onConfirm = () {
            _viewModel.resetWalletCreationProvider();
            _isFinishing = true;
            Navigator.popUntil(context, (route) => route.settings.name == AppRoutes.multisigQuorumSelection);
          };
          break;
        }
      case DialogType.notAvailable:
        {
          title = t.alert.empty_vault.title;
          message = t.alert.empty_vault.description;
          confirmButtonColor = CoconutColors.black;
          onConfirm = () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.vaultCreationOptions,
              (Route<dynamic> route) => route.settings.name == AppRoutes.vaultTypeSelection,
            );
          };
          break;
        }
      case DialogType.quit:
        {
          title = t.alert.quit_creating_mutisig_wallet.title;
          message = t.alert.quit_creating_mutisig_wallet.description;
          confirmButtonColor = CoconutColors.warningText;
          onConfirm = () {
            _viewModel.resetWalletCreationProvider();
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
          };
          break;
        }
      case DialogType.deleteKey:
        {
          title = t.alert.reset_nth_key.title(index: keyIndex + 1);
          message = t.alert.reset_nth_key.description;
          confirmButtonColor = CoconutColors.warningText;
          onConfirm = () {
            final signer = _viewModel.assignedVaultList[keyIndex];
            // 내부 지갑인 경우
            if (signer.importKeyType == ImportKeyType.internal) {
              int insertIndex = 0;
              for (int i = 0; i < _viewModel.unselectedSignerOptions.length; i++) {
                if (signer.singleSigVaultListItem!.id >
                    _viewModel.unselectedSignerOptions[i].singlesigVaultListItem.id) {
                  insertIndex++;
                }
              }
              _viewModel.unselectedSignerOptions.insert(
                insertIndex,
                SignerOption(signer.singleSigVaultListItem!, signer.bsms!),
              );
            }

            setState(() {
              signer.reset();
            });
            Navigator.pop(context);
          };
        }
      case DialogType.cancelImport:
        {
          if (_alreadyDialogShown) return;
          _alreadyDialogShown = true;
          title = t.alert.stop_importing.title;
          message = t.alert.stop_importing.description;
          confirmButtonColor = CoconutColors.warningText;
          barrierDismissible = false;
          onCancel = () {
            _draggableController.animateTo(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              _alreadyDialogShown = false;
            });
          };
          onConfirm = () {
            _alreadyDialogShown = false;
            Navigator.pop(context);
            Navigator.pop(context);
          };
          break;
        }
      case DialogType.alreadyExist:
        {
          title = t.alert.duplicate_key.title;
          message = t.alert.duplicate_key.description;
          cancelButtonText = '';
          confirmButtonText = t.confirm;
          confirmButtonColor = CoconutColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
      case DialogType.sameWithInternalOne:
        {
          title = t.alert.same_wallet.title;
          message = t.alert.same_wallet.description(name: vaultName!);
          cancelButtonText = '';
          confirmButtonText = t.confirm;
          confirmButtonColor = CoconutColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
      default: // TODO: remove
        {
          title = t.alert.include_internal_key.title;
          message = t.alert.include_internal_key.description;
          cancelButtonText = '';
          confirmButtonText = t.confirm;
          confirmButtonColor = CoconutColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
    }

    showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: title,
          description: message,
          backgroundColor: CoconutColors.white,
          rightButtonText: confirmButtonText,
          rightButtonColor: confirmButtonColor,
          leftButtonText: cancelButtonText,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          onTapRight: onConfirm,
          onTapLeft:
              (type == DialogType.alreadyExist || type == DialogType.sameWithInternalOne)
                  ? null
                  : onCancel ?? () => Navigator.pop(context),
        );
      },
    );
  }
}
