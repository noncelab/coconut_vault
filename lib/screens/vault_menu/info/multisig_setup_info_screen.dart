import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/multisig_setup_info_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_signer_memo_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/single_sig_setup_info_screen.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/multi_button.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/card/information_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MultisigSetupInfoScreen extends StatefulWidget {
  final int id;
  final String? entryPoint;
  const MultisigSetupInfoScreen({super.key, required this.id, this.entryPoint});

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

  Future<void> _authenticateAndDelete(
    BuildContext context,
  ) async {
    void onComplete() {
      context.read<MultisigSetupInfoViewModel>().deleteVault();
      vibrateLight();
      if (widget.entryPoint != null && widget.entryPoint == kEntryPointVaultList) {
        Navigator.popUntil(context, (route) {
          return route.settings.name == AppRoutes.vaultList;
        });
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValid() && context.mounted) {
      onComplete();
      return;
    }

    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.seedDeletion,
          onSuccess: () async {
            Navigator.pop(context);
            onComplete();
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
          return GestureDetector(
            onTapDown: (details) => _removeTooltip(),
            child: Scaffold(
              backgroundColor: CoconutColors.white,
              appBar: CoconutAppBar.build(
                title: viewModel.name,
                context: context,
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
                          CoconutLayout.spacing_500h,
                          _buildSignMenu(),
                          CoconutLayout.spacing_500h,
                          _buildMenuList(context),
                          _buildDivider(),
                          _buildDeleteButton(context),
                          CoconutLayout.spacing_500h,
                        ],
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
        CoconutToast.showToast(context: context, text: t.toast.data_updated, isVisibleIcon: true);
        return;
      }
      CoconutToast.showToast(
          context: context, text: t.toast.name_already_used, isVisibleIcon: true);
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

  Widget _buildSignMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleButton(
        enableShrinkAnim: true,
        title: t.vault_menu_screen.title.multisig_sign,
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.psbtScanner, arguments: {'id': widget.id});
        },
      ),
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
                color: CoconutColors.white,
                borderRadius: CoconutBorder.defaultRadius,
                border: Border.all(color: CoconutColors.gray200),
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
                    style: CoconutTypography.body1_16_Number,
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
        style: CoconutTypography.body1_16_Number,
      ),
    );
  }

  Widget _buildSignerIcon({int colorIndex = -1, String iconPath = 'assets/svg/download.svg'}) {
    final Color backgroundColor = colorIndex == -1
        ? CoconutColors.gray200
        : CoconutColors.backgroundColorPaletteLight[colorIndex];
    final Color iconColor =
        colorIndex == -1 ? CoconutColors.black : CoconutColors.colorPalette[colorIndex];
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
          style: CoconutTypography.body2_14,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Visibility(
          visible: memo != null && memo.isNotEmpty,
          child: Text(
            memo ?? '',
            style: CoconutTypography.body3_12.merge(
              const TextStyle(
                color: CoconutColors.searchbarHint,
                fontSize: 10,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ButtonGroup(
        buttons: [
          SingleButton(
            enableShrinkAnim: true,
            title: t.multi_sig_setting_screen.view_bsms,
            onPressed: () {
              _removeTooltip();
              Navigator.pushNamed(context, AppRoutes.multisigBsmsView,
                  arguments: {'id': widget.id});
            },
          ),
          SingleButton(
            title: t.view_address,
            enableShrinkAnim: true,
            onPressed: () {
              _removeTooltip();
              Navigator.pushNamed(context, AppRoutes.addressList,
                  arguments: {'id': widget.id, 'isSpecificVault': true});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final name = context.read<MultisigSetupInfoViewModel>().name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleButton(
        title: t.delete_label,
        titleStyle: CoconutTypography.body2_14_Bold,
        enableShrinkAnim: true,
        rightElement: SvgPicture.asset(
          'assets/svg/trash.svg',
          width: 16,
          colorFilter: const ColorFilter.mode(
            CoconutColors.warningText,
            BlendMode.srcIn,
          ),
        ),
        onPressed: () {
          _removeTooltip();
          showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return CoconutPopup(
                  insetPadding:
                      EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
                  title: t.confirm,
                  titleTextStyle: CoconutTypography.body1_16_Bold,
                  description: t.alert.confirm_deletion(name: name),
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
                    if (context.mounted) {
                      _authenticateAndDelete(context);
                    }
                  },
                );
              });
        },
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
            color: CoconutColors.borderLightGray,
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
              color: CoconutColors.gray800,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$requiredSignatureCount/$totalSingerCount, ${t.multi_sig_setting_screen.tooltip(total: totalSingerCount, n: requiredSignatureCount)}',
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
    if (_tooltipRemainingTime > 0) {
      // 툴팁이 이미 보여지고 있는 상태라면 툴팁 제거만 합니다.
      _removeTooltip();
      return;
    }
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
    if (_tooltipRemainingTime == 0) return;
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
