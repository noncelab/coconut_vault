import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/signer_assignment_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/multisig_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/import_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_key_list_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_expansion_panel.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AssignedVaultListItem {
  int index;
  String? bsms;
  SingleSigVaultListItem? item;
  String? memo;
  bool isExpanded; // UI
  ImportKeyType? importKeyType;

  AssignedVaultListItem({
    required this.index,
    required this.importKeyType,
    required this.item,
    this.bsms,
    this.isExpanded = false,
  });

  void changeExpanded() {
    isExpanded = !isExpanded;
  }

  void reset() {
    bsms = item = importKeyType = memo = null;
    isExpanded = true;
  }

  @override
  String toString() =>
      '[index]: ${t.multisig.nth_key(index: index + 1)}\n[item]: ${item.toString()}\nmemo: $memo';
}

enum DialogType {
  reselectQuorum,
  quit,
  alert,
  notAvailable,
  deleteKey,
  alreadyExist,
  cancelImport,
  sameWithInternalOne // '가져오기' 한 지갑이 내부에 있는 지갑 중 하나일 때
}

// 확장형 메뉴의 선택지
class ExpansionChildWidget extends StatefulWidget {
  final ImportKeyType type;
  final VoidCallback? onPressed;
  final ValueNotifier<bool>? isButtonActiveNotifier;

  const ExpansionChildWidget({
    super.key,
    required this.type,
    this.onPressed,
    this.isButtonActiveNotifier,
  });

  @override
  State<ExpansionChildWidget> createState() => _ExpansionChildWidgetState();
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
  final String signerBsms;
  late final String masterFingerprint;

