import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/single_sig_setup_info_view_model.dart';
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../providers/wallet_provider.dart';

class SingleSigSetupInfoScreen extends StatefulWidget {
  final int id;
  final String? entryPoint;
  const SingleSigSetupInfoScreen({super.key, required this.id, this.entryPoint});

  @override
  State<SingleSigSetupInfoScreen> createState() => _SingleSigSetupInfoScreenState();
}

class _SingleSigSetupInfoScreenState extends State<SingleSigSetupInfoScreen> {
  final GlobalKey _tooltipIconKey = GlobalKey();
  RenderBox? _tooltipIconRendBox;
  Offset _tooltipIconPosition = Offset.zero;
  double _tooltipTopPadding = 0;

  Timer? _tooltipTimer;
  bool _isTooltipVisible = false;
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

  Future<void> _authenticateWithBiometricOrPin(
    BuildContext context,
    PinCheckContextEnum pinCheckContext,
    VoidCallback onSuccess,
  ) async {
    final authProvider = context.read<AuthProvider>();

    if (await authProvider.isBiometricsAuthValid() && context.mounted) {
      onSuccess();
      return;
    }

    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: pinCheckContext,
          onSuccess: () async {
            Navigator.pop(context);
            onSuccess();
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
          create: (context) =>
              SingleSigSetupInfoViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id),
          child: Consumer<SingleSigSetupInfoViewModel>(
            builder: (context, viewModel, child) {
              final canDelete = viewModel.hasLinkedMultisigVault != true;
              final walletName = viewModel.name;

              return GestureDetector(
                onTap: () => _removeTooltip(),
                child: Scaffold(
                  backgroundColor: CoconutColors.white,
                  appBar: CoconutAppBar.build(
                    title: walletName,
                    context: context,
                    // isBottom: viewModel.hasLinkedMultisigVault,
                    isBottom: false,
                    actionButtonList: [
                      IconButton(
                        onPressed: () {
                          _removeTooltip();
                          if (canDelete) {
                            _showDeleteDialog(context, walletName);
                            return;
                          }
                          CoconutToast.showToast(
                            context: context,
                            text: t.toast.name_multisig_in_use,
                            isVisibleIcon: true,
                          );
                        },
                        icon: SvgPicture.asset(
                          'assets/svg/trash.svg',
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            canDelete ? CoconutColors.red : CoconutColors.gray850.withValues(alpha: 0.15),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CoconutLayout.spacing_500h,
                              _buildVaultItemCard(context),
                              if (viewModel.hasLinkedMultisigVault == true) ...[
                                CoconutLayout.spacing_300h,
                                _buildLinkedMultisigVaultInfoCard(context),
                              ],
                              CoconutLayout.spacing_500h,
                              _buildSignMenu(),
                              CoconutLayout.spacing_500h,
                              _buildMenuList(context),
                              CoconutLayout.spacing_500h,
                              _buildExportWalletMenu(),
                              CoconutLayout.spacing_1500h,
                            ],
                          ),
                          _buildTooltip(context),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVaultItemCard(BuildContext context) {
    final viewModel = context.watch<SingleSigSetupInfoViewModel>();
    return VaultItemCard(
      vaultItem: viewModel.vaultItem,
      onTooltipClicked: () => _toggleTooltipVisible(context),
      onNameChangeClicked: () {
        _removeTooltip();
        _showModalBottomSheetForEditingNameAndIcon(viewModel);
      },
      tooltipKey: _tooltipIconKey,
    );
  }

  Widget _buildSignMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleButton(
        enableShrinkAnim: true,
        title: t.vault_menu_screen.title.single_sig_sign,
        onPressed: () {
          _removeTooltip();
          Navigator.pushNamed(context, AppRoutes.psbtScanner, arguments: {'id': widget.id});
        },
      ),
    );
  }

  Widget _buildExportWalletMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleButton(
        enableShrinkAnim: true,
        title: t.select_export_type_screen.title,
        onPressed: () {
          _showSyncOptionBottomSheet(widget.id, context);
        },
      ),
    );
  }

  void _showSyncOptionBottomSheet(int walletId, BuildContext context) {
    MyBottomSheet.showDraggableBottomSheet(
      context: context,
      minChildSize: 0.5,
      childBuilder: (scrollController) => SelectSyncOptionBottomSheet(
        onSyncOptionSelected: (format) {
          if (!context.mounted) return;
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.syncToWallet, arguments: {'id': walletId, 'syncOption': format});
        },
        scrollController: scrollController,
      ),
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
      ),
    );
  }

  void _updateVaultInfo(
    String newName,
    int newColorIndex,
    int newIconIndex,
    SingleSigSetupInfoViewModel viewModel,
  ) async {
    // 변경 사항이 없는 경우
    if (newName == viewModel.name && newIconIndex == viewModel.iconIndex && newColorIndex == viewModel.colorIndex) {
      return;
    }

    bool hasChanged = await viewModel.updateVault(widget.id, newName, newColorIndex, newIconIndex);

    if (mounted) {
      if (hasChanged) {
        CoconutToast.showToast(context: context, text: t.toast.data_updated, isVisibleIcon: true);
        return;
      }
      CoconutToast.showToast(context: context, text: t.toast.name_already_used, isVisibleIcon: true);
    }
  }

  Widget _buildLinkedMultisigVaultInfoCard(BuildContext context) {
    const linearGradient = LinearGradient(
      colors: [Color(0xFFB2E774), Color(0xFF6373EB), Color(0xFF2ACEC3)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        color: CoconutColors.white,
        borderRadius: BorderRadius.circular(12),
        gradient: linearGradient,
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 14),
        decoration: BoxDecoration(color: CoconutColors.white, borderRadius: BorderRadius.circular(11)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & used in multisig vault text
            Row(
              children: [
                SvgPicture.asset('assets/svg/vault-grey.svg', width: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(t.vault_settings.used_in_multisig, style: CoconutTypography.body2_14)),
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 4, bottom: 4, left: 28), child: Divider()),

            // Linked multisig vaults
            Consumer<SingleSigSetupInfoViewModel>(
              builder: (context, viewModel, child) {
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.linkedMutlsigVaultCount,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final id = viewModel.linkedMultisigInfo!.keys.elementAt(index);
                    final idx = viewModel.linkedMultisigInfo!.values.elementAt(index);

                    if (viewModel.isLoadedVaultList && viewModel.existsLinkedMultisigVault(id)) {
                      final multisig = viewModel.getVaultById(id);

                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.multisigSetupInfo, arguments: {'id': id});
                        },
                        child: Container(
                          padding: const EdgeInsets.only(left: 28, bottom: 4),
                          color: Colors.transparent,
                          child: RichText(
                            text: TextSpan(
                              style: CoconutTypography.body2_14.setColor(const Color(0xFF4E83FF)),
                              children: [
                                TextSpan(
                                  text: TextUtils.ellipsisIfLonger(multisig.name),
                                  style: CoconutTypography.body2_14_Bold.setColor(const Color(0xFF4E83FF)),
                                ),
                                TextSpan(text: t.vault_settings.of),
                                TextSpan(
                                  text: t.vault_settings.nth(index: idx + 1),
                                  style: CoconutTypography.body2_14_Bold.setColor(const Color(0xFF4E83FF)),
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
                          child: Container(height: 17, width: double.maxFinite, color: CoconutColors.gray300),
                        ),
                      );
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

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ButtonGroup(
        buttons: [
          SingleButton(
            title: t.view_address,
            enableShrinkAnim: true,
            onPressed: () {
              _removeTooltip();
              Navigator.pushNamed(
                context,
                AppRoutes.addressList,
                arguments: {'id': widget.id, 'isSpecificVault': true},
              );
            },
          ),
          SingleButton(
            title: t.view_mnemonic,
            enableShrinkAnim: true,
            onPressed: () {
              _removeTooltip();
              _authenticateWithBiometricOrPin(
                context,
                PinCheckContextEnum.sensitiveAction,
                () => Navigator.pushNamed(context, AppRoutes.mnemonicView, arguments: {'id': widget.id}),
              );
            },
          ),
          if (hasPassphrase) ...[
            SingleButton(
              enableShrinkAnim: true,
              title: t.verify_passphrase,
              onPressed: () {
                _removeTooltip();
                Navigator.of(context).pushNamed(AppRoutes.passphraseVerification, arguments: {'id': widget.id});
              },
            ),
          ],
          SingleButton(
            title: t.vault_menu_screen.title.use_as_multisig_signer,
            enableShrinkAnim: true,
            onPressed: () {
              _removeTooltip();
              Navigator.pushNamed(context, AppRoutes.multisigSignerBsmsExport, arguments: {'id': widget.id});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVault(BuildContext context) async {
    final viewModel = context.read<SingleSigSetupInfoViewModel>();
    viewModel.deleteVault();
    vibrateLight();
    if (widget.entryPoint != null && widget.entryPoint == AppRoutes.vaultList) {
      Navigator.popUntil(context, (route) {
        return route.settings.name == AppRoutes.vaultList;
      });
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
    return;
  }

  Widget _buildTooltip(BuildContext context) {
    return Visibility(
      visible: _isTooltipVisible,
      child: Positioned(
        top: _tooltipIconPosition.dy - _tooltipTopPadding,
        right: MediaQuery.sizeOf(context).width - _tooltipIconPosition.dx - 48,
        child: GestureDetector(
          onTap: () => _removeTooltip(),
          child: ClipPath(
            clipper: RightTriangleBubbleClipper(),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
              padding: const EdgeInsets.only(top: 25, left: 10, right: 10, bottom: 10),
              color: CoconutColors.gray800,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      t.tooltip.mfp,
                      style: CoconutTypography.body3_12.merge(const TextStyle(height: 1.3, color: CoconutColors.white)),
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

  void _toggleTooltipVisible(BuildContext context) {
    /// 이미 보여지고 있는 상태라면 툴팁 제거만 합니다.
    if (_isTooltipVisible) {
      _removeTooltip();
      return;
    }

    setState(() {
      _isTooltipVisible = true;
    });

    _tooltipTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _isTooltipVisible = false;
      });
    });
  }

  void _removeTooltip() {
    _tooltipTimer?.cancel();
    setState(() {
      _isTooltipVisible = false;
    });
  }

  void _showDeleteDialog(BuildContext context, String walletName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.delete_vault.title,
          description: t.alert.delete_vault.description,
          backgroundColor: CoconutColors.white,
          leftButtonText: t.no,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.yes,
          rightButtonColor: CoconutColors.warningText,
          onTapLeft: () => Navigator.pop(context),
          onTapRight: () async {
            if (context.mounted) {
              await _authenticateWithBiometricOrPin(
                context,
                PinCheckContextEnum.seedDeletion,
                () => _deleteVault(context),
              );
            }
          },
        );
      },
    );

    return;
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }
}
