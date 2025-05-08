import 'dart:async';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/single_sig_setup_info_view_model.dart';
import 'package:coconut_vault/screens/vault_menu/info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/mnemonic_view_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/card/information_item_card.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../providers/wallet_provider.dart';

class SingleSigSetupInfoScreen extends StatefulWidget {
  final int id;
  const SingleSigSetupInfoScreen({super.key, required this.id});

  @override
  State<SingleSigSetupInfoScreen> createState() => _SingleSigSetupInfoScreenState();
}

class _SingleSigSetupInfoScreenState extends State<SingleSigSetupInfoScreen> {
  final GlobalKey _tooltipIconKey = GlobalKey();
  RenderBox? _tooltipIconRendBox;
  Offset _tooltipIconPosition = Offset.zero;
  double _tooltipTopPadding = 0;

  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipIconRendBox = _tooltipIconKey.currentContext?.findRenderObject() as RenderBox;
      _tooltipIconPosition = _tooltipIconRendBox!.localToGlobal(Offset.zero);
      _tooltipTopPadding = MediaQuery.paddingOf(context).top + kToolbarHeight - 14;
    });
  }

  Future<void> _verifyBiometric(BuildContext context, PinCheckContextEnum pinCheckContext) async {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: pinCheckContext,
          onComplete: () async {
            Navigator.pop(context);
            _verifySwitch(context, pinCheckContext);
          },
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
      child: CustomLoadingOverlay(
        child: ChangeNotifierProvider(
          create: (context) => SingleSigSetupInfoViewModel(
              Provider.of<WalletProvider>(context, listen: false), widget.id),
          child: Consumer<SingleSigSetupInfoViewModel>(builder: (context, viewModel, child) {
            return Scaffold(
              backgroundColor: MyColors.white,
              appBar: CustomAppBar.build(
                  title: '${viewModel.name} ${t.info}',
                  context: context,
                  hasRightIcon: false,
                  isBottom: viewModel.hasLinkedMultisigVault),
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
                              _buildVaultItemCard(context),
                              (viewModel.hasLinkedMultisigVault == true)
                                  ? _buildLinkedMultisigVaultInfoCard(context)
                                  : const SizedBox(height: 20),
                              _buildMnemonicViewAction(context),
                              _buildDivider(),
                              _buildDeleteButton(context)
                            ],
                          ),
                        ),
                        _buildTooltip(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVaultItemCard(BuildContext context) {
    final viewModel = context.watch<SingleSigSetupInfoViewModel>();
    return VaultItemCard(
      vaultItem: viewModel.vaultItem,
      onTooltipClicked: () => _showTooltip(context),
      onNameChangeClicked: () {
        _removeTooltip();
        _showModalBottomSheetForEditingNameAndIcon(viewModel);
      },
      tooltipKey: _tooltipIconKey,
    );
  }

  void _showModalBottomSheetForEditingNameAndIcon(SingleSigSetupInfoViewModel viewModel) {
    MyBottomSheet.showBottomSheet_90(
        context: context,
        child: NameAndIconEditBottomSheet(
          name: viewModel.name,
          iconIndex: viewModel.iconIndex,
          colorIndex: viewModel.colorIndex,
          onUpdate: (String newName, int newIconIndex, int newColorIndex) {
            setState(() {
              _updateVaultInfo(newName, newColorIndex, newIconIndex, viewModel);
            });
          },
        ));
  }

  void _updateVaultInfo(String newName, int newColorIndex, int newIconIndex,
      SingleSigSetupInfoViewModel viewModel) async {
    // 변경 사항이 없는 경우
    if (newName == viewModel.name &&
        newIconIndex == viewModel.iconIndex &&
        newColorIndex == viewModel.colorIndex) {
      return;
    }

    bool hasChanged = await viewModel.updateVault(widget.id, newName, newColorIndex, newIconIndex);

    if (mounted) {
      if (hasChanged) {
        CustomToast.showToast(context: context, text: t.toast.data_updated);
        return;
      }
      CustomToast.showToast(context: context, text: t.toast.name_already_used);
    }
  }

  Widget _buildLinkedMultisigVaultInfoCard(BuildContext context) {
    const linearGradient = LinearGradient(
      colors: [
        MyColors.multiSigGradient1,
        MyColors.multiSigGradient2,
        MyColors.multiSigGradient3,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: MyColors.white,
        borderRadius: BorderRadius.circular(22),
        gradient: linearGradient,
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 14),
        decoration: BoxDecoration(
          color: MyColors.white,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & used in multisig vault text
            Row(
              children: [
                SvgPicture.asset(
                  'assets/svg/vault-grey.svg',
                  width: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  t.vault_settings.used_in_multisig,
                  style: Styles.body2,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4, left: 28),
              child: Divider(),
            ),

            // Linked multisig vaults
            Consumer<SingleSigSetupInfoViewModel>(builder: (context, viewModel, child) {
              return ListView.builder(
                itemCount: viewModel.linkedMutlsigVaultCount,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final id = viewModel.linkedMultisigInfo!.keys.elementAt(index);
                  final idx = viewModel.linkedMultisigInfo!.values.elementAt(index);

                  if (viewModel.isLoadedVaultList && viewModel.existsLinkedMultisigVault(id)) {
                    final multisig = viewModel.getVaultById(id);

                    return InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.multisigSetupInfo,
                            arguments: {'id': id});
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 28, bottom: 4),
                        color: Colors.transparent,
                        child: RichText(
                          text: TextSpan(
                            style: Styles.body2.copyWith(
                              color: MyColors.linkBlue,
                            ),
                            children: [
                              TextSpan(
                                text: TextUtils.ellipsisIfLonger(multisig.name),
                                style: Styles.body2Bold.copyWith(
                                  color: MyColors.linkBlue,
                                ),
                              ),
                              TextSpan(text: t.vault_settings.of),
                              TextSpan(
                                text: t.vault_settings.nth(index: idx + 1),
                                style: Styles.body2Bold.copyWith(
                                  color: MyColors.linkBlue,
                                ),
                              ),
                              TextSpan(text: t.vault_settings.key),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.only(left: 28, bottom: 4),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
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
    );
  }

  Widget _buildMnemonicViewAction(BuildContext context) {
    return Padding(
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
                  // InformationRowItem(
                  //     label: '확장 공개키 보기',
                  //     showIcon: true,
                  //     onPressed: () {
                  //       _removeTooltip();
                  //       _verifyBiometric(context, SecurityAction.viewExtendedPublicKey);
                  //     }),
                  // const Divider(
                  //     color: MyColors.borderLightgrey,
                  //     height: 1),
                  InformationItemCard(
                    label: t.view_mnemonic,
                    showIcon: true,
                    onPressed: () {
                      _removeTooltip();
                      _verifyBiometric(context, PinCheckContextEnum.sensitiveAction);
                    },
                  ),
                ],
              ),
            )));
  }

  Widget _buildDeleteButton(BuildContext context) {
    final viewModel = context.read<SingleSigSetupInfoViewModel>();
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
              color: MyColors.transparentBlack_03,
            ),
            child: Column(
              children: [
                Selector<SingleSigSetupInfoViewModel, ({bool canDelete, String walletName})>(
                    selector: (context, viewModel) => (
                          canDelete: viewModel.hasLinkedMultisigVault != true,
                          walletName: viewModel.name,
                        ),
                    builder: (context, data, child) {
                      return InformationItemCard(
                        label: t.delete_label,
                        showIcon: true,
                        textColor: viewModel.hasLinkedMultisigVault
                            ? MyColors.disabledGrey.withOpacity(0.15)
                            : null,
                        rightIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MyColors.transparentWhite_70,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/trash.svg',
                            width: 16,
                            colorFilter: ColorFilter.mode(
                              data.canDelete
                                  ? MyColors.warningText
                                  : MyColors.disabledGrey.withOpacity(0.15),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        onPressed: () {
                          _removeTooltip();
                          if (data.canDelete) {
                            showConfirmDialog(
                                context: context,
                                title: t.confirm,
                                content: t.alert.confirm_deletion(name: data.walletName),
                                onConfirmPressed: () async {
                                  context.loaderOverlay.show();
                                  await Future.delayed(const Duration(seconds: 1));
                                  if (context.mounted) {
                                    _verifyBiometric(context, PinCheckContextEnum.seedDeletion);
                                    context.loaderOverlay.hide();
                                  }
                                });
                            return;
                          }

                          CustomToast.showToast(
                            context: context,
                            text: t.toast.name_multisig_in_use,
                          );
                        },
                      );
                    }),
              ],
            )));
  }

  void _verifySwitch(BuildContext context, PinCheckContextEnum pinCheckContext) async {
    if (pinCheckContext == PinCheckContextEnum.seedDeletion) {
      final viewModel = context.read<SingleSigSetupInfoViewModel>();
      viewModel.deleteVault();
      vibrateLight();
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    MyBottomSheet.showBottomSheet_90(
        context: context,
        child: MnemonicViewScreen(
          walletId: widget.id,
          title: t.view_mnemonic,
          subtitle: t.view_passphrase,
        ));
  }

  // deprecated: 확장 공개키 보기
  // void _showModalBottomSheetWithQrImage(
  //     String appBarTitle, String data, Widget? qrcodeTopWidget) {
  //   MyBottomSheet.showBottomSheet_90(
  //       context: context,
  //       child: QrcodeBottomSheet(
  //           qrData: data,
  //           title: appBarTitle,
  //           qrcodeTopWidget: qrcodeTopWidget));
  // }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 65,
          child: Divider(
            thickness: 1, // 선의 두께
            color: MyColors.borderLightgrey,
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context) {
    return Visibility(
      visible: _tooltipRemainingTime > 0,
      child: Positioned(
        top: _tooltipIconPosition.dy - _tooltipTopPadding,
        right: MediaQuery.sizeOf(context).width - _tooltipIconPosition.dx - 48,
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
    );
  }

  void _showTooltip(BuildContext context) {
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

  void _removeTooltip() {
    setState(() {
      _tooltipRemainingTime = 0;
    });
    _tooltipTimer?.cancel();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }
}
