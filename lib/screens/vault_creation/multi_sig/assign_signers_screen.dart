import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/singlesig/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/multisig_creation_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/confirm_importing_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/key_list_bottom_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/signer_scanner_screen.dart';
import 'package:coconut_vault/managers/isolate_manager.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_expansion_panel.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SignerOption {
  final SinglesigVaultListItem singlesigVaultListItem;
  final String signerBsms;
  late final String masterFingerprint;

  SignerOption(this.singlesigVaultListItem, this.signerBsms) {
    masterFingerprint =
        (singlesigVaultListItem.coconutVault as SingleSignatureVault)
            .keyStore
            .masterFingerprint;
  }
}

class AssignSignersScreen extends StatefulWidget {
  const AssignSignersScreen({super.key});

  @override
  State<AssignSignersScreen> createState() => _AssignSignersScreenState();
}

class _AssignSignersScreenState extends State<AssignSignersScreen> {
  ValueNotifier<bool> isButtonActiveNotifier = ValueNotifier<bool>(false);
  late int totalSignatureCount; // 전체 키의 수
  late int requiredSignatureCount; // 필요한 서명 수
  late List<AssignedVaultListItem> assignedVaultList; // 키 가져오기에서 선택 완료한 객체
  late List<SignerOption> signerOptions = [];
  late List<SignerOption> unselectedSignerOptions;
  // 내부 지갑 중 Signer 선택하는 순간에만 사용함
  int? selectedSignerOptionIndex;

  late List<SinglesigVaultListItem> singlesigVaultList;
  late WalletProvider _vaultModel;
  bool isFinishing = false;
  bool isNextProcessing = false;
  bool alreadyDialogShown = false;
  late DraggableScrollableController draggableController;

  IsolateHandler<List<VaultListItemBase>, List<String>>?
      _extractBsmsIsolateHandler;
  IsolateHandler<Map<String, dynamic>, MultisignatureVault>?
      _fromKeyStoreListIsolateHandler;

  late MultisigCreationModel _multisigCreationState;

  String? loadingMessage;
  bool hasValidationCompleted = false;

  @override
  void initState() {
    super.initState();
    _vaultModel = Provider.of<WalletProvider>(context, listen: false);
    _multisigCreationState =
        Provider.of<MultisigCreationModel>(context, listen: false);
    requiredSignatureCount = _multisigCreationState.requiredSignatureCount!;
    totalSignatureCount = _multisigCreationState.totalSignatureCount!;

    _initAssigendVaultList();

    singlesigVaultList = _vaultModel
        .getVaults()
        .where((vault) => vault.vaultType == WalletType.singleSignature)
        .map((vault) => vault as SinglesigVaultListItem)
        .toList();

    _initSignerOptionList(singlesigVaultList);
    draggableController = DraggableScrollableController();
    draggableController.addListener(() {
      if (draggableController.size <= 0.71 && !alreadyDialogShown) {
        _showDialog(DialogType.cancelImport);
      }
    });
  }

  @override
  void dispose() {
    isButtonActiveNotifier.dispose();
    draggableController.dispose();
    super.dispose();
  }

  Future<MultisignatureVault> _createMultisignatureVault(
      List<KeyStore> keyStores) async {
    if (_fromKeyStoreListIsolateHandler == null) {
      _fromKeyStoreListIsolateHandler =
          IsolateHandler<Map<String, dynamic>, MultisignatureVault>(
              fromKeyStoreIsolate);
      await _fromKeyStoreListIsolateHandler!
          .initialize(initialType: InitializeType.fromKeyStore);
    }

    Map<String, dynamic> data = {
      'keyStores': jsonEncode(keyStores.map((item) => item.toJson()).toList()),
      'requiredSignatureCount': requiredSignatureCount,
    };

    MultisignatureVault multisignatureVault =
        await _fromKeyStoreListIsolateHandler!.run(data);

    return multisignatureVault;
  }

  Future<void> _initSignerOptionList(
      List<SinglesigVaultListItem> singlesigVaultList) async {
    if (_extractBsmsIsolateHandler == null) {
      _extractBsmsIsolateHandler =
          IsolateHandler<List<SinglesigVaultListItem>, List<String>>(
              extractSignerBsmsIsolate);
      await _extractBsmsIsolateHandler!
          .initialize(initialType: InitializeType.extractSignerBsms);
    }

    List<String> bsmses =
        await _extractBsmsIsolateHandler!.run(singlesigVaultList);

    for (int i = 0; i < singlesigVaultList.length; i++) {
      signerOptions.add(SignerOption(singlesigVaultList[i], bsmses[i]));
    }

    unselectedSignerOptions = signerOptions.toList();

    _extractBsmsIsolateHandler!.dispose();
  }

