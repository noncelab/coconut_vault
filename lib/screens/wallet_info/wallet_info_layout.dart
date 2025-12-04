import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/icon_path.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/wallet_info_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/select_external_wallet_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/multisig_menu/multisig_add_key_option_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/multisig_menu/multisig_signer_memo_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/icon/vault_icon.dart';
import 'package:coconut_vault/widgets/wallet_info/wallet_info_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class WalletInfoLayout extends StatefulWidget {
  final int id;
  final List<SingleButtonData> menuButtonDatas;

  final String? entryPoint;
  final bool isMultisig;

  // 서명 전용 모드에서는 항상 false입니다.
  final bool? shouldShowPassphraseVerifyMenu;

  const WalletInfoLayout({
    super.key,
    required this.id,
    required this.menuButtonDatas,
    this.entryPoint,
    this.isMultisig = false,
    this.shouldShowPassphraseVerifyMenu, // only SingleSig
  });

  @override
  State<WalletInfoLayout> createState() => _WalletInfoLayoutState();
}

class _WalletInfoLayoutState extends State<WalletInfoLayout> {
  final GlobalKey _tooltipIconKey = GlobalKey();
  RenderBox? _tooltipIconRendBox;
  Offset _tooltipIconPosition = Offset.zero;
  double _tooltipTopPadding = 0;

