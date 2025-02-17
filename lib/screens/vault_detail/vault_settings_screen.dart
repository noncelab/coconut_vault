import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/singlesig/singlesig_vault_list_item.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_detail/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/vault_detail/qrcode_bottom_sheet_screen.dart';
import 'package:coconut_vault/screens/vault_detail/vault_edit_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/information_item_row.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/wallet_provider.dart';

class VaultSettingsScreen extends StatefulWidget {
  final int id;

  const VaultSettingsScreen({super.key, required this.id});

  @override
  State<VaultSettingsScreen> createState() => _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends State<VaultSettingsScreen> {
  late WalletProvider _walletProvider;
  late TextEditingController _nameTextController;
  late SinglesigVaultListItem _singleVaultItem;
  late SingleSignatureVault _singleSignatureVault;
  double _tooltipTopPadding = 0;

  late String _name;
  late String _titleName;
  late int _iconIndex;
  late int _colorIndex;

  final GlobalKey _tooltipIconKey = GlobalKey();
  RenderBox? _tooltipIconRendBox;
  Offset _tooltipIconPosition = Offset.zero;
  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 0;

  @override
  void initState() {
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    super.initState();
    // id 접근: widget.id
    _singleVaultItem =
        _walletProvider.getVaultById(widget.id) as SinglesigVaultListItem;

    if (_singleVaultItem.coconutVault is SingleSignatureVault) {
      _singleSignatureVault =
          _singleVaultItem.coconutVault as SingleSignatureVault;
    }

    _nameTextController = TextEditingController(text: _singleVaultItem.name);
    _name = _singleVaultItem.name;
    _titleName = _name;
    _iconIndex = _singleVaultItem.iconIndex;
    _colorIndex = _singleVaultItem.colorIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipIconRendBox =
          _tooltipIconKey.currentContext?.findRenderObject() as RenderBox;
      _tooltipIconPosition = _tooltipIconRendBox!.localToGlobal(Offset.zero);
      _tooltipTopPadding =
          MediaQuery.paddingOf(context).top + kToolbarHeight - 14;
    });
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _showModalBottomSheetWithQrImage(
      String appBarTitle, String data, Widget? qrcodeTopWidget) {
    MyBottomSheet.showBottomSheet_90(
        context: context,
        child: QrcodeBottomSheetScreen(
            qrData: data,
            title: appBarTitle,
            qrcodeTopWidget: qrcodeTopWidget));
  }

  void _updateVaultInfo(
      String newName, int newColorIndex, int newIconIndex) async {
    // 변경 사항이 없는 경우
    if (newName == _name &&
        newIconIndex == _iconIndex &&
        newColorIndex == _colorIndex) {
      return;
    }

    bool hasChanges = false;

    if (newName != _name ||
        newIconIndex != _iconIndex ||
        newColorIndex != _colorIndex) {
      hasChanges = true;
    }

    if (_name != newName && (newName != _singleVaultItem.name)) {
      if (_walletProvider.isNameDuplicated(newName)) {
        CustomToast.showToast(
            context: context, text: t.toast.name_already_used);
        return;
      }
    }

    if (hasChanges) {
      await _walletProvider.updateVault(
          widget.id, newName, newColorIndex, newIconIndex);

      setState(() {
        _name = newName;
        _titleName = newName;
        _iconIndex = newIconIndex;
        _colorIndex = newColorIndex;
      });

      CustomToast.showToast(context: context, text: t.toast.data_updated);
    }
  }

  void _showModalBottomSheetForEditingNameAndIcon(
      String name, int colorIndex, int iconIndex) {
    MyBottomSheet.showBottomSheet_90(
        context: context,
        child: VaultInfoEditBottomSheet(
          name: name,
          iconIndex: iconIndex,
          colorIndex: colorIndex,
          onUpdate: (String newName, int newIconIndex, int newColorIndex) {
            setState(() {
              _updateVaultInfo(newName, newColorIndex, newIconIndex);
            });
          },
        ));
  }