  SignerOption(this.singlesigVaultListItem, this.signerBsms) {
    masterFingerprint =
        (singlesigVaultListItem.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
  }
}

class _ExpansionChildWidgetState extends State<ExpansionChildWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          right: 8, left: 65, bottom: widget.type == ImportKeyType.external ? 10 : 0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            isPressed = false;
          });
          if (widget.onPressed != null) widget.onPressed!();
        },
        onTapDown: (details) {
          setState(() {
            isPressed = true;
          });
        },
        onTapCancel: () {
          setState(() {
            isPressed = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isPressed ? MyColors.lightgrey : MyColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.only(left: 15, top: 16, bottom: 16, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.type == ImportKeyType.internal
                      ? t.assign_signers_screen.use_internal_key
                      : t.import,
                  style: Styles.body1,
                ),
              ),
              const Icon(
                Icons.add_rounded,
                color: MyColors.black,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignerAssignmentScreenState extends State<SignerAssignmentScreen> {
  bool _isFinishing = false;
  bool _isNextProcessing = false;
  bool _alreadyDialogShown = false;
  bool _hasValidationCompleted = false;
  late SignerAssignmentViewModel _viewModel;
  late DraggableScrollableController _draggableController;
  final ValueNotifier<bool> _isButtonActiveNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!_isFinishing) _onBackPressed(context);
      },
      child: ChangeNotifierProvider<SignerAssignmentViewModel>(
        create: (context) => _viewModel = SignerAssignmentViewModel(
          Provider.of<WalletProvider>(context, listen: false),
          Provider.of<WalletCreationProvider>(context, listen: false),
        ),
        child: Consumer<SignerAssignmentViewModel>(
          builder: (context, viewModel, child) => Scaffold(
            backgroundColor: MyColors.white,
            appBar: CustomAppBar.buildWithNext(
              title: t.multisig_wallet,
              context: context,
              onBackPressed: () => _onBackPressed(context),
              onNextPressed: onNextPressed,
              isActive: _hasValidationCompleted,
              hasBackdropFilter: false,
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            child: Container(
                              height: 6,
                              color: MyColors.transparentBlack_06,
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return ClipRRect(
                                borderRadius: viewModel.getAssignedVaultListLength() /
                                            viewModel.totalSignatureCount ==
                                        1
                                    ? BorderRadius.zero
                                    : const BorderRadius.only(
                                        topRight: Radius.circular(6),
                                        bottomRight: Radius.circular(6)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  height: 6,
                                  width: (constraints.maxWidth) *
                                      (viewModel.getAssignedVaultListLength() == 0
                                          ? 0
                                          : viewModel.getAssignedVaultListLength() /
                                              viewModel.totalSignatureCount),
                                  color: MyColors.black,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HighLightedText(
                                      '${viewModel.requiredSignatureCount}/${viewModel.totalSignatureCount}',
                                      color: MyColors.darkgrey),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    t.select,
                                    style: Styles.body1,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      viewModel.getAssignedVaultListLength() != 0
                                          ? _showDialog(DialogType.reselectQuorum)
                                          : _onBackPressed(context);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: MyColors.borderGrey)),
                                      child: Text(
                                        t.re_select,
                                        style: Styles.caption,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 38),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: MyColors.white,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: MyColors.transparentBlack_15,
                                      offset: Offset(0, 0),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    children: [
                                      for (int i = 0;
                                          i < viewModel.assignedVaultList.length;
                                          i++) ...[
                                        if (i > 0)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10),
                                            child: Divider(height: 1, color: MyColors.dropdownGrey),
                                          ),
                                        CustomExpansionPanel(
                                          isExpanded: viewModel.assignedVaultList[i].isExpanded,
                                          isAssigned:
                                              viewModel.assignedVaultList[i].importKeyType != null,
                                          onAssignedClicked: () {
                                            _showDialog(DialogType.deleteKey, keyIndex: i);
                                          },
                                          onExpansionChanged: () {
                                            setState(() {
                                              viewModel.assignedVaultList[i].changeExpanded();
                                            });
                                          },
                                          unExpansionWidget:
                                              viewModel.assignedVaultList[i].importKeyType == null
                                                  ? _unExpansionWidget(i)
                                                  : _unExpansionWidget(i, isAssigned: true),
                                          expansionWidget: Column(
                                            children: [
                                              // 이 볼트에 있는 키 사용하기
                                              ExpansionChildWidget(
                                                  type: ImportKeyType.internal,
                                                  onPressed: () {
                                                    // 등록된 singlesig vault가 없으면 멀티시그 지갑 생성 불가
                                                    if (viewModel.unselectedSignerOptions.isEmpty) {
                                                      _showDialog(DialogType.notAvailable);
                                                      return;
                                                    }

                                                    _isButtonActiveNotifier.value = false;
                                                    MyBottomSheet.showDraggableScrollableSheet(
                                                      topWidget: true,
                                                      isButtonActiveNotifier:
                                                          _isButtonActiveNotifier,
                                                      context: context,
                                                      childBuilder: (sheetController) =>
                                                          KeyListBottomSheet(
                                                        // 키 옵션 중 하나 선택했을 때
                                                        onPressed: (int index) {
                                                          viewModel
                                                              .setSelectedSignerOptionIndex(index);
                                                          _isButtonActiveNotifier.value = true;
                                                        },
                                                        vaultList: viewModel.unselectedSignerOptions
                                                            .map((o) => o.singlesigVaultListItem)
                                                            .toList(),
                                                      ),
                                                      onTopWidgetButtonClicked: () {
                                                        viewModel.assignInternalSigner(i);

                                                        viewModel
                                                            .setSelectedSignerOptionIndex(null);
                                                      },
                                                    );
                                                  }),
                                              // 가져오기
                                              ExpansionChildWidget(
                                                  type: ImportKeyType.external,
                                                  onPressed: () async {
                                                    if (viewModel.isAllAssignedFromExternal()) {
                                                      _showDialog(DialogType.alert);
                                                      return;
                                                    }

                                                    final externalImported = await MyBottomSheet
                                                        .showDraggableScrollableSheet(
                                                      topWidget: true,
                                                      context: context,
                                                      physics: const ClampingScrollPhysics(),
                                                      enableSingleChildScroll: false,
                                                      child: const MultisigBsmsScannerScreen(),
                                                    );

                                                    if (externalImported != null) {
                                                      /// 이미 추가된 signer와 중복 비교
                                                      if (viewModel
                                                          .isAlreadyImported(externalImported)) {
                                                        return _showDialog(DialogType.alreadyExist);
                                                      }

                                                      String? sameVaultName = viewModel
                                                          .findVaultNameByBsms(externalImported);
                                                      if (sameVaultName != null) {
                                                        _showDialog(DialogType.sameWithInternalOne,
                                                            vaultName: sameVaultName);
                                                        return;
                                                      }

                                                      final Map<String, String>? bsmsAndMemo =
                                                          await MyBottomSheet
                                                              .showDraggableScrollableSheet(
                                                        topWidget: true,
                                                        context: context,
                                                        isScrollControlled: true,
                                                        controller: _draggableController,
                                                        minChildSize: 0.7,
                                                        isDismissible: false,
                                                        enableDrag: true,
                                                        snap: true,
                                                        onBackPressed: () =>
                                                            _showDialog(DialogType.cancelImport),
                                                        physics: const ClampingScrollPhysics(),
                                                        enableSingleChildScroll: true,
                                                        childBuilder: (sheetController) =>
                                                            ImportConfirmationScreen(
                                                          importingBsms: externalImported,
                                                          scrollController: sheetController,
                                                        ),
                                                      );
                                                      if (bsmsAndMemo != null) {
                                                        assert(bsmsAndMemo['bsms']!.isNotEmpty);

                                                        viewModel.setAssignedVaultList(
                                                            i,
                                                            ImportKeyType.external,
                                                            false,
                                                            externalImported,
                                                            bsmsAndMemo['memo']);
                                                      }
                                                    }
                                                  }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Visibility(
                                  visible: viewModel.isAssignedKeyCompletely() &&
                                      !_hasValidationCompleted,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 40),
                                    child: CompleteButton(
                                        onPressed: onSelectionCompleted,
                                        label: t.select_completed,
                                        disabled: viewModel.isAssignedKeyCompletely() &&
                                            _isNextProcessing),
                                  ))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: _isNextProcessing,
                  child: Container(
                    decoration: const BoxDecoration(color: MyColors.transparentBlack_30),
                    child:
                        Center(child: MessageActivityIndicator(message: viewModel.loadingMessage)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void onNextPressed() {
    _viewModel.saveSignersToProvider();
    Navigator.pushNamed(context, AppRoutes.vaultNameSetup);
  }

  // 외부지갑은 추가 시 올바른 signerBsms 인지 미리 확인이 되어 있어야 합니다.
  void onSelectionCompleted() async {
    setState(() {
      _isNextProcessing = true;
    });
    _viewModel.setLoadingMessage(t.assign_signers_screen.order_keys);

    await Future.delayed(const Duration(seconds: 3));
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
            content: t.alert.wallet_creation_failed.description);
      }
      return;
    }

    // multisig 지갑 리스트에서 중복 체크 하기
    VaultListItemBase? existingWallet = _viewModel.getWalletByDescriptor();
    if (existingWallet != null) {
      if (mounted) {
        CustomToast.showToast(
            context: context, text: t.toast.multisig_already_added(name: existingWallet.name));
        setState(() {
          _isNextProcessing = false;
        });
      }
      return;
    }

    _viewModel.setSigners(signers);

    _viewModel.clearFromKeyStoreListIsolateHandler();

    if (mounted) {
      setState(() {
        _hasValidationCompleted = true;
        _isNextProcessing = false;
      });
    }
  }

  void _onBackPressed(BuildContext context) {
    if (_viewModel.getAssignedVaultListLength() > 0) {
      _showDialog(DialogType.quit);
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
    Color confirmButtonColor = MyColors.black;
    VoidCallback? onCancel;
    VoidCallback onConfirm;
    bool barrierDismissible = true;

    switch (type) {
      case DialogType.reselectQuorum:
        {
          title = t.alert.reselect.title;
          message = t.alert.reselect.description;
          cancelButtonText = t.cancel;
          confirmButtonText = t.confirm;
          confirmButtonColor = MyColors.warningText;
          onConfirm = () {
            _viewModel.resetWalletCreationProvider();
            _isFinishing = true;
            Navigator.popUntil(
                context, (route) => route.settings.name == AppRoutes.multisigQuorumSelection);
          };
          break;
        }
      case DialogType.notAvailable:
        {
          title = t.alert.empty_vault.title;
          message = t.alert.empty_vault.description;
          cancelButtonText = t.no;
          confirmButtonText = t.yes;
          confirmButtonColor = MyColors.black;
          onConfirm = () {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.vaultCreationOptions,
                (Route<dynamic> route) => route.settings.name == AppRoutes.vaultTypeSelection);
          };
          break;
        }
      case DialogType.quit:
        {
          title = t.alert.quit_creating_mutisig_wallet.title;
          message = t.alert.quit_creating_mutisig_wallet.description;
          cancelButtonText = t.cancel;
          confirmButtonText = t.stop;
          confirmButtonColor = MyColors.warningText;
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
          cancelButtonText = t.no;
          confirmButtonText = t.yes;
          confirmButtonColor = MyColors.warningText;
          onConfirm = () {
            _viewModel.setSigners(null);
            // 내부 지갑인 경우
            if (_viewModel.assignedVaultList[keyIndex].importKeyType == ImportKeyType.internal) {
              int insertIndex = 0;
              for (int i = 0; i < _viewModel.unselectedSignerOptions.length; i++) {
                if (_viewModel.assignedVaultList[keyIndex].item!.id >
                    _viewModel.unselectedSignerOptions[i].singlesigVaultListItem.id) {
                  insertIndex++;
                }
              }
              _viewModel.unselectedSignerOptions.insert(
                  insertIndex,
                  SignerOption(_viewModel.assignedVaultList[keyIndex].item!,
                      _viewModel.assignedVaultList[keyIndex].bsms!));
            }

            setState(() {
              _viewModel.assignedVaultList[keyIndex].reset();
              if (_hasValidationCompleted) {
                _hasValidationCompleted = false;
              }
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
          cancelButtonText = t.cancel;
          confirmButtonText = t.stop;
          confirmButtonColor = MyColors.warningText;
          barrierDismissible = false;
          onCancel = () {
            _draggableController.animateTo(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );

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
          confirmButtonColor = MyColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
      case DialogType.sameWithInternalOne:
        {
          title = t.alert.same_wallet.title;
          message = t.alert.same_wallet.description(name: vaultName!);
          confirmButtonText = t.confirm;
          confirmButtonColor = MyColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
      default:
        {
          title = t.alert.include_internal_key.title;
          message = t.alert.include_internal_key.description;
          cancelButtonText = '';
          confirmButtonText = t.confirm;
          confirmButtonColor = MyColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
    }

    CustomDialogs.showCustomAlertDialog(
      context,
      title: title,
      message: message,
      cancelButtonText: cancelButtonText,
      confirmButtonText: confirmButtonText,
      confirmButtonColor: confirmButtonColor,
      barrierDismissible: barrierDismissible,
      isSingleButton: type == DialogType.alert ||
          type == DialogType.alreadyExist ||
          type == DialogType.sameWithInternalOne,
      onCancel: onCancel ?? () => Navigator.pop(context),
      onConfirm: () => onConfirm(),
    );
  }

  // 확장형 메뉴 펼쳐져 있지 않을 때
  Row _unExpansionWidget(int i, {bool isAssigned = false}) {
    bool isExternalImported =
        _viewModel.assignedVaultList[i].importKeyType == ImportKeyType.external;
    return isAssigned
        ? Row(
            children: [
              const SizedBox(width: 8),
              Text(
                '${t.multisig.nth_key(index: _viewModel.assignedVaultList[i].index + 1)} -',
                style: Styles.body1,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BackgroundColorPalette[
                      isExternalImported ? 8 : _viewModel.assignedVaultList[i].item!.colorIndex],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SvgPicture.asset(
                  isExternalImported
                      ? 'assets/svg/download.svg'
                      : CustomIcons.getPathByIndex(_viewModel.assignedVaultList[i].item!.iconIndex),
                  colorFilter: ColorFilter.mode(
                    isExternalImported
                        ? MyColors.black
                        : ColorPalette[_viewModel.assignedVaultList[i].item!.colorIndex],
                    BlendMode.srcIn,
                  ),
                  width: 16.0,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExternalImported
                          ? ' ${_viewModel.assignedVaultList[i].bsms?.split('\n')[3] ?? ''}'
                          : ' ${_viewModel.assignedVaultList[i].item!.name}',
                      style: Styles.body1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Visibility(
                      visible: _viewModel.assignedVaultList[i].memo != null &&
                          _viewModel.assignedVaultList[i].memo!.isNotEmpty,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          _viewModel.assignedVaultList[i].memo ?? '',
                          style: Styles.caption2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/svg/circle-check-gradient.svg',
                width: 18,
                height: 18,
              ),
            ],
          )
        : Row(
            children: [
              AnimatedRotation(
                turns: _viewModel.assignedVaultList[i].isExpanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.expand_more,
                  color: CoconutColors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  '${t.multisig.nth_key(index: _viewModel.assignedVaultList[i].index + 1)} -',
                  style: Styles.body1,
                ),
              ),
              SvgPicture.asset(
                'assets/svg/circle-check-gradient.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(MyColors.transparentBlack_15, BlendMode.srcIn),
              ),
            ],
          );
  }
}
