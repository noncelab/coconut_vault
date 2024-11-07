import 'package:coconut_vault/model/vault_list_item.dart';
import 'package:coconut_vault/model/vault_model.dart';
import 'package:coconut_vault/screens/vault_creation/key_list_bottom_screen.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_expansion_panel.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter/scheduler.dart';
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

  late int nCount; // 전체 키의 수
  late int mCount; // 필요한 서명 수
  late List<AssignedVaultListItem> assignedVaultList; // 키 가져오기에서 선택 완료한 객체
  late VaultListItem? selectingVaultList; // 키 가져오기 목록에서 선택중인 객체
  late List<VaultListItem> vaultList;
  late VaultModel _vaultModel;
  bool isFinishing = false;

  @override
  void initState() {
    super.initState();
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    _initAssigendVaultList();
    vaultList = _vaultModel.getVaults();
  }

  @override
  void dispose() {
    isButtonActiveNotifier.dispose();
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
    return assignedVaultList.where((e) => e.item != null).length;
  }

  void _initAssigendVaultList() {
    nCount = widget.nKeyCount;
    mCount = widget.mKeyCount;
    assignedVaultList = List.generate(
      nCount,
      (index) => AssignedVaultListItem(
        item: null,
        index: index,
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

  void _showDialog({bool isReset = true}) {
    CustomDialogs.showCustomAlertDialog(
      context,
      title: isReset ? '다시 고르기' : '볼트에 저장된 키가 없어요',
      message: isReset
          ? '지금까지 입력한 정보가 모두 지워져요.\n정말로 다시 선택하시겠어요?'
          : '키를 사용하기 위해 일반 지갑을 먼저 만드시겠어요?',
      cancelButtonText: isReset ? '취소' : '아니오',
      confirmButtonText: isReset ? '지우기' : '네',
      confirmButtonColor: isReset ? MyColors.warningText : MyColors.black,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        if (isReset) {
          isFinishing = true;
          Navigator.popUntil(
              context, (route) => route.settings.name == '/select-key-options');
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context,
              '/vault-creation-options',
              (Route<dynamic> route) =>
                  route.settings.name == '/select-vault-type');
        }
      },
    );
  }

  void _showStopGeneratingMultisigDialog() {
    CustomDialogs.showCustomAlertDialog(
      context,
      title: '다중 서명 지갑 만들기 중단',
      message: '정말 만들기를 그만하시겠어요?',
      cancelButtonText: '취소',
      confirmButtonText: '그만하기',
      confirmButtonColor: MyColors.warningText,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (Route<dynamic> route) => false);
      },
    );
  }

  void _onBackPressed(BuildContext context) {
    if (_getAssignedVaultListLength() > 0) {
      _showStopGeneratingMultisigDialog();
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
          onNextPressed: () =>
              Navigator.pushNamed(context, '/vault-name-setup'),
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
                                ? _showDialog(isReset: true)
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
                                isAssigned: assignedVaultList[i].item != null,
                                onAssignedClicked: () {
                                  CustomDialogs.showCustomAlertDialog(
                                    context,
                                    title: '${i + 1}번 키 초기화',
                                    message: '지정한 키 정보를 삭제하시겠어요?',
                                    cancelButtonText: '아니오',
                                    confirmButtonText: '네',
                                    confirmButtonColor: MyColors.warningText,
                                    onCancel: () => Navigator.pop(context),
                                    onConfirm: () {
                                      setState(() {
                                        assignedVaultList[i].item = null;
                                        assignedVaultList[i].isExpanded = true;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                                onExpansionChanged: () {
                                  setState(() {
                                    assignedVaultList[i].changeExpanded();
                                  });
                                },
                                unExpansionWidget: assignedVaultList[i].item ==
                                        null
                                    ? _unExpansionWidget(i)
                                    : _unExpansionWidget(i, isAssigned: true),
                                expansionWidget: Column(
                                  children: [
                                    ExpansionChildWidget(
                                        type: ImportKeyType.internal,
                                        onImported: (VaultListItem item) {
                                          debugPrint(item.toString());
                                        },
                                        onPressed: () {
                                          if (_checkEmptyList()) {
                                            _showDialog(isReset: false);
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
                                                  ..isExpanded = false;
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
                                      onImported: (VaultListItem item) {
                                        debugPrint(item.toString());
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
                  color: BackgroundColorPalette[
                      assignedVaultList[i].item!.colorIndex],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SvgPicture.asset(
                  CustomIcons.getPathByIndex(
                      assignedVaultList[i].item!.iconIndex),
                  colorFilter: ColorFilter.mode(
                    ColorPalette[assignedVaultList[i].item!.colorIndex],
                    BlendMode.srcIn,
                  ),
                  width: 12.0,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ' ${assignedVaultList[i].item!.name}',
                  style: Styles.body1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SvgPicture.asset(
                'assets/svg/circle-check.svg',
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
                'assets/svg/circle-check.svg',
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
  bool isExpanded;
  AssignedVaultListItem({
    required this.index,
    required this.item,
    this.isExpanded = false,
  });

  @override
  String toString() => '[index]: ${index + 1}번 키\n[item]: ${item.toString()}';

  void changeExpanded() {
    isExpanded = !isExpanded;
  }
}

class ExpansionChildWidget extends StatefulWidget {
  final ImportKeyType type;
  final void Function(VaultListItem) onImported;
  final VoidCallback? onPressed;
  final ValueNotifier<bool>? isButtonActiveNotifier;

  const ExpansionChildWidget({
    super.key,
    required this.type,
    required this.onImported,
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

enum ImportKeyType { internal, external }
