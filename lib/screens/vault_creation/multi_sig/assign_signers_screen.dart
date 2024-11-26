import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/model/state/multisig_creation_model.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/confirm_importing_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/key_list_bottom_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/signer_scanner_screen.dart';
import 'package:coconut_vault/services/isolate_service.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_expansion_panel.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SignerOption {
  final SinglesigVaultListItem singlesigVaultListItem;
  final String signerBsms;

  const SignerOption(this.singlesigVaultListItem, this.signerBsms);
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
  late VaultModel _vaultModel;
  bool isFinishing = false;
  bool isNextProcessing = false;
  bool alreadyDialogShown = false;
  late DraggableScrollableController draggableController;
  bool isCompleteToExtractSignerBsms = false; // use for loading indicator

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
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    _multisigCreationState =
        Provider.of<MultisigCreationModel>(context, listen: false);
    requiredSignatureCount = _multisigCreationState.requiredSignatureCount!;
    totalSignatureCount = _multisigCreationState.totalSignatureCount!;

    _initAssigendVaultList();

    singlesigVaultList = _vaultModel
        .getVaults()
        .where((vault) => vault.vaultType == VaultType.singleSignature)
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
    setState(() {
      isCompleteToExtractSignerBsms = true;
    });
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
    setState(() {
      assignedVaultList[0].isExpanded = true;
    });
  }

  bool _isAllAssignedFromExternal() {
    return assignedVaultList.every((vault) =>
            vault.importKeyType == null ||
            vault.importKeyType == ImportKeyType.external) &&
        _getAssignedVaultListLength() >= totalSignatureCount - 1;
  }

  bool _isAlreadyImported(String signerBsms) {
    for (int i = 0; i < assignedVaultList.length; i++) {
      if (assignedVaultList[i].bsms == signerBsms) {
        return true;
      }
    }

    return false;
  }

  /// bsms를 비교하여 이미 보유한 볼트 지갑 중 하나인 경우 이름을 반환
  String? _findVaultNameByBsms(String signerBsms) {
    int result =
        signerOptions.indexWhere((element) => element.signerBsms == signerBsms);
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
          title = '다시 고르기';
          message = '지금까지 입력한 정보가 모두 지워져요.\n정말로 다시 선택하시겠어요?';
          cancelButtonText = '취소';
          confirmButtonText = '지우기';
          confirmButtonColor = MyColors.warningText;
          onConfirm = () {
            isFinishing = true;
            Navigator.popUntil(context,
                (route) => route.settings.name == '/select-multisig-quoram');
          };
          break;
        }
      case DialogType.notAvailable:
        {
          title = '볼트에 저장된 키가 없어요';
          message = '키를 사용하기 위해 일반 지갑을 먼저 만드시겠어요?';
          cancelButtonText = '아니오';
          confirmButtonText = '네';
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
          title = '다중 서명 지갑 만들기 중단';
          message = '정말 지갑 생성을 그만하시겠어요?';
          cancelButtonText = '취소';
          confirmButtonText = '그만하기';
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
          title = '${keyIndex + 1}번 키 초기화';
          message = '지정한 키 정보를 삭제하시겠어요?';
          cancelButtonText = '아니오';
          confirmButtonText = '네';
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
          title = '가져오기 중단';
          message = '스캔된 정보가 사라집니다.\n정말 가져오기를 그만하시겠어요?';
          cancelButtonText = '취소';
          confirmButtonText = '그만하기';
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
          title = '이미 추가된 키입니다';
          message = '중복되지 않는 다른 키로 가져와 주세요';
          cancelButtonText = '';
          confirmButtonText = '확인';
          confirmButtonColor = MyColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
      case DialogType.sameWithInternalOne:
        {
          title = "보유하신 지갑 중 하나입니다.";
          message = "'$vaultName'와 같은 지갑입니다.";
          confirmButtonText = '확인';
          confirmButtonColor = MyColors.black;
          onConfirm = () {
            Navigator.pop(context);
          };
          break;
        }
      default:
        {
          title = '외부 지갑 개수 초과';
          message = '적어도 1개는 이 볼트에 있는 키를 사용해 주세요';
          cancelButtonText = '';
          confirmButtonText = '확인';
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
      loadingMessage = '데이터 검증 중이에요';
      isNextProcessing = true;
    });
    List<KeyStore> keyStores = [];
    List<MultisigSigner> signers = [];

    for (int i = 0; i < assignedVaultList.length; i++) {
      var data = assignedVaultList[i];
      keyStores.add(KeyStore.fromSignerBsms(data.bsms!));
      switch (data.importKeyType!) {
        case ImportKeyType.internal:
          signers.add(MultisigSigner(
              id: i,
              innerVaultId: data.item!.id,
              name: data.item!.name,
              iconIndex: data.item!.iconIndex,
              colorIndex: data.item!.colorIndex,
              signerBsms: data.bsms!,
              keyStore: keyStores[i]));
          break;
        case ImportKeyType.external:
          signers.add(MultisigSigner(
              id: i,
              signerBsms: data.bsms!,
              memo: data.memo,
              keyStore: keyStores[i]));
          break;
        default:
          throw ArgumentError("wrong importKeyType: ${data.importKeyType!}");
      }
    }
    assert(signers.length == totalSignatureCount);
    // 검증: 올바른 Signer 정보를 받았는지 확인합니다.
    MultisignatureVault newMultisigVault;
    try {
      newMultisigVault = await _createMultisignatureVault(keyStores);
    } catch (error) {
      setState(() {
        isNextProcessing = false;
      });
      showAlertDialog(
          context: context, title: '지갑 생성 실패', content: '유효하지 않은 정보입니다.');
      return;
    }

    // multisig 지갑 리스트에서 중복 체크 하기
    var multisigVaults = _vaultModel.getMultisigVaults();
    for (int i = 0; i < multisigVaults.length; i++) {
      printLongString(
          "descriptors ---> ${multisigVaults[i].coconutVault.descriptor} , ${newMultisigVault.descriptor}");
      if (multisigVaults[i].coconutVault.descriptor ==
          newMultisigVault.descriptor) {
        CustomToast.showToast(context: context, text: "이미 추가되어 있는 다중 서명 지갑이에요");
        setState(() {
          isNextProcessing = false;
        });
        return;
      }
    }

    // signer mfp 기준으로 재정렬하기
    setState(() {
      loadingMessage = '동일한 순서를 유지하도록 키 순서를 정렬 할게요';
    });

    await Future.delayed(const Duration(seconds: 4));

    List<int> indices = List.generate(keyStores.length, (i) => i);
    indices.sort((a, b) => keyStores[a]
        .masterFingerprint
        .compareTo(keyStores[b].masterFingerprint));

    keyStores = [for (var i in indices) keyStores[i]];
    signers = [for (var i in indices) signers[i]];
    setState(() {
      assignedVaultList = [for (var i in indices) assignedVaultList[i]];
    });

    _multisigCreationState.setSigners(signers);

    _fromKeyStoreListIsolateHandler!.dispose();
    _fromKeyStoreListIsolateHandler = null;

    setState(() {
      hasValidationCompleted = true;
      isNextProcessing = false;
    });
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
          title: '다중 서명 지갑',
          context: context,
          onBackPressed: () => _onBackPressed(context),
          onNextPressed: onNextPressed,
          isActive: hasValidationCompleted,
          hasBackdropFilter: false,
        ),
        body: Stack(
          children: [
            Column(
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
                            const Text(
                              '선택',
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
                                    border:
                                        Border.all(color: MyColors.borderGrey)),
                                child: const Text(
                                  '다시 고르기',
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Divider(
                                          height: 1,
                                          color: MyColors.dropdownGrey),
                                    ),
                                  CustomExpansionPanel(
                                    isExpanded: assignedVaultList[i].isExpanded,
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
                                                child: KeyListBottomScreen(
                                                  // 키 옵션 중 하나 선택했을 때
                                                  onPressed: (int index) {
                                                    selectedSignerOptionIndex =
                                                        index;
                                                    isButtonActiveNotifier
                                                        .value = true;
                                                  },
                                                  vaultList: unselectedSignerOptions
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
                                              enableSingleChildScroll: false,
                                              child:
                                                  const SignerScannerScreen(),
                                            );

                                            if (externalImported != null) {
                                              /// 이미 추가된 signer와 중복 비교
                                              if (_isAlreadyImported(
                                                  externalImported)) {
                                                return _showDialog(
                                                    DialogType.alreadyExist);
                                              }

                                              String? sameVaultName =
                                                  _findVaultNameByBsms(
                                                      externalImported);
                                              if (sameVaultName != null) {
                                                _showDialog(
                                                    DialogType
                                                        .sameWithInternalOne,
                                                    vaultName: sameVaultName);
                                                return;
                                              }

                                              final Map<String, String>
                                                  bsmsAndMemo =
                                                  await MyBottomSheet
                                                      .showDraggableScrollableSheet(
                                                topWidget: true,
                                                context: context,
                                                isScrollControlled: true,
                                                controller: draggableController,
                                                minChildSize: 0.7,
                                                isDismissible: false,
                                                enableDrag: true,
                                                snap: true,
                                                onBackPressed: () =>
                                                    _showDialog(DialogType
                                                        .cancelImport),
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                enableSingleChildScroll: true,
                                                child: ConfirmImportingScreen(
                                                  importingBsms:
                                                      externalImported,
                                                ),
                                              );
                                              assert(bsmsAndMemo['bsms']!
                                                  .isNotEmpty);

                                              // 외부 지갑 추가
                                              setState(() {
                                                assignedVaultList[i]
                                                  ..importKeyType =
                                                      ImportKeyType.external
                                                  ..isExpanded = false
                                                  ..bsms = externalImported
                                                  ..memo = bsmsAndMemo['memo'];
                                              });
                                            }
                                          },
                                        ),
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
                                  label: '선택 완료',
                                  disabled: _isAssignedKeyCompletely() &&
                                      isNextProcessing),
                            ))
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: !isCompleteToExtractSignerBsms || isNextProcessing,
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
                child: Text(
                  isExternalImported
                      ? '외부 지갑'
                      : ' ${assignedVaultList[i].item!.name}',
                  style: Styles.body1,
                  overflow: TextOverflow.ellipsis,
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
  final int index;
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
      '[index]: ${index + 1}번 키\n[item]: ${item.toString()}\nmemo: $memo';

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
                      ? '이 볼트에 있는 키 사용하기'
                      : '가져오기',
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
