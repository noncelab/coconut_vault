import 'dart:async';

import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_detail/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/vault_detail/multi_sig_memo_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_detail/qrcode_bottom_sheet_screen.dart';
import 'package:coconut_vault/screens/vault_detail/vault_edit_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/information_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MultiSigSettingScreen extends StatefulWidget {
  final int id;
  const MultiSigSettingScreen({super.key, required this.id});

  @override
  State<MultiSigSettingScreen> createState() => _MultiSigSettingScreenState();
}

class _MultiSigSettingScreenState extends State<MultiSigSettingScreen> {
  late AppModel _appModel;
  late VaultModel _vaultModel;
  late MultisigVaultListItem _multiVault;
  final GlobalKey _tooltipIconKey = GlobalKey();

  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 0;
  late int signAvailableCount;

  @override
  void initState() {
    _appModel = Provider.of<AppModel>(context, listen: false);
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    _updateMultiVaultListItem();
    int innerVaultCount =
        _multiVault.signers.where((s) => s.innerVaultId != null).length;
    signAvailableCount = innerVaultCount > _multiVault.requiredSignatureCount
        ? _multiVault.requiredSignatureCount
        : innerVaultCount;
    super.initState();
  }

  _updateMultiVaultListItem() {
    final vaultBasItem = _vaultModel.getVaultById(widget.id);
    _multiVault = vaultBasItem as MultisigVaultListItem;
  }