  Future<void> _verifyBiometric(int status) async {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          isDeleteScreen: true,
          onComplete: () async {
            Navigator.pop(context);
            _verifySwitch(status);
          },
        ),
      ),
    );
  }

  void _verifySwitch(int status) async {
    // 0 -> 확장 공개키, 1 -> 니모닉, 2 -> 삭제
    switch (status) {
      case 0:
        {
          _showModalBottomSheetWithQrImage(
              t.extended_public_key,
              _singleSignatureVault.keyStore.extendedPublicKey.serialize(),
              null);
        }
      case 1:
        {
          MyBottomSheet.showBottomSheet_90(
              context: context,
              child: MnemonicViewScreen(
                walletId: widget.id,
                title: t.view_mnemonic,
                subtitle: t.view_passphrase,
              ));
        }
      default:
        {
          _walletProvider.deleteVault(widget.id);
          vibrateLight();
          Navigator.popUntil(context, (route) => route.isFirst);
        }
    }
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _removeTooltip();
      },
      child: CustomLoadingOverlay(
        child: Scaffold(
          backgroundColor: MyColors.white,
          appBar: CustomAppBar.build(
              title: '$_titleName ${t.info}',
              context: context,
              hasRightIcon: false,
              isBottom:
                  _singleVaultItem.linkedMultisigInfo?.keys.isNotEmpty == true),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 볼트 네임 카드
                          VaultItemCard(
                            vaultItem: _singleVaultItem,
                            onTooltipClicked: () => _showTooltip(context),
                            onNameChangeClicked: () {
                              _removeTooltip();
                              _showModalBottomSheetForEditingNameAndIcon(
                                _name,
                                _colorIndex,
                                _iconIndex,
                              );
                            },
                            tooltipKey: _tooltipIconKey,
                          ),
                          if (_singleVaultItem
                                  .linkedMultisigInfo?.entries.isNotEmpty ==
                              true) ...{
                            Container(
                              margin: const EdgeInsets.only(
                                  bottom: 12, left: 16, right: 16),
                              decoration: BoxDecoration(
                                color: MyColors.white,
                                borderRadius: BorderRadius.circular(22),
                                gradient: const LinearGradient(
                                  colors: [
                                    MyColors.multiSigGradient1,
                                    MyColors.multiSigGradient2,
                                    MyColors.multiSigGradient3,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(1),
                                padding: const EdgeInsets.only(
                                    left: 20, right: 20, top: 20, bottom: 14),
                                decoration: BoxDecoration(
                                  color: MyColors.white,
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 아이콘
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/svg/vault-grey.svg',
                                          width: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          t.vault_settings_screen
                                              .used_in_multisig,
                                          style: Styles.body2,
                                        ),
                                      ],
                                    ),

                                    const Padding(
                                      padding: EdgeInsets.only(
                                          top: 4, bottom: 4, left: 28),
                                      child: Divider(),
                                    ),

                                    Selector<WalletProvider, bool>(
                                        selector: (context, model) =>
                                            model.isLoadVaultList,
                                        builder:
                                            (context, isLoadVaultList, child) {
                                          return ListView.builder(
                                            itemCount: _singleVaultItem
                                                .linkedMultisigInfo!
                                                .keys
                                                .length,
                                            shrinkWrap: true,
                                            itemBuilder: (context, index) {
                                              final id = _singleVaultItem
                                                  .linkedMultisigInfo!.keys
                                                  .elementAt(index);
                                              final idx = _singleVaultItem
                                                  .linkedMultisigInfo!.values
                                                  .elementAt(index);

                                              if (isLoadVaultList &&
                                                  _walletProvider.vaultList.any(
                                                      (element) =>
                                                          element.id == id)) {
                                                final multisig = _walletProvider
                                                    .getVaultById(id);
                                                return InkWell(
                                                  onTap: () {
                                                    Navigator.pushNamed(context,
                                                        AppRoutes.multisigSetup,
                                                        arguments: {'id': id});
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 28,
                                                            bottom: 4),
                                                    color: Colors.transparent,
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: Styles.body2
                                                            .copyWith(
                                                          color:
                                                              MyColors.linkBlue,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: TextUtils
                                                                .ellipsisIfLonger(
                                                                    multisig
                                                                        .name),
                                                            style: Styles
                                                                .body2Bold
                                                                .copyWith(
                                                              color: MyColors
                                                                  .linkBlue,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                              text: t
                                                                  .vault_settings_screen
                                                                  .of),
                                                          TextSpan(
                                                            text: t
                                                                .vault_settings_screen
                                                                .nth(
                                                                    index: idx +
                                                                        1),
                                                            style: Styles
                                                                .body2Bold
                                                                .copyWith(
                                                              color: MyColors
                                                                  .linkBlue,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                              text: t
                                                                  .vault_settings_screen
                                                                  .key),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 28, bottom: 4),
                                                  child: Shimmer.fromColors(
                                                    baseColor:
                                                        Colors.grey[300]!,
                                                    highlightColor:
                                                        Colors.grey[100]!,
                                                    child: Container(
                                                      height: 17,
                                                      width: double.maxFinite,
                                                      color: Colors.grey[300],
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        }),
                                  ],
                                ),
                              ),
                            ),
                          } else ...{
                            const SizedBox(height: 20),
                          },
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28.0),
                                    color: MyColors.transparentBlack_03,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Column(
                                      children: [
                                        // InformationRowItem(
                                        //     label: '확장 공개키 보기',
                                        //     showIcon: true,
                                        //     onPressed: () {
                                        //       _removeTooltip();
                                        //       _verifyBiometric(0);
                                        //     }),
                                        // const Divider(
                                        //     color: MyColors.borderLightgrey,
                                        //     height: 1),
                                        InformationRowItem(
                                          label: t.view_mnemonic,
                                          showIcon: true,
                                          onPressed: () {
                                            _removeTooltip();
                                            _verifyBiometric(1);
                                          },
                                        ),
                                      ],
                                    ),
                                  ))),
                          const SizedBox(height: 32),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28.0),
                                    color: MyColors.transparentBlack_03,
                                  ),
                                  child: Column(
                                    children: [
                                      InformationRowItem(
                                        label: t.delete,
                                        showIcon: true,
                                        textColor: _singleVaultItem
                                                    .linkedMultisigInfo
                                                    ?.entries
                                                    .isNotEmpty ==
                                                true
                                            ? MyColors.disabledGrey
                                                .withOpacity(0.15)
                                            : null,
                                        rightIcon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: MyColors.transparentWhite_70,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/svg/trash.svg',
                                            width: 16,
                                            colorFilter: ColorFilter.mode(
                                              _singleVaultItem
                                                          .linkedMultisigInfo
                                                          ?.entries
                                                          .isNotEmpty ==
                                                      true
                                                  ? MyColors.disabledGrey
                                                      .withOpacity(0.15)
                                                  : MyColors.warningText,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          _removeTooltip();
                                          if (_singleVaultItem
                                                  .linkedMultisigInfo
                                                  ?.entries
                                                  .isNotEmpty ==
                                              true) {
                                            CustomToast.showToast(
                                              context: context,
                                              text:
                                                  t.toast.name_multisig_in_use,
                                            );
                                          } else {
                                            showConfirmDialog(
                                                context: context,
                                                title: t.confirm,
                                                content: t.alert
                                                    .confirm_deletion(
                                                        name: _name),
                                                onConfirmPressed: () async {
                                                  context.loaderOverlay.show();
                                                  await Future.delayed(
                                                      const Duration(
                                                          seconds: 1));
                                                  _verifyBiometric(2);
                                                  context.loaderOverlay.hide();
                                                  //context.go('/');
                                                });
                                          }
                                        },
                                      ),
                                    ],
                                  ))),
                        ],
                      ),
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
                                    t.tooltip.mfp,
                                    style: Styles.caption.merge(TextStyle(
                                      height: 1.3,
                                      fontFamily:
                                          CustomFonts.text.getFontFamily,
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
        ),
      ),
    );
  }
}
