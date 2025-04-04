import 'dart:async';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/common/qrcode_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_signer_memo_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/card/information_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

class MultisigSetupInfoScreen extends StatefulWidget {
  final int id;
  const MultisigSetupInfoScreen({super.key, required this.id});

  @override
  State<MultisigSetupInfoScreen> createState() =>
      _MultisigSetupInfoScreenState();
}

class _MultisigSetupInfoScreenState extends State<MultisigSetupInfoScreen> {
  late WalletProvider _walletProvider;
  late MultisigVaultListItem _multiVault;

  final GlobalKey _tooltipIconKey = GlobalKey();
  RenderBox? _tooltipIconRenderBox;
  Offset _tooltipIconPosition = Offset.zero;
  double _tooltipTopPadding = 0;

  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 0;
  late int signAvailableCount;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _updateMultiVaultListItem();
    int innerVaultCount =
        _multiVault.signers.where((s) => s.innerVaultId != null).length;
    signAvailableCount = innerVaultCount > _multiVault.requiredSignatureCount
        ? _multiVault.requiredSignatureCount
        : innerVaultCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipIconRenderBox =
          _tooltipIconKey.currentContext?.findRenderObject() as RenderBox;
      _tooltipIconPosition = _tooltipIconRenderBox!.localToGlobal(Offset.zero);