  _showTooltip(BuildContext context) {
    _removeTooltip();

    setState(() {
      _tooltipRemainingTime = 5;
    });

    _tooltipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_tooltipRemainingTime > 0) {
          _tooltipRemainingTime--;
        } else {
          _removeTooltip();
          timer.cancel();
        }
      });
    });
  }

  _removeTooltip() {
    setState(() {
      _tooltipRemainingTime = 0;
    });
    _tooltipTimer?.cancel();
  }

  void _updateVaultInfo(
      String newName, int newColorIndex, int newIconIndex) async {
    // 변경 사항이 없는 경우
    if (newName == _multiVault.name &&
        newIconIndex == _multiVault.iconIndex &&
        newColorIndex == _multiVault.colorIndex) {
      return;
    }

    bool hasChanges = false;

    if (newName != _multiVault.name ||
        newIconIndex != _multiVault.iconIndex ||
        newColorIndex != _multiVault.colorIndex) {
      hasChanges = true;
    }

    if (newName != _multiVault.name && _vaultModel.isNameDuplicated(newName)) {
      CustomToast.showToast(
          context: context, text: '이미 사용하고 있는 이름으로는 바꿀 수 없어요');
      return;
    }

    if (hasChanges) {
      await _vaultModel.updateVault(
          widget.id, newName, newColorIndex, newIconIndex);

      _updateMultiVaultListItem();
      setState(() {});
      CustomToast.showToast(context: context, text: '정보를 수정했어요');
    }
  }

  _showModalBottomSheetForEditingNameAndIcon(
      String name, int colorIndex, int iconIndex) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: VaultInfoEditBottomSheet(
        name: name,
        iconIndex: iconIndex,
        colorIndex: colorIndex,
        onUpdate: (String newName, int newIconIndex, int newColorIndex) {
          _updateVaultInfo(newName, newColorIndex, newIconIndex);
        },
      ),
    );
  }

  _showEditMemoBottomSheet(MultisigSigner selectedVault, int index) {
    final selectedMemo = selectedVault.memo ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiSigMemoBottomSheet(
        memo: selectedMemo,
        onUpdate: (memo) {
          if (selectedMemo == memo) return;

          _vaultModel.updateMemo(widget.id, index, memo).then((_) {
            setState(() {
              String? finalMemo = memo;
              if (memo.isEmpty) {
                finalMemo = null;
              }
              _multiVault.signers[index].memo = finalMemo;
            });
            if (mounted) {
              Navigator.pop(context);
            }
          });
        },
      ),
    );
  }

  void _showModalBottomSheetWithQrImage(
      String appBarTitle, String data, Widget? qrcodeTopWidget) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: QrcodeBottomSheetScreen(
        qrData: data,
        title: appBarTitle,
        qrcodeTopWidget: qrcodeTopWidget,
      ),
    );
  }

  Future _verifyBiometric(int status, {MultisigSigner? multisigSigner}) async {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          screenStatus: PinCheckScreenStatus.info,
          isDeleteScreen: true,
          onComplete: () async {
            Navigator.pop(context);
            switch (status) {
              case 0:
                _showModalBottomSheetWithQrImage(
                  '확장 공개키',
                  multisigSigner!.keyStore.extendedPublicKey.serialize(),
                  null,
                );
                break;
              case 1:
                final base =
                    _vaultModel.getVaultById(multisigSigner!.innerVaultId!);
                final single = base as SinglesigVaultListItem;
                MyBottomSheet.showBottomSheet_90(
                  context: context,
                  child: MnemonicViewScreen(
                    walletId: single.id,
                    title: '니모닉 문구 보기',
                    subtitle: '패스프레이즈 보기',
                  ),
                );
                break;
              default:
                _vaultModel.deleteVault(widget.id);
                vibrateLight();
                Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
      ),
    );
  }

  Future _selectedKeyBottomSheet(
      MultisigSigner multisigSigner, int index) async {
    final isInnerVault = multisigSigner.innerVaultId != null;
    final name = multisigSigner.name ?? '';

    bool existsMemo = !isInnerVault && multisigSigner.memo != null;

    MyBottomSheet.showBottomSheet(
      context: context,
      title: TextUtils.ellipsisIfLonger(name), // overflow
      titleTextStyle: Styles.body1.copyWith(
        fontSize: 18,
      ),
      isCloseButton: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.only(bottom: 84),
        child: Column(
          children: [
            _bottomSheetButton(
              '다중 서명용 확장 공개키 보기',
              onPressed: () {
                _verifyBiometric(0, multisigSigner: multisigSigner);
              },
            ),
            const Divider(),
            _bottomSheetButton(
              isInnerVault
                  ? '니모닉 문구 보기'
                  : existsMemo
                      ? '메모 수정'
                      : '메모 추가',
              onPressed: () {
                if (isInnerVault) {
                  _verifyBiometric(1, multisigSigner: multisigSigner);
                } else {
                  _showEditMemoBottomSheet(multisigSigner, index);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheetButton(String title, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: () {
        onPressed.call();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          top: 30,
          bottom: 30,
          left: 8,
        ),
        width: double.infinity,
        child: Text(
          title,
          style: Styles.body1Bold,
          textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tooltipTop = MediaQuery.of(context).padding.top + 46;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _tooltipTimer?.cancel();
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.build(
          title: '${_multiVault.name} 정보',
          context: context,
          hasRightIcon: false,
          isBottom: false,
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // 다중 서명 지갑
                    Container(
                      margin:
                          const EdgeInsets.only(top: 20, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: MyColors.white,
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: CustomColorHelper.getGradientColors(
                              _multiVault.signers),
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.only(
                            left: 24, right: 24, top: 30, bottom: 24),
                        decoration: BoxDecoration(
                          color: MyColors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 아이콘
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BackgroundColorPalette[
                                    _multiVault.colorIndex],
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              child: SvgPicture.asset(
                                CustomIcons.getPathByIndex(
                                    _multiVault.iconIndex),
                                colorFilter: ColorFilter.mode(
                                    ColorPalette[_multiVault.colorIndex],
                                    BlendMode.srcIn),
                                width: 28.0,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // 이름, 편집버튼, 주소
                            Flexible(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(
                                        child: Text(
                                      _multiVault.name,
                                      style: Styles.h3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    const SizedBox(width: 7),
                                    GestureDetector(
                                        onTap: () {
                                          _removeTooltip();
                                          _showModalBottomSheetForEditingNameAndIcon(
                                            _multiVault.name,
                                            _multiVault.colorIndex,
                                            _multiVault.iconIndex,
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: MyColors.lightgrey),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Icon(
                                              Icons.edit,
                                              color: MyColors.darkgrey,
                                              size: 14,
                                            ),
                                          ),
                                        ))
                                  ]),
                                  Text(
                                    '다중 서명 주소',
                                    style: Styles.body2Bold.merge(
                                        const TextStyle(
                                            color:
                                                MyColors.transparentBlack_30)),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(
                              flex: 1,
                            ),

                            // MFP, M/N, 볼트로 N개 서명 가능
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$signAvailableCount개 서명 가능',
                                  style: Styles.body1Bold,
                                ),
                                TooltipButton(
                                  isSelected: false,
                                  text:
                                      '${_multiVault.requiredSignatureCount}/${_multiVault.signers.length}',
                                  isLeft: true,
                                  iconkey: _tooltipIconKey,
                                  containerMargin: EdgeInsets.zero,
                                  onTap: () {},
                                  onTapDown: (details) {
                                    _showTooltip(context);
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    // 상세 지갑 리스트
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      itemCount: _multiVault.signers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _multiVault.signers[index];

                        final isVaultKey = item.innerVaultId != null;
                        final name = item.name;
                        final memo = isVaultKey ? null : item.memo;
                        final colorIndex = item.colorIndex;
                        final iconIndex = item.iconIndex;
                        final mfp = item.keyStore.masterFingerprint;

                        return GestureDetector(
                          onTap: () {
                            _selectedKeyBottomSheet(item, index);
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                // 왼쪽 인덱스 번호
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: Styles.body2.merge(
                                      TextStyle(
                                          fontSize: 16,
                                          fontFamily:
                                              CustomFonts.number.getFontFamily),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12), // 간격

                                // 카드 영역
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: MyColors.white,
                                      borderRadius: BorderRadius.circular(17),
                                      border:
                                          Border.all(color: MyColors.greyE9),
                                    ),
                                    child: Row(
                                      children: [
                                        // 아이콘
                                        Container(
                                            padding: EdgeInsets.all(
                                                isVaultKey ? 8 : 10),
                                            decoration: BoxDecoration(
                                              color: isVaultKey
                                                  ? BackgroundColorPalette[
                                                      colorIndex!]
                                                  : MyColors.greyEC,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: SvgPicture.asset(
                                              isVaultKey
                                                  ? CustomIcons.getPathByIndex(
                                                      iconIndex!)
                                                  : 'assets/svg/download.svg',
                                              colorFilter: ColorFilter.mode(
                                                isVaultKey
                                                    ? ColorPalette[colorIndex!]
                                                    : MyColors.black,
                                                BlendMode.srcIn,
                                              ),
                                              width: isVaultKey ? 20 : 15,
                                            )),

                                        const SizedBox(width: 10),
                                        // 이름, 메모
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 이름
                                              Text(
                                                name ?? '',
                                                style: Styles.body2,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Visibility(
                                                visible: memo != null &&
                                                    memo.isNotEmpty,
                                                child: Text(
                                                  memo ?? '',
                                                  style: Styles.caption2,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // mfp
                                        Text(
                                          mfp,
                                          style: Styles.body1.copyWith(
                                              color: MyColors.darkgrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // 지갑설정 정보보기, 삭제하기
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0),
                          color: MyColors.transparentBlack_03,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              InformationRowItem(
                                label: '지갑 설정 정보 보기',
                                showIcon: true,
                                onPressed: () {
                                  _removeTooltip();

                                  Map<String, String> namesMap = {};
                                  for (var signer in _multiVault.signers) {
                                    namesMap[signer.keyStore
                                        .masterFingerprint] = signer.name ?? '';
                                  }

                                  Navigator.pushNamed(context, '/multisig-bsms',
                                      arguments: {
                                        'id': widget.id,
                                        'names': namesMap
                                      });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0),
                          color: MyColors.transparentBlack_03,
                        ),
                        child: Column(
                          children: [
                            InformationRowItem(
                              label: '삭제하기',
                              showIcon: true,
                              rightIcon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: MyColors.transparentWhite_70,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: SvgPicture.asset(
                                      'assets/svg/trash.svg',
                                      width: 16,
                                      colorFilter: const ColorFilter.mode(
                                          MyColors.warningText,
                                          BlendMode.srcIn))),
                              onPressed: () {
                                _removeTooltip();
                                showConfirmDialog(
                                  context: context,
                                  title: '확인',
                                  content:
                                      '정말로 볼트에서 ${_multiVault.name} 정보를 삭제하시겠어요?',
                                  onConfirmPressed: () async {
                                    _appModel.showIndicator();
                                    await Future.delayed(
                                        const Duration(seconds: 1));
                                    _verifyBiometric(2);
                                    _appModel.hideIndicator();
                                    //context.go('/');
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ToolTip
                Visibility(
                  visible: _tooltipRemainingTime > 0,
                  child: Positioned(
                    top: tooltipTop,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _removeTooltip(),
                      child: ClipPath(
                        clipper: RightTriangleBubbleClipper(),
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 25,
                            left: 10,
                            right: 10,
                            bottom: 10,
                          ),
                          color: MyColors.darkgrey,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_multiVault.signers.length}개의 키 중 ${_multiVault.requiredSignatureCount}개로 서명해야 하는\n다중 서명 지갑이예요.',
                                style: Styles.caption.merge(TextStyle(
                                  height: 1.3,
                                  fontFamily: CustomFonts.text.getFontFamily,
                                  color: MyColors.white,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }
}