  Timer? _tooltipTimer;
  bool _isTooltipVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<WalletInfoViewModel>().isMultisig) {
        final ctx = _tooltipIconKey.currentContext;
        if (ctx == null) return;

        final renderObject = ctx.findRenderObject();
        if (renderObject is! RenderBox) return;

        _tooltipIconRendBox = renderObject;
        _tooltipIconPosition = _tooltipIconRendBox!.localToGlobal(Offset.zero);
        _tooltipTopPadding = MediaQuery.paddingOf(context).top + kToolbarHeight - 14;
      }
    });
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _onTooltipClicked() {
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

  void _onNameChangeClicked() {
    _removeTooltip();
    final viewModel = context.read<WalletInfoViewModel>();
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: NameAndIconEditBottomSheet(
        name: viewModel.name,
        iconIndex: viewModel.iconIndex,
        colorIndex: viewModel.colorIndex,
        onUpdate: (String newName, int newIconIndex, int newColorIndex) {
          _updateVaultInfo(newName, newColorIndex, newIconIndex);
        },
      ),
    );
  }

  void _updateVaultInfo(String newName, int newColorIndex, int newIconIndex) async {
    final viewModel = context.read<WalletInfoViewModel>();
    if (newName == viewModel.name && newIconIndex == viewModel.iconIndex && newColorIndex == viewModel.colorIndex) {
      return;
    }

    final hasChanged = await viewModel.updateVault(widget.id, newName, newColorIndex, newIconIndex);

    if (mounted) {
      if (hasChanged) {
        CoconutToast.showToast(context: context, text: t.toast.data_updated, isVisibleIcon: true);
        return;
      }
      CoconutToast.showToast(context: context, text: t.toast.name_already_used, isVisibleIcon: true);
    }
  }

  Future<void> _authenticateWithBiometricOrPin(
    BuildContext context,
    PinCheckContextEnum pinCheckContext,
    VoidCallback onSuccess,
  ) async {
    final authProvider = context.read<AuthProvider>();

    final isBiometricValid =
        pinCheckContext == PinCheckContextEnum.sensitiveAction
            ? await authProvider.isBiometricsAuthValidToAvoidDoubleAuth()
            : await authProvider.isBiometricsAuthValid();

    if (isBiometricValid && context.mounted) {
      onSuccess();
      return;
    }

    if (!context.mounted) return;
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
            if (widget.isMultisig) {
              if (context.mounted) {
                if (!context.read<WalletInfoViewModel>().isSigningOnlyMode) {
                  // 안전 저장 모드
                  _authenticateAndDelete();
                } else {
                  // 서명 전용 모드
                  onAuthenticationComplete();
                }
                return;
              }
            }

            if (!mounted) return;
            final viewModel = context.read<WalletInfoViewModel>();
            if (!viewModel.isSigningOnlyMode) {
              await _authenticateWithBiometricOrPin(
                context,
                PinCheckContextEnum.seedDeletion,
                () => _deleteVault(context),
              );
            } else {
              _deleteVault(context);
            }
          },
        );
      },
    );

    return;
  }

  Future<void> _deleteVault(BuildContext context) async {
    if (!mounted) return;
    final viewModel = context.read<WalletInfoViewModel>();
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

  void _showMemoEditBottomSheet(MultisigSigner signer, int index) {
    final viewModel = context.read<WalletInfoViewModel>();
    final selectedMemo = signer.memo ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MultisigSignerNameBottomSheet(
            memo: selectedMemo,
            onUpdate: (newMemo) async {
              final navigator = Navigator.of(context);
              if (newMemo.trim() != selectedMemo.trim()) {
                await viewModel.updateOutsideVaultMemo(index, newMemo.trim());
              }
              if (mounted) {
                navigator.pop();
              }
            },
          ),
    );
  }

  void _showAddIconBottomSheet(String? iconSource, int index) async {
    final viewModel = context.read<WalletInfoViewModel>();
    final iconSourceList = [
      kCoconutVaultIconPath,
      kKeystoneIconPath,
      kSeedSignerIconPath,
      kJadeIconPath,
      kColdCardIconPath,
      kKruxIconPath,
    ];
    final externalWalletButtonList = [
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.coconut_vault, iconSource: iconSourceList[0]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.keystone3pro, iconSource: iconSourceList[1]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.seed_signer, iconSource: iconSourceList[2]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.jade, iconSource: iconSourceList[3]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.cold_card, iconSource: iconSourceList[4]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.krux, iconSource: iconSourceList[5]),
    ];
    final selectedIndex = iconSource != null ? iconSourceList.indexOf(iconSource) : null;
    HardwareWalletType? result;
    await MyBottomSheet.showDraggableBottomSheet<HardwareWalletType?>(
      context: context,
      showDragHandle: false,
      maxChildSize: 0.45,
      minChildSize: 0.2,
      initialChildSize: 0.45,
      childBuilder:
          (context) => SelectExternalWalletBottomSheet(
            title: t.multi_sig_setting_screen.add_icon.title,
            externalWalletButtonList: externalWalletButtonList,
            selectedIndex: selectedIndex,
            onSelected: (selectedIndex) {
              result = _getSignerSourceByIconSource(externalWalletButtonList, selectedIndex);

              if (result == null) {
                return;
              }
              viewModel.updateSignerSource(index, result!);
            },
          ),
    );
  }

  HardwareWalletType? _getSignerSourceByIconSource(
    List<ExternalWalletButton> externalWalletButtonList,
    int selectedIndex,
  ) {
    if (selectedIndex >= externalWalletButtonList.length) {
      return null;
    }

    final selectedButton = externalWalletButtonList[selectedIndex];
    final iconSource = selectedButton.iconSource;

    switch (iconSource) {
      case kCoconutVaultIconPath:
        return HardwareWalletType.coconutVault;
      case kKeystoneIconPath:
        return HardwareWalletType.keystone3Pro;
      case kSeedSignerIconPath:
        return HardwareWalletType.seedSigner;
      case kJadeIconPath:
        return HardwareWalletType.jade;
      case kColdCardIconPath:
        return HardwareWalletType.coldcard;
      case kKruxIconPath:
        return HardwareWalletType.krux;
      default:
        return null;
    }
  }

  Future<void> _authenticateAndDelete() async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValid() && context.mounted) {
      onAuthenticationComplete();
      return;
    }

    if (!mounted) return;
    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.seedDeletion,
          onSuccess: () async {
            Navigator.pop(context);
            onAuthenticationComplete();
          },
        ),
      ),
    );
  }

  void onAuthenticationComplete() {
    context.read<WalletInfoViewModel>().deleteVault();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _removeTooltip();
      },
      child: CustomLoadingOverlay(
        child: Consumer<WalletInfoViewModel>(
          builder: (context, viewModel, child) {
            if (!viewModel.isInitialized) {
              return const Scaffold(
                backgroundColor: CoconutColors.white,
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final canDelete = viewModel.isMultisig ? true : viewModel.hasLinkedMultisigVault != true;
            final walletName = viewModel.name;
            final isMultisig = viewModel.isMultisig;
            return Scaffold(
              backgroundColor: CoconutColors.white,
              appBar: CoconutAppBar.build(
                title: walletName,
                context: context,
                isBottom: false,
                actionButtonList: [
                  IconButton(
                    onPressed: () {
                      _removeTooltip();
                      if (!canDelete) {
                        CoconutToast.showToast(
                          context: context,
                          text: t.toast.name_multisig_in_use,
                          isVisibleIcon: true,
                        );
                        return;
                      }
                      _showDeleteDialog(context, walletName);
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
                          WalletInfoItemCard(
                            tooltipKey: _tooltipIconKey,
                            onTooltipClicked: _onTooltipClicked,
                            onNameChangeClicked: _onNameChangeClicked,
                            vaultItem: viewModel.vaultItem,
                          ),
                          if (viewModel.linkedMultisigInfo != null && viewModel.linkedMultisigInfo!.isNotEmpty) ...[
                            CoconutLayout.spacing_300h,
                            _buildLinkedMultisigInfo(),
                          ],
                          if (isMultisig) _buildSignerList(),
                          CoconutLayout.spacing_500h,
                          _buildMenuList(widget.menuButtonDatas),
                          CoconutLayout.spacing_1500h,
                        ],
                      ),
                      if (!viewModel.isMultisig) ...[
                        /// 25.09.04 변경으로 멀티시그 지갑 상세화면에는 툴팁 없음
                        _buildTooltip(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTooltip() {
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

  Widget _buildLinkedMultisigInfo() {
    final viewModel = context.read<WalletInfoViewModel>();
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
            ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignerList() {
    final viewModel = context.read<WalletInfoViewModel>();
    final signers = viewModel.signers;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      itemCount: signers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final signer = viewModel.getSignerInfo(index);
        final isVaultInside = signer.innerVaultId != null;
        return GestureDetector(
          onTap: () async {
            _removeTooltip();
            if (isVaultInside && signer.innerVaultId != null) {
              final walletProvider = context.read<WalletProvider>();
              bool shouldShowPassphraseVerifyMenu =
                  walletProvider.isSigningOnlyMode ? false : await walletProvider.hasPassphrase(signer.innerVaultId!);
              if (context.mounted) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.singleSigSetupInfo,
                  arguments: {
                    'id': signer.innerVaultId,
                    'shouldShowPassphraseVerifyMenu': shouldShowPassphraseVerifyMenu,
                  },
                );
              }
            } else {
              _showMemoEditBottomSheet(signer, index);
            }
          },
          child: _buildSignerCard(signer, index),
        );
      },
    );
  }

  Widget _buildSignerCard(MultisigSigner signer, int index) {
    final isVaultInside = signer.innerVaultId != null;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('${index + 1}', textAlign: TextAlign.center, style: CoconutTypography.body1_16_Number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CoconutColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CoconutColors.gray200),
                ),
                child: Row(
                  children: [
                    VaultIcon(
                      iconIndex: isVaultInside ? signer.iconIndex! : null,
                      colorIndex: isVaultInside ? signer.colorIndex! : null,
                      customIconSource: isVaultInside ? null : signer.signerSource!.iconPath,
                      size: 20,
                      onPressed:
                          isVaultInside
                              ? null
                              : () {
                                _showAddIconBottomSheet(signer.signerSource!.iconPath, index);
                              },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          isVaultInside
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSignerName(name: signer.name),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _buildMfpAndDerivationPath(
                                      signer.keyStore.masterFingerprint,
                                      signer.getSignerDerivationPath(),
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildMfpAndDerivationPath(
                                      signer.keyStore.masterFingerprint,
                                      signer.getSignerDerivationPath(),
                                      memo: signer.memo,
                                      isLeftAlign: true,
                                    ),
                                  ),
                                  _buildAddKeyButton(signer),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignerName({String? name}) {
    return Text(name ?? '', style: CoconutTypography.body2_14, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _buildMfpAndDerivationPath(String mfp, String derivationPath, {String? memo, bool isLeftAlign = false}) {
    return Column(
      crossAxisAlignment: isLeftAlign ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(mfp, style: CoconutTypography.body2_14_Number),
        memo != null && memo.isNotEmpty
            ? Row(
              mainAxisAlignment: isLeftAlign ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Text('$derivationPath • ', style: CoconutTypography.body3_12.setColor(CoconutColors.gray600)),
                Expanded(
                  child: Text(
                    memo,
                    style: CoconutTypography.body3_12.setColor(CoconutColors.gray600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isLeftAlign ? TextAlign.left : TextAlign.right,
                  ),
                ),
              ],
            )
            : Text(
              derivationPath,
              style: CoconutTypography.body3_12.setColor(CoconutColors.gray600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }

  Widget _buildAddKeyButton(MultisigSigner signer) {
    return ShrinkAnimationButton(
      borderWidth: 1.4,
      borderGradientColors: const [CoconutColors.gray350, CoconutColors.gray350],
      borderRadius: 8,
      onPressed: () async {
        final result = await MyBottomSheet.showDraggableBottomSheet<AddKeyArgs?>(
          context: context,
          showDragHandle: false,
          maxChildSize: 0.45,
          minChildSize: 0.2,
          initialChildSize: 0.45,
          childBuilder:
              (context) => MultisigAddKeyOptionBottomSheet(signer: signer, multisigVaultIdOfExternalSigner: widget.id),
        );

        if (result != null) {
          if (!mounted) return;
          Navigator.pushNamed(
            context,
            result.nextRoute,
            arguments: {
              'externalSigner': result.externalSigner,
              'multisigVaultIdOfExternalSigner': result.multisigVaultIdOfExternalSigner,
            },
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          t.multi_sig_setting_screen.add_key,
          style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.black),
        ),
      ),
    );
  }

  Widget _buildMenuList(List<SingleButtonData> singleButtonDatas) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ButtonGroup(
        buttons: List.generate(
          singleButtonDatas.length,
          (index) => SingleButton(
            enableShrinkAnim: singleButtonDatas[index].enableShrinkAnim,
            title: singleButtonDatas[index].title,
            onPressed: () {
              _removeTooltip();
              singleButtonDatas[index].onPressed.call();
            },
          ),
        ),
      ),
    );
  }
}

class SingleButtonData {
  final String title;
  final VoidCallback onPressed;
  final bool enableShrinkAnim;

  SingleButtonData({required this.title, required this.onPressed, required this.enableShrinkAnim});
}

class AddKeyArgs {
  final MultisigSigner externalSigner;
  final int? multisigVaultIdOfExternalSigner;
  final String nextRoute;

  const AddKeyArgs({required this.externalSigner, this.multisigVaultIdOfExternalSigner, required this.nextRoute});
}