      _tooltipTopPadding =
          MediaQuery.paddingOf(context).top + kToolbarHeight - 14;
    });
  }

  _updateMultiVaultListItem() {
    final vaultBasItem = _walletProvider.getVaultById(widget.id);
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

    if (newName != _multiVault.name &&
        _walletProvider.isNameDuplicated(newName)) {
      CustomToast.showToast(context: context, text: t.toast.name_already_used);
      return;
    }

    if (hasChanges) {
      await _walletProvider.updateVault(
          widget.id, newName, newColorIndex, newIconIndex);

      _updateMultiVaultListItem();
      setState(() {});
      CustomToast.showToast(context: context, text: t.toast.data_updated);
    }
  }

  _showModalBottomSheetForEditingNameAndIcon(
      String name, int colorIndex, int iconIndex) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: NameAndIconEditBottomSheet(
        name: name,
        iconIndex: iconIndex,
        colorIndex: colorIndex,
        onUpdate: (String newName, int newIconIndex, int newColorIndex) {
          _updateVaultInfo(newName, newColorIndex, newIconIndex);
        },
      ),
    );
  }

  _showEditMemoBottomSheet(MultisigSigner selectedVault) {
    final selectedMemo = selectedVault.memo ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultisigSignerMemoBottomSheet(
        memo: selectedMemo,
        onUpdate: (memo) {
          if (selectedMemo == memo) return;

          _walletProvider
              .updateMemo(widget.id, selectedVault.id, memo)
              .then((_) {
            setState(() {
              String? finalMemo = memo;
              if (memo.isEmpty) {
                finalMemo = null;
              }
              _multiVault.signers[selectedVault.id].memo = finalMemo;
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
      child: QrcodeBottomSheet(
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
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          isDeleteScreen: true,
          onComplete: () async {
            Navigator.pop(context);
            switch (status) {
              case 0:
                _showModalBottomSheetWithQrImage(
                  t.extended_public_key,
                  multisigSigner!.keyStore.extendedPublicKey.serialize(),
                  null,
                );
                break;
              case 1:
                final base =
                    _walletProvider.getVaultById(multisigSigner!.innerVaultId!);
                final single = base as SingleSigVaultListItem;
                MyBottomSheet.showBottomSheet_90(
                  context: context,
                  child: MnemonicViewScreen(
                    walletId: single.id,
                    title: t.view_mnemonic,
                    subtitle: t.view_passphrase,
                  ),
                );
                break;
              default:
                _walletProvider.deleteVault(widget.id);
                vibrateLight();
                Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
      ),
    );
  }

  Future _openOutsideWalletBottomMenu(MultisigSigner multisigSigner) async {
    assert(multisigSigner.innerVaultId == null);
    final name = multisigSigner.name ?? '';

    bool existsMemo = multisigSigner.memo?.isNotEmpty == true;

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
            // _bottomSheetButton(
            //   '다중 서명용 확장 공개키 보기',
            //   onPressed: () {
            //     _verifyBiometric(0, multisigSigner: multisigSigner);
            //   },
            // ),
            // const Divider(),
            _bottomSheetButton(
              existsMemo
                  ? t.multi_sig_setting_screen.edit_memo
                  : t.multi_sig_setting_screen.add_memo,
              onPressed: () {
                _showEditMemoBottomSheet(multisigSigner);
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
        _removeTooltip();
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _removeTooltip();
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.build(
          title: '${_multiVault.name} ${t.info}',
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
                    VaultItemCard(
                        vaultItem: _multiVault,
                        onTooltipClicked: () => _showTooltip(context),
                        onNameChangeClicked: () {
                          _removeTooltip();
                          _showModalBottomSheetForEditingNameAndIcon(
                            _multiVault.name,
                            _multiVault.colorIndex,
                            _multiVault.iconIndex,
                          );
                        },
                        tooltipKey: _tooltipIconKey),
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

                        final isInnerWallet = item.innerVaultId != null;
                        final name = item.name;
                        final memo = isInnerWallet ? null : item.memo;
                        final colorIndex = item.colorIndex;
                        final iconIndex = item.iconIndex;
                        final mfp = item.keyStore.masterFingerprint;

                        return GestureDetector(
                          onTap: () {
                            _removeTooltip();
                            if (isInnerWallet) {
                              Navigator.pushNamed(
                                  context, AppRoutes.singleSigSetupInfo,
                                  arguments: {
                                    'id': item.innerVaultId,
                                  });
                            } else {
                              _openOutsideWalletBottomMenu(item);
                            }
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
                                      borderRadius: MyBorder.defaultRadius,
                                      border:
                                          Border.all(color: MyColors.greyE9),
                                    ),
                                    child: Row(
                                      children: [
                                        // 아이콘
                                        Container(
                                            padding: EdgeInsets.all(
                                                isInnerWallet ? 8 : 10),
                                            decoration: BoxDecoration(
                                              color: isInnerWallet
                                                  ? BackgroundColorPalette[
                                                      colorIndex!]
                                                  : MyColors.greyEC,
                                              borderRadius:
                                                  BorderRadius.circular(14.0),
                                            ),
                                            child: SvgPicture.asset(
                                              isInnerWallet
                                                  ? CustomIcons.getPathByIndex(
                                                      iconIndex!)
                                                  : 'assets/svg/download.svg',
                                              colorFilter: ColorFilter.mode(
                                                isInnerWallet
                                                    ? ColorPalette[colorIndex!]
                                                    : MyColors.black,
                                                BlendMode.srcIn,
                                              ),
                                              width: isInnerWallet ? 20 : 15,
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
                                          style: Styles.mfpH3,
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
                          borderRadius: MyBorder.defaultRadius,
                          color: MyColors.transparentBlack_03,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              InformationItemCard(
                                label: t.multi_sig_setting_screen.view_bsms,
                                showIcon: true,
                                onPressed: () {
                                  _removeTooltip();

                                  Navigator.pushNamed(
                                      context, AppRoutes.multisigBsmsView,
                                      arguments: {
                                        'id': widget.id,
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
                          borderRadius: MyBorder.defaultRadius,
                          color: MyColors.transparentBlack_03,
                        ),
                        child: Column(
                          children: [
                            InformationItemCard(
                              label: t.delete,
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
                                  title: t.confirm,
                                  content: t.alert
                                      .confirm_deletion(name: _multiVault.name),
                                  onConfirmPressed: () async {
                                    context.loaderOverlay.show();
                                    await Future.delayed(
                                        const Duration(seconds: 1));
                                    _verifyBiometric(2);
                                    context.loaderOverlay.hide();
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
                Visibility(
                  visible: _tooltipRemainingTime > 0,
                  child: Positioned(
                    top: _tooltipIconPosition.dy - _tooltipTopPadding,
                    right: MediaQuery.sizeOf(context).width -
                        _tooltipIconPosition.dx -
                        48,
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
                                t.multi_sig_setting_screen.tooltip(
                                    total: _multiVault.signers.length,
                                    count: _multiVault.requiredSignatureCount),
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