  bool _isAssignedKeyCompletely() {
    int assignedCount = _getAssignedVaultListLength();
    if (assignedCount >= totalSignatureCount) {
      return true;
    }
    return false;
  }

  int _getAssignedVaultListLength() {
    return assignedVaultList.where((e) => e.importKeyType != null).length;
  }

  void _initAssigendVaultList() {
    assignedVaultList = List.generate(
      totalSignatureCount,
      (index) => AssignedVaultListItem(
        item: null,
        index: index,
        importKeyType: null,
      ),
    );

    if (mounted) {
      setState(() {
        assignedVaultList[0].isExpanded = true;
      });
    }
  }

  bool _isAllAssignedFromExternal() {
    return assignedVaultList.every((vault) =>
            vault.importKeyType == null ||
            vault.importKeyType == ImportKeyType.external) &&
        _getAssignedVaultListLength() >= totalSignatureCount - 1;
  }

  bool _isAlreadyImported(String signerBsms) {
    List<String> splitedOne = signerBsms.split('\n');
    for (int i = 0; i < assignedVaultList.length; i++) {
      if (assignedVaultList[i].bsms == null) continue;
      List<String> splitedTwo = assignedVaultList[i].bsms!.split('\n');
      if (splitedOne[0] == splitedTwo[0] &&
          splitedOne[1] == splitedTwo[1] &&
          splitedOne[2] == splitedTwo[2]) {
        return true;
      }
      // if (assignedVaultList[i].bsms == signerBsms) {
      //   return true;
      // }
    }

    return false;
  }

