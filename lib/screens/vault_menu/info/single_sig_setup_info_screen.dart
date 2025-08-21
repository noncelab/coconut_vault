import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/single_sig_setup_info_view_model.dart';
import 'package:coconut_vault/screens/vault_menu/info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
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
  bool hasPassphrase = false;

  Future<void> checkPassphraseStatus() async {
    hasPassphrase = await context.read<WalletProvider>().hasPassphrase(widget.id);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    checkPassphraseStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipIconRendBox = _tooltipIconKey.currentContext?.findRenderObject() as RenderBox;
      _tooltipIconPosition = _tooltipIconRendBox!.localToGlobal(Offset.zero);
      _tooltipTopPadding = MediaQuery.paddingOf(context).top + kToolbarHeight - 14;
    });
  }

  Future<bool> _verifyBiometric(BuildContext context, PinCheckContextEnum pinCheckContext) async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValid()) {
      _verifySwitch(context, pinCheckContext);
      return true;
    }

    bool isSuccess = false;
    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: pinCheckContext,
          onSuccess: () async {
            Navigator.pop(context);
            _verifySwitch(context, pinCheckContext);
            isSuccess = true;
          },
        ),
      ),
    );

    return isSuccess;
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
              backgroundColor: CoconutColors.white,
              appBar: CoconutAppBar.build(
                title: '${viewModel.name} ${t.info}',
                context: context,
                // isBottom: viewModel.hasLinkedMultisigVault,
                isBottom: false,
              ),
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
        CoconutToast.showToast(
          context: context,
          text: t.toast.data_updated,
          isVisibleIcon: true,
        );
        return;
      }
      CoconutToast.showToast(
        context: context,
        text: t.toast.name_already_used,
        isVisibleIcon: true,
      );
    }
  }

  Widget _buildLinkedMultisigVaultInfoCard(BuildContext context) {
    const linearGradient = LinearGradient(
      colors: [
        Color(0xFFB2E774),
        Color(0xFF6373EB),
        Color(0xFF2ACEC3),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: CoconutColors.white,
        borderRadius: BorderRadius.circular(22),
        gradient: linearGradient,
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 14),
        decoration: BoxDecoration(
          color: CoconutColors.white,
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
                  style: CoconutTypography.body2_14,
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
                            style: CoconutTypography.body2_14.setColor(
                              const Color(0xFF4E83FF),
                            ),
                            children: [
                              TextSpan(
                                text: TextUtils.ellipsisIfLonger(multisig.name),
                                style: CoconutTypography.body2_14_Bold.setColor(
                                  const Color(0xFF4E83FF),
                                ),
                              ),
                              TextSpan(text: t.vault_settings.of),
                              TextSpan(
                                text: t.vault_settings.nth(index: idx + 1),
                                style: CoconutTypography.body2_14_Bold.setColor(
                                  const Color(0xFF4E83FF),
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
                        baseColor: CoconutColors.gray300,
                        highlightColor: CoconutColors.gray150,
                        child: Container(
                          height: 17,
                          width: double.maxFinite,
                          color: CoconutColors.gray300,
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
              color: CoconutColors.black.withOpacity(0.03),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  InformationItemCard(
                    label: t.vault_menu_screen.title.use_as_multisig_signer,
                    showIcon: true,
                    onPressed: () {
                      _removeTooltip();

                      Navigator.pushNamed(
                        context,
                        AppRoutes.multisigSignerBsmsExport,
                        arguments: {'id': widget.id},
                      );
                    },
                  ),
                  const Divider(color: CoconutColors.borderLightGray, height: 1),
                  InformationItemCard(
                    label: t.view_mnemonic,
                    showIcon: true,
                    onPressed: () {
                      _removeTooltip();
                      _verifyBiometric(context, PinCheckContextEnum.sensitiveAction);
                    },
                  ),
                  if (hasPassphrase) ...[
                    const Divider(color: CoconutColors.borderLightGray, height: 1),
                    InformationItemCard(
                      label: t.verify_passphrase,
                      showIcon: true,
                      onPressed: () {
                        _removeTooltip();
                        Navigator.of(context).pushNamed(AppRoutes.passphraseVerification,
                            arguments: {'id': widget.id});
                      },
                    ),
                  ],
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
              color: CoconutColors.black.withOpacity(0.03),
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
                            ? CoconutColors.gray850.withOpacity(0.15)
                            : null,
                        rightIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CoconutColors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/trash.svg',
                            width: 16,
                            colorFilter: ColorFilter.mode(
                              data.canDelete
                                  ? CoconutColors.warningText
                                  : CoconutColors.gray850.withOpacity(0.15),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        onPressed: () {
                          _removeTooltip();
                          if (data.canDelete) {
                            debugPrint('data.canDelete: ${data.canDelete}');
                            showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return CoconutPopup(
                                    insetPadding: EdgeInsets.symmetric(
                                        horizontal: MediaQuery.of(context).size.width * 0.15),
                                    title: t.confirm,
                                    titleTextStyle: CoconutTypography.body1_16_Bold,
                                    description: t.alert.confirm_deletion(name: data.walletName),
                                    descriptionTextStyle: CoconutTypography.body2_14,
                                    backgroundColor: CoconutColors.white,
                                    leftButtonText: t.no,
                                    leftButtonTextStyle: CoconutTypography.body2_14.merge(
                                      TextStyle(
                                        color: CoconutColors.black.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    rightButtonText: t.yes,
                                    rightButtonColor: CoconutColors.warningText,
                                    rightButtonTextStyle: CoconutTypography.body2_14.merge(
                                      const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onTapLeft: () => Navigator.pop(context),
                                    onTapRight: () async {
                                      context.loaderOverlay.show();
                                      if (context.mounted) {
                                        _verifyBiometric(context, PinCheckContextEnum.seedDeletion)
                                            .then((bool isSuccess) {
                                          if (!context.mounted) return;

                                          context.loaderOverlay.hide();
                                        });
                                      }
                                    },
                                  );
                                });

                            return;
                          }
                          CoconutToast.showToast(
                            context: context,
                            text: t.toast.name_multisig_in_use,
                            isVisibleIcon: true,
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

    Navigator.pushNamed(context, AppRoutes.mnemonicView, arguments: {'id': widget.id});
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
            color: CoconutColors.borderLightGray,
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
              color: CoconutColors.gray800,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.tooltip.mfp,
                    style: CoconutTypography.body3_12.merge(const TextStyle(
                      height: 1.3,
                      color: CoconutColors.white,
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
