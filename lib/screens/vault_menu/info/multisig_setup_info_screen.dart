import 'dart:async';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/multisig_setup_info_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_signer_memo_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
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
  State<MultisigSetupInfoScreen> createState() => _MultisigSetupInfoScreenState();
}

class _MultisigSetupInfoScreenState extends State<MultisigSetupInfoScreen> {
  final GlobalKey _tooltipIconKey = GlobalKey();
  RenderBox? _tooltipIconRenderBox;
  Offset _tooltipIconPosition = Offset.zero;
  double _tooltipTopPadding = 0;

  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipIconRenderBox = _tooltipIconKey.currentContext?.findRenderObject() as RenderBox;
      _tooltipIconPosition = _tooltipIconRenderBox!.localToGlobal(Offset.zero);

      _tooltipTopPadding = MediaQuery.paddingOf(context).top + kToolbarHeight - 14;
    });
  }

  Future _verifyBiometric(
    BuildContext context,
  ) async {
    final viewModel = context.read<MultisigSetupInfoViewModel>();
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          onComplete: () async {
            Navigator.pop(context);
            viewModel.deleteVault();
            vibrateLight();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MultisigSetupInfoViewModel(
          Provider.of<WalletProvider>(context, listen: false), widget.id),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          _removeTooltip();
        },
        child: Consumer<MultisigSetupInfoViewModel>(builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: MyColors.white,
            appBar: CustomAppBar.build(
              title: '${viewModel.name} ${t.info}',
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
                        _buildVaultItemCard(context),
                        _buildSignerList(context),
                        // 지갑설정 정보보기, 삭제하기
                        const SizedBox(height: 14),
                        _buildBsmsInfoActions(context),
                        _buildDivider(),
                        _buildDeleteButton(context),
                      ],
                    ),
                    _buildTooltip(context),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVaultItemCard(BuildContext context) {
    final viewModel = context.watch<MultisigSetupInfoViewModel>();
    return VaultItemCard(
      vaultItem: viewModel.vaultItem,
      onTooltipClicked: () => _showTooltip(context),
      onNameChangeClicked: () {
        _removeTooltip();
        _showNameAndIconEditBottomSheet(viewModel);
      },
      tooltipKey: _tooltipIconKey,
    );
  }

  void _showNameAndIconEditBottomSheet(MultisigSetupInfoViewModel viewModel) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: NameAndIconEditBottomSheet(
        name: viewModel.name,
        iconIndex: viewModel.iconIndex,
        colorIndex: viewModel.colorIndex,
        onUpdate: (String newName, int newIconIndex, int newColorIndex) {
          _updateVaultInfo(newName, newColorIndex, newIconIndex, viewModel);
        },
      ),
    );
  }

  void _updateVaultInfo(String newName, int newColorIndex, int newIconIndex,
      MultisigSetupInfoViewModel viewModel) async {
    if (newName == viewModel.name &&
        newIconIndex == viewModel.iconIndex &&
        newColorIndex == viewModel.colorIndex) {
      return;
    }

    final hasChanged = await viewModel.updateVault(widget.id, newName, newColorIndex, newIconIndex);

    if (mounted) {
      if (hasChanged) {
        CustomToast.showToast(context: context, text: t.toast.data_updated);
        return;
      }
      CustomToast.showToast(context: context, text: t.toast.name_already_used);
    }
  }

  Widget _buildSignerList(BuildContext context) {
    final viewModel = context.watch<MultisigSetupInfoViewModel>();
    final signers = viewModel.signers;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: signers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final signer = viewModel.getSignerInfo(index);
        final isVaultInside = signer.innerVaultId != null;
        return GestureDetector(
            onTap: () {
              _removeTooltip();
              if (isVaultInside) {
                Navigator.pushNamed(context, AppRoutes.singleSigSetupInfo, arguments: {
                  'id': signer.innerVaultId,
                });
              } else {
                _showMemoEditBottomSheet(signer, index, viewModel);
              }
            },
            child: _buildSignerCard(signer, index));
      },
    );
  }

  void _showMemoEditBottomSheet(
      MultisigSigner signer, int index, MultisigSetupInfoViewModel viewModel) {
    final selectedMemo = signer.memo ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultisigSignerMemoBottomSheet(
        memo: selectedMemo,
        autofocus: true,
        onUpdate: (memo) async {
          if (selectedMemo == memo) return;
          final navigator = Navigator.of(context);
          await viewModel.updateOutsideVaultMemo(index, memo);
          if (mounted) {
            navigator.pop();
          }
        },
      ),
    );
  }

  Widget _buildSignerCard(MultisigSigner signer, int index) {
    final isVaultInside = signer.innerVaultId != null;
    return Container(
      color: Colors.transparent,
      child: Row(
        children: [
          _buildIndex(index + 1),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MyColors.white,
                borderRadius: MyBorder.defaultRadius,
                border: Border.all(color: MyColors.greyE9),
              ),
              child: Row(
                children: [
                  _buildSignerIcon(
                      colorIndex: isVaultInside ? signer.colorIndex! : -1,
                      iconPath: isVaultInside
                          ? CustomIcons.getPathByIndex(signer.iconIndex!)
                          : 'assets/svg/download.svg'),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSignerNameAndMemo(name: signer.name, memo: signer.memo)),
                  // mfp
                  Text(
                    signer.keyStore.masterFingerprint,
                    style: Styles.mfpH3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndex(int index) {
    return SizedBox(
        width: 24,
        child: Text(
          '$index',
          textAlign: TextAlign.center,
          style: Styles.body2.merge(
            TextStyle(fontSize: 16, fontFamily: CustomFonts.number.getFontFamily),
          ),
        ));
  }

  Widget _buildSignerIcon({int colorIndex = -1, String iconPath = 'assets/svg/download.svg'}) {
    final Color backgroundColor =
        colorIndex == -1 ? MyColors.greyEC : BackgroundColorPalette[colorIndex];
    final Color iconColor = colorIndex == -1 ? MyColors.black : ColorPalette[colorIndex];
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: SvgPicture.asset(iconPath,
            colorFilter: ColorFilter.mode(
              iconColor,
              BlendMode.srcIn,
            ),
            width: 20));
  }

  Widget _buildSignerNameAndMemo({String? name, String? memo}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이름
        Text(
          name ?? '',
          style: Styles.body2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Visibility(
          visible: memo != null && memo.isNotEmpty,
          child: Text(
            memo ?? '',
            style: Styles.caption2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBsmsInfoActions(BuildContext context) {
    return Padding(
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

                  Navigator.pushNamed(context, AppRoutes.multisigBsmsView, arguments: {
                    'id': widget.id,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final name = context.read<MultisigSetupInfoViewModel>().name;
    return Padding(
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
              label: t.delete_label,
              showIcon: true,
              rightIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: MyColors.transparentWhite_70, borderRadius: BorderRadius.circular(10)),
                  child: SvgPicture.asset('assets/svg/trash.svg',
                      width: 16,
                      colorFilter: const ColorFilter.mode(MyColors.warningText, BlendMode.srcIn))),
              onPressed: () {
                _removeTooltip();
                showConfirmDialog(
                  context: context,
                  title: t.confirm,
                  content: t.alert.confirm_deletion(name: name),
                  onConfirmPressed: () async {
                    context.loaderOverlay.show();
                    await Future.delayed(const Duration(seconds: 1));
                    if (context.mounted) {
                      _verifyBiometric(context);
                      context.loaderOverlay.hide();
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
    final totalSingerCount = context.read<MultisigSetupInfoViewModel>().signers.length;
    final requiredSignatureCount =
        context.read<MultisigSetupInfoViewModel>().requiredSignatureCount;
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
                    t.multi_sig_setting_screen
                        .tooltip(total: totalSingerCount, count: requiredSignatureCount),
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