  /// bsms를 비교하여 이미 보유한 볼트 지갑 중 하나인 경우 이름을 반환
  String? _findVaultNameByBsms(String signerBsms) {
    var mfp = BSMS.parseSigner(signerBsms).signer!.masterFingerPrint;

    int result = signerOptions.indexWhere((element) {
      return element.masterFingerprint == mfp;
    });
    if (result == -1) return null;
    return signerOptions[result].singlesigVaultListItem.name;
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
      case DialogType.reSelect:
        {
          title = t.alert.reselect.title;
          message = t.alert.reselect.description;
          cancelButtonText = t.cancel;
          confirmButtonText = t.delete;
          confirmButtonColor = MyColors.warningText;
          onConfirm = () {
            isFinishing = true;
            Navigator.popUntil(context,
                (route) => route.settings.name == '/select-multisig-quorum');
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
            Navigator.pushNamedAndRemoveUntil(
                context,
                '/vault-creation-options',
                (Route<dynamic> route) =>
                    route.settings.name == '/select-vault-type');
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
            _multisigCreationState.reset();
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (Route<dynamic> route) => false);
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
            // 내부 지갑인 경우
            if (assignedVaultList[keyIndex].importKeyType ==
                ImportKeyType.internal) {
              int insertIndex = 0;
              for (int i = 0; i < unselectedSignerOptions.length; i++) {
                if (assignedVaultList[keyIndex].item!.id >
                    unselectedSignerOptions[i].singlesigVaultListItem.id) {
                  insertIndex++;
                }
              }
              unselectedSignerOptions.insert(
                  insertIndex,
                  SignerOption(assignedVaultList[keyIndex].item!,
                      assignedVaultList[keyIndex].bsms!));
            }

            setState(() {
              assignedVaultList[keyIndex].reset();
              if (hasValidationCompleted) {
                hasValidationCompleted = false;
              }
            });
            Navigator.pop(context);
          };
        }
      case DialogType.cancelImport:
        {
          if (alreadyDialogShown) return;
          alreadyDialogShown = true;
          title = t.alert.stop_importing.title;
          message = t.alert.stop_importing.description;
          cancelButtonText = t.cancel;
          confirmButtonText = t.stop;
          confirmButtonColor = MyColors.warningText;
          barrierDismissible = false;
          onCancel = () {
            draggableController.animateTo(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );

            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              alreadyDialogShown = false;
            });
          };
          onConfirm = () {
            alreadyDialogShown = false;
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

  void _onBackPressed(BuildContext context) {
    if (_getAssignedVaultListLength() > 0) {
      _showDialog(DialogType.quit);
    } else {
      _multisigCreationState.reset();
      isFinishing = true;
      Navigator.pop(context);
    }
  }

  // 외부지갑은 추가 시 올바른 signerBsms 인지 미리 확인이 되어 있어야 합니다.
  void onSelectionCompleted() async {
    setState(() {
      loadingMessage = t.assign_signers_screen.order_keys;
      isNextProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    List<KeyStore> keyStores = [];
    List<MultisigSigner> signers = [];

    for (int i = 0; i < assignedVaultList.length; i++) {
      keyStores.add(KeyStore.fromSignerBsms(assignedVaultList[i].bsms!));
      switch (assignedVaultList[i].importKeyType!) {
        case ImportKeyType.internal:
          signers.add(MultisigSigner(
              id: i,
              innerVaultId: assignedVaultList[i].item!.id,
              name: assignedVaultList[i].item!.name,
              iconIndex: assignedVaultList[i].item!.iconIndex,
              colorIndex: assignedVaultList[i].item!.colorIndex,
              signerBsms: assignedVaultList[i].bsms!,
              keyStore: keyStores[i]));
          break;
        case ImportKeyType.external:
          signers.add(MultisigSigner(
              id: i,
              signerBsms: assignedVaultList[i].bsms!,
              name: assignedVaultList[i].bsms?.split('\n')[3] ?? '',
              memo: assignedVaultList[i].memo,
              keyStore: keyStores[i]));
          break;
        default:
          throw ArgumentError(
              "wrong importKeyType: ${assignedVaultList[i].importKeyType!}");
      }
    }

    assert(signers.length == totalSignatureCount);
    // signer mfp 기준으로 재정렬하기
    List<int> indices = List.generate(keyStores.length, (i) => i);
    indices.sort((a, b) => keyStores[a]
        .masterFingerprint
        .compareTo(keyStores[b].masterFingerprint));

    keyStores = [for (var i in indices) keyStores[i]];
    signers = [for (var i in indices) signers[i]]
      ..asMap().forEach((i, signer) => signer.id = i);

    // 오래 걸리는 작업 뒤에 setState가 있으면 mounted 체크를 해주어햐 에러가 나지 않습니다.
    if (!mounted) return;
    setState(() {
      assignedVaultList = [for (var i in indices) assignedVaultList[i]];

      for (int i = 0; i < assignedVaultList.length; i++) {
        assignedVaultList[i].index = i;
      }

      loadingMessage = t.assign_signers_screen.data_verifying;
    });

    // 검증: 올바른 Signer 정보를 받았는지 확인합니다.
    MultisignatureVault newMultisigVault;
    try {
      newMultisigVault = await _createMultisignatureVault(keyStores);
    } catch (error) {
      if (mounted) {
        setState(() {
          isNextProcessing = false;
        });
        showAlertDialog(
            context: context,
            title: t.alert.wallet_creation_failed.title,
            content: t.alert.wallet_creation_failed.description);
      }
      return;
    }

    // multisig 지갑 리스트에서 중복 체크 하기
    VaultListItemBase? findResult =
        _vaultModel.findWalletByDescriptor(newMultisigVault.descriptor);
    if (findResult != null) {
      if (mounted) {
        CustomToast.showToast(
            context: context,
            text: t.toast.multisig_already_added(name: findResult.name));
        setState(() {
          isNextProcessing = false;
        });
      }
      return;
    }

    _multisigCreationState.setSigners(signers);

    _fromKeyStoreListIsolateHandler!.dispose();
    _fromKeyStoreListIsolateHandler = null;

    if (mounted) {
      setState(() {
        hasValidationCompleted = true;
        isNextProcessing = false;
      });
    }
  }

  void onNextPressed() {
    Navigator.pushNamed(context, '/vault-name-setup');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!isFinishing) _onBackPressed(context);
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.buildWithNext(
          title: t.multisig_wallet,
          context: context,
          onBackPressed: () => _onBackPressed(context),
          onNextPressed: onNextPressed,
          isActive: hasValidationCompleted,
          hasBackdropFilter: false,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
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
                            borderRadius: _getAssignedVaultListLength() /
                                        totalSignatureCount ==
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
                                  (_getAssignedVaultListLength() == 0
                                      ? 0
                                      : _getAssignedVaultListLength() /
                                          totalSignatureCount),
                              color: MyColors.black,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HighLightedText(
                                  '$requiredSignatureCount/$totalSignatureCount',
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
                                  _getAssignedVaultListLength() != 0
                                      ? _showDialog(DialogType.reSelect)
                                      : _onBackPressed(context);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: MyColors.borderGrey)),
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
                                      i < assignedVaultList.length;
                                      i++) ...[
                                    if (i > 0)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Divider(
                                            height: 1,
                                            color: MyColors.dropdownGrey),
                                      ),
                                    CustomExpansionPanel(
                                      isExpanded:
                                          assignedVaultList[i].isExpanded,
                                      isAssigned:
                                          assignedVaultList[i].importKeyType !=
                                              null,
                                      onAssignedClicked: () {
                                        _showDialog(DialogType.deleteKey,
                                            keyIndex: i);
                                      },
                                      onExpansionChanged: () {
                                        setState(() {
                                          assignedVaultList[i].changeExpanded();
                                        });
                                      },
                                      unExpansionWidget:
                                          assignedVaultList[i].importKeyType ==
                                                  null
                                              ? _unExpansionWidget(i)
                                              : _unExpansionWidget(i,
                                                  isAssigned: true),
                                      expansionWidget: Column(
                                        children: [
                                          // 이 볼트에 있는 키 사용하기
                                          ExpansionChildWidget(
                                              type: ImportKeyType.internal,
                                              onPressed: () {
                                                // 등록된 singlesig vault가 없으면 멀티시그 지갑 생성 불가
                                                if (unselectedSignerOptions
                                                    .isEmpty) {
                                                  _showDialog(
                                                      DialogType.notAvailable);
                                                  return;
                                                }

                                                isButtonActiveNotifier.value =
                                                    false;
                                                MyBottomSheet
                                                    .showDraggableScrollableSheet(
                                                  topWidget: true,
                                                  isButtonActiveNotifier:
                                                      isButtonActiveNotifier,
                                                  context: context,
                                                  childBuilder:
                                                      (sheetController) =>
                                                          KeyListBottomScreen(
                                                    // 키 옵션 중 하나 선택했을 때
                                                    onPressed: (int index) {
                                                      selectedSignerOptionIndex =
                                                          index;
                                                      isButtonActiveNotifier
                                                          .value = true;
                                                    },
                                                    vaultList:
                                                        unselectedSignerOptions
                                                            .map((o) => o
                                                                .singlesigVaultListItem)
                                                            .toList(),
                                                  ),
                                                  onTopWidgetButtonClicked: () {
                                                    setState(() {
                                                      // 내부 지갑 선택 완료
                                                      assignedVaultList[i]
                                                        ..item = unselectedSignerOptions[
                                                                selectedSignerOptionIndex!]
                                                            .singlesigVaultListItem
                                                        ..bsms =
                                                            unselectedSignerOptions[
                                                                    selectedSignerOptionIndex!]
                                                                .signerBsms
                                                        ..isExpanded = false
                                                        ..importKeyType =
                                                            ImportKeyType
                                                                .internal;

                                                      unselectedSignerOptions
                                                          .removeAt(
                                                              selectedSignerOptionIndex!);
                                                    });
                                                    selectedSignerOptionIndex =
                                                        null;
                                                  },
                                                );
                                              }),
                                          // 가져오기
                                          ExpansionChildWidget(
                                              type: ImportKeyType.external,
                                              onPressed: () async {
                                                if (_isAllAssignedFromExternal()) {
                                                  _showDialog(DialogType.alert);
                                                  return;
                                                }

                                                final externalImported =
                                                    await MyBottomSheet
                                                        .showDraggableScrollableSheet(
                                                  topWidget: true,
                                                  context: context,
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  enableSingleChildScroll:
                                                      false,
                                                  child:
                                                      const SignerScannerScreen(),
                                                );

                                                if (externalImported != null) {
                                                  /// 이미 추가된 signer와 중복 비교
                                                  if (_isAlreadyImported(
                                                      externalImported)) {
                                                    return _showDialog(
                                                        DialogType
                                                            .alreadyExist);
                                                  }

                                                  String? sameVaultName =
                                                      _findVaultNameByBsms(
                                                          externalImported);
                                                  if (sameVaultName != null) {
                                                    _showDialog(
                                                        DialogType
                                                            .sameWithInternalOne,
                                                        vaultName:
                                                            sameVaultName);
                                                    return;
                                                  }

                                                  final Map<String, String>?
                                                      bsmsAndMemo =
                                                      await MyBottomSheet
                                                          .showDraggableScrollableSheet(
                                                    topWidget: true,
                                                    context: context,
                                                    isScrollControlled: true,
                                                    controller:
                                                        draggableController,
                                                    minChildSize: 0.7,
                                                    isDismissible: false,
                                                    enableDrag: true,
                                                    snap: true,
                                                    onBackPressed: () =>
                                                        _showDialog(DialogType
                                                            .cancelImport),
                                                    physics:
                                                        const ClampingScrollPhysics(),
                                                    enableSingleChildScroll:
                                                        true,
                                                    childBuilder:
                                                        (sheetController) =>
                                                            ConfirmImportingScreen(
                                                      importingBsms:
                                                          externalImported,
                                                      scrollController:
                                                          sheetController,
                                                    ),
                                                  );
                                                  if (bsmsAndMemo != null) {
                                                    assert(bsmsAndMemo['bsms']!
                                                        .isNotEmpty);

                                                    // 외부 지갑 추가
                                                    setState(() {
                                                      assignedVaultList[i]
                                                        ..importKeyType =
                                                            ImportKeyType
                                                                .external
                                                        ..isExpanded = false
                                                        ..bsms =
                                                            externalImported
                                                        ..memo =
                                                            bsmsAndMemo['memo'];
                                                    });
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
                              visible: _isAssignedKeyCompletely() &&
                                  !hasValidationCompleted,
                              child: Container(
                                margin: const EdgeInsets.only(top: 40),
                                child: CompleteButton(
                                    onPressed: onSelectionCompleted,
                                    label: t.select_completed,
                                    disabled: _isAssignedKeyCompletely() &&
                                        isNextProcessing),
                              ))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isNextProcessing,
              child: Container(
                decoration:
                    const BoxDecoration(color: MyColors.transparentBlack_30),
                child: Center(
                    child: MessageActivityIndicator(message: loadingMessage)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 확장형 메뉴 펼쳐져 있지 않을 때
  Row _unExpansionWidget(int i, {bool isAssigned = false}) {
    bool isExternalImported =
        assignedVaultList[i].importKeyType == ImportKeyType.external;
    return isAssigned
        ? Row(
            children: [
              const SizedBox(width: 8),
              Text(
                '${assignedVaultList[i].index + 1}번 키 -',
                style: Styles.body1,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BackgroundColorPalette[isExternalImported
                      ? 8
                      : assignedVaultList[i].item!.colorIndex],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SvgPicture.asset(
                  isExternalImported
                      ? 'assets/svg/download.svg'
                      : CustomIcons.getPathByIndex(
                          assignedVaultList[i].item!.iconIndex),
                  colorFilter: ColorFilter.mode(
                    isExternalImported
                        ? MyColors.black
                        : ColorPalette[assignedVaultList[i].item!.colorIndex],
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
                          ? ' ${assignedVaultList[i].bsms?.split('\n')[3] ?? ''}'
                          : ' ${assignedVaultList[i].item!.name}',
                      style: Styles.body1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Visibility(
                      visible: assignedVaultList[i].memo != null &&
                          assignedVaultList[i].memo!.isNotEmpty,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          assignedVaultList[i].memo ?? '',
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
                turns: assignedVaultList[i].isExpanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.expand_more,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  '${assignedVaultList[i].index + 1}번 키',
                  style: Styles.body1,
                ),
              ),
              SvgPicture.asset(
                'assets/svg/circle-check-gradient.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                    MyColors.transparentBlack_15, BlendMode.srcIn),
              ),
            ],
          );
  }
}

class AssignedVaultListItem {
  int index;
  String? bsms;
  SinglesigVaultListItem? item;
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

  @override
  String toString() =>
      '[index]: ${t.multisig.nth_key(index: index + 1)}\n[item]: ${item.toString()}\nmemo: $memo';

  void changeExpanded() {
    isExpanded = !isExpanded;
  }

  void reset() {
    bsms = item = importKeyType = memo = null;
    isExpanded = true;
  }
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

class _ExpansionChildWidgetState extends State<ExpansionChildWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          right: 8,
          left: 65,
          bottom: widget.type == ImportKeyType.external ? 10 : 0),
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
          padding:
              const EdgeInsets.only(left: 15, top: 16, bottom: 16, right: 8),
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

// internal = 이 볼트에 있는 키 사용 external = 외부에서 가져오기
enum ImportKeyType { internal, external }

enum DialogType {
  reSelect,
  quit,
  alert,
  notAvailable,
  deleteKey,
  alreadyExist,
  cancelImport,
  sameWithInternalOne // '가져오기' 한 지갑이 내부에 있는 지갑 중 하나일 때
}
