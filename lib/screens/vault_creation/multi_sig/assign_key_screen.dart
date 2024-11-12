import 'package:coconut_vault/model/vault_list_item.dart';
import 'package:coconut_vault/model/vault_model.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/confirm_importing_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/import_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/key_list_bottom_screen.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_expansion_panel.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AssignKeyScreen extends StatefulWidget {
  final int nKeyCount;
  final int mKeyCount;
  const AssignKeyScreen({
    super.key,
    required this.nKeyCount,
    required this.mKeyCount,
  });

  @override
  State<AssignKeyScreen> createState() => _AssignKeyScreenState();
}

class _AssignKeyScreenState extends State<AssignKeyScreen> {
  ValueNotifier<bool> isButtonActiveNotifier = ValueNotifier<bool>(false);
  // TODO: 다중서명 데이터들 모델로 분리 필요
  late int nCount; // 전체 키의 수
  late int mCount; // 필요한 서명 수
  late List<AssignedVaultListItem> assignedVaultList; // 키 가져오기에서 선택 완료한 객체
  late VaultListItem? selectingVaultList; // 키 가져오기 목록에서 선택중인 객체
  late List<VaultListItem> vaultList;
  late VaultModel _vaultModel;
  bool isFinishing = false;
  bool alreadyDialogShown = false;
  late DraggableScrollableController draggableController;

