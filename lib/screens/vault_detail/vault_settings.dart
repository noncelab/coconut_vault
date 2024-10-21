import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_detail/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/vault_detail/qrcode_bottom_sheet_screen.dart';
import 'package:coconut_vault/screens/vault_detail/vault_edit_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/information_item_row.dart';
import 'package:provider/provider.dart';

import '../../model/vault_model.dart';
import '../../model/vault_list_item.dart';

class VaultSettings extends StatefulWidget {
  final String id;

  const VaultSettings({super.key, required this.id});

  @override
  State<VaultSettings> createState() => _VaultSettingsState();
}

class _VaultSettingsState extends State<VaultSettings> {
  late AppModel _appModel;
  late VaultModel _vaultModel;
  OverlayEntry? _overlayEntry;
  late TextEditingController _nameTextController;
  late VaultListItem _vaultListItem;
  late String _name;
  late String _titleName;
  late int _iconIndex;
  late int _colorIndex;

  final GlobalKey _tooltipIconKey = GlobalKey();
  late RenderBox _tooltipIconRendBox;
  late Offset _tooltipIconPosition;
  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 5;

  @override
  void initState() {
    _appModel = Provider.of<AppModel>(context, listen: false);
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    // id 접근: widget.id
    _vaultListItem = _vaultModel.getVaultById(int.parse(widget.id));
    _nameTextController = TextEditingController(text: _vaultListItem.name);
    _name = _vaultListItem.name;
    _titleName = _getEllipsedNameIfOver10(_name);
    _iconIndex = _vaultListItem.iconIndex;
    _colorIndex = _vaultListItem.colorIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipIconRendBox =
          _tooltipIconKey.currentContext?.findRenderObject() as RenderBox;
      _tooltipIconPosition = _tooltipIconRendBox.localToGlobal(Offset.zero);
    });
  }

  static String _getEllipsedNameIfOver10(String name) {
    return name.length > 10 ? '${name.substring(0, 7)}...' : name;
  }

  @override
  void dispose() {
    _nameTextController.dispose();
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

    if (_name != newName && (newName != _vaultListItem.name)) {
      if (_vaultModel.isNameDuplicated(newName)) {
        CustomToast.showToast(
            context: context, text: '이미 사용하고 있는 이름으로는 바꿀 수 없어요');
        return;
      }
    }

    if (hasChanges) {
      await _vaultModel.updateVault(
          int.parse(widget.id), newName, newColorIndex, newIconIndex);

      setState(() {
        _name = newName;
        _titleName = _getEllipsedNameIfOver10(newName);
        _iconIndex = newIconIndex;
        _colorIndex = newColorIndex;
      });

      CustomToast.showToast(context: context, text: '정보를 수정했어요');
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
          screenStatus: PinCheckScreenStatus.info,
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
          SingleSignatureVault vault = _vaultListItem.coconutVault;
          _showModalBottomSheetWithQrImage(
              '확장 공개키', vault.keyStore.extendedPublicKey.serialize(), null);
        }
      case 1:
        {
          MyBottomSheet.showBottomSheet_90(
              context: context,
              child: MnemonicViewScreen(
                mnemonic: _vaultListItem.secret,
                passphrase: _vaultListItem.passphrase,
                title: '니모닉 문구 보기',
                subtitle: '패스프레이즈 보기',
              ));
        }
      default:
        {
          _vaultModel.deleteVault(int.parse(widget.id));
          vibrateLight();
          Navigator.popUntil(context, (route) => route.isFirst);
        }
    }
  }

  void _showTooltip(BuildContext context, Offset position, String tip) {
    _removeTooltip();

    _tooltipRemainingTime = 5;
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

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
          top: position.dy + 16,
          right: MediaQuery.of(context).size.width - position.dx - 48,
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
                      tip,
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
          )),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeTooltip() {
    if (_overlayEntry != null) {
      if (_tooltipTimer != null) {
        _tooltipTimer!.cancel();
      }
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (_) {
        _removeTooltip();
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.build(
            title: '$_titleName 정보',
            context: context,
            hasRightIcon: false,
            isBottom: true),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                      color: MyColors.borderLightgrey,
                                      width: 0.5)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            BackgroundColorPalette[_colorIndex],
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                      ),
                                      child: SvgPicture.asset(
                                          CustomIcons.getPathByIndex(
                                              _iconIndex),
                                          colorFilter: ColorFilter.mode(
                                              ColorPalette[_colorIndex],
                                              BlendMode.srcIn),
                                          width: 28.0)),
                                  const SizedBox(width: 8.0),
                                  Flexible(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Flexible(
                                              child: Text(
                                            _name,
                                            style: Styles.h3,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )),
                                          const SizedBox(width: 7),
                                          GestureDetector(
                                              onTap: () {
                                                _removeTooltip();
                                                _showModalBottomSheetForEditingNameAndIcon(
                                                    _name,
                                                    _colorIndex,
                                                    _iconIndex);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
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
                                          "bc1주소",
                                          style: Styles.body2Bold.merge(
                                              const TextStyle(
                                                  color: MyColors
                                                      .transparentBlack_30)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(
                                    flex: 1,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _vaultListItem
                                            .coconutVault.keyStore.fingerprint,
                                        style: Styles.h3.merge(TextStyle(
                                            fontFamily: CustomFonts
                                                .number.getFontFamily)),
                                      ),
                                      TooltipButton(
                                        isSelected: false,
                                        text: '지갑 ID',
                                        isLeft: true,
                                        iconkey: _tooltipIconKey,
                                        containerMargin: EdgeInsets.zero,
                                        onTap: () {},
                                        onTapDown: (details) {
                                          _showTooltip(
                                            context,
                                            _tooltipIconPosition,
                                            '지갑의 고유 값이예요.\n마스터 핑거프린트(MFP)라고도 해요.',
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              )),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                        label: '니모닉 문구 보기',
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
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
                                              color:
                                                  MyColors.transparentWhite_70,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: SvgPicture.asset(
                                              'assets/svg/trash.svg',
                                              width: 16,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                      MyColors.warningText,
                                                      BlendMode.srcIn))),
                                      onPressed: () {
                                        _removeTooltip();
                                        showConfirmDialog(
                                            context: context,
                                            title: '확인',
                                            content:
                                                '정말로 볼트에서 $_name 정보를 삭제하시겠어요?',
                                            onConfirmPressed: () async {
                                              _appModel.showIndicator();
                                              await Future.delayed(
                                                  const Duration(seconds: 1));
                                              _verifyBiometric(2);
                                              _appModel.hideIndicator();
                                              //context.go('/');
                                            });
                                      },
                                    ),
                                  ],
                                ))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