  @override
  void initState() {
    super.initState();
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    _initAssigendVaultList();
    vaultList = _vaultModel.getVaults();

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

  bool _isAssignedKeyCompletely() {
    int assignedCount = _getAssignedVaultListLength();
    if (assignedCount >= nCount) {
      return true;
    }
    return false;
  }

  int _getAssignedVaultListLength() {
    return assignedVaultList.where((e) => e.importKeyType != null).length;
  }

  void _initAssigendVaultList() {
    nCount = widget.nKeyCount;
    mCount = widget.mKeyCount;
    assignedVaultList = List.generate(
      nCount,
      (index) => AssignedVaultListItem(
        item: null,
        index: index,
        importKeyType: null,
      ),
    );
    setState(() {
      assignedVaultList[0].isExpanded = true;
    });
    selectingVaultList = null;
  }

  bool _checkEmptyList() {
    if (vaultList.isEmpty ||
        _getAssignedVaultListLength() >= vaultList.length) {
      return true;
    }
    return false;
  }

  bool _isAllAssignedFromExternal() {
    return _getAssignedVaultListLength() >= nCount - 1 &&
        assignedVaultList
            .every((vault) => vault.importKeyType != ImportKeyType.internal);
  }

  bool _isAlreadyImportedExternalItem(String data) {
    // TODO : 기존 추가된 키들과 동일한 pubkey인지 확인 필요..

    for (int i = 0; i < assignedVaultList.length; i++) {
      if (assignedVaultList[i].importKeyType == ImportKeyType.external &&
          assignedVaultList[i].zPubString == data) {
        return true;
      }
    }
    return false;
  }

  void _showDialog(DialogType type, {int keyIndex = 0}) {
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
                (route) => route.settings.name == '/select-key-options');
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
          message = '정말 만들기를 그만하시겠어요?';
          cancelButtonText = '취소';
          confirmButtonText = '그만하기';
          confirmButtonColor = MyColors.warningText;
          onConfirm = () {
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
            setState(() {
              assignedVaultList[keyIndex].item = null;
              assignedVaultList[keyIndex].isExpanded = true;
              assignedVaultList[keyIndex].importKeyType = null;
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
      default:
        {
          title = '더이상 가져올 수 없어요';
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
      isSingleButton:
          type == DialogType.alert || type == DialogType.alreadyExist,
      onCancel: onCancel ?? () => Navigator.pop(context),
      onConfirm: () => onConfirm(),
    );
  }

  void _onBackPressed(BuildContext context) {
    if (_getAssignedVaultListLength() > 0) {
      _showDialog(DialogType.quit);
    } else {
      isFinishing = true;
      Navigator.pop(context);
    }
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
          onNextPressed: () => Navigator.pushNamed(context,
              '/vault-name-setup'), // TODO: VaultNameIconSetup 클래스에서 일반 지갑과 다중서명 지갑 생성 분리 필요
          isActive: _isAssignedKeyCompletely(),
          hasBackdropFilter: false,
        ),
        body: Column(
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
                      borderRadius: _getAssignedVaultListLength() / nCount == 1
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
                                : _getAssignedVaultListLength() / nCount),
                        color: MyColors.black,
                      ),
                    );
                  },
                ),
              ],
            ),
            SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HighLightedText('$mCount/$nCount',
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
                                border: Border.all(color: MyColors.borderGrey)),
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
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Divider(
                                      height: 1, color: MyColors.dropdownGrey),
                                ),
                              CustomExpansionPanel(
                                isExpanded: assignedVaultList[i].isExpanded,
                                isAssigned:
                                    assignedVaultList[i].importKeyType != null,
                                onAssignedClicked: () {
                                  _showDialog(DialogType.deleteKey,
                                      keyIndex: i);
                                },
                                onExpansionChanged: () {
                                  setState(() {
                                    assignedVaultList[i].changeExpanded();
                                  });
                                },
                                unExpansionWidget: assignedVaultList[i]
                                            .importKeyType ==
                                        null
                                    ? _unExpansionWidget(i)
                                    : _unExpansionWidget(i, isAssigned: true),
                                expansionWidget: Column(
                                  children: [
                                    ExpansionChildWidget(
                                        type: ImportKeyType.internal,
                                        onPressed: () {
                                          if (_checkEmptyList()) {
                                            _showDialog(
                                                DialogType.notAvailable);
                                            return;
                                          }

                                          isButtonActiveNotifier.value = false;
                                          selectingVaultList = null;
                                          MyBottomSheet
                                              .showDraggableScrollableSheet(
                                            topWidget: true,
                                            onTopWidgetButtonClicked: () {
                                              setState(() {
                                                assignedVaultList[i]
                                                  ..item = selectingVaultList
                                                  ..isExpanded = false
                                                  ..importKeyType =
                                                      ImportKeyType.internal;
                                              });
                                              debugPrint(assignedVaultList[i]
                                                  .toString());
                                            },
                                            isButtonActiveNotifier:
                                                isButtonActiveNotifier,
                                            context: context,
                                            child: KeyListBottomScreen(
                                              onPressed:
                                                  (VaultListItem selectedItem) {
                                                selectingVaultList =
                                                    selectedItem;
                                                isButtonActiveNotifier.value =
                                                    true;
                                              },
                                              vaultList: vaultList,
                                              assignedList: assignedVaultList,
                                            ),
                                          );
                                        }),
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
                                          child: const ImportScannerScreen(),
                                        );

                                        if (externalImported != null) {
                                          if (_isAlreadyImportedExternalItem(
                                              externalImported)) {
                                            return _showDialog(
                                                DialogType.alreadyExist);
                                          }
                                          final confirmedExternalZPub =
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
                                            onBackPressed: () => _showDialog(
                                                DialogType.cancelImport),
                                            physics:
                                                const ClampingScrollPhysics(),
                                            enableSingleChildScroll: true,
                                            child: ConfirmImportingScreen(
                                              importingZpub: externalImported,
                                            ),
                                          );
                                          if (confirmedExternalZPub != null) {
                                            assignedVaultList[i]
                                              ..importKeyType =
                                                  ImportKeyType.external
                                              ..isExpanded = false
                                              ..zPubString =
                                                  externalImported // TODO: zpub만 따로 가져올 경우 처리 필요
                                              ..memo =
                                                  confirmedExternalZPub['memo'];
                                          }
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
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                padding: const EdgeInsets.all(10),
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
                  width: 12.0,
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
  VaultListItem? item;
  String? zPubString;
  String? memo;
  bool isExpanded;
  ImportKeyType? importKeyType;

  AssignedVaultListItem({
    required this.index,
    required this.importKeyType,
    required this.item,
    this.zPubString,
    this.isExpanded = false,
  });

  @override
  String toString() =>
      '[index]: ${index + 1}번 키\n[item]: ${item.toString()}\nmemo: $memo';

  void changeExpanded() {
    isExpanded = !isExpanded;
  }
}

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
}
