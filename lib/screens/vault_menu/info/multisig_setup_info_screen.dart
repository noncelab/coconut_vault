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
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_add_icon_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_add_key_option_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/multisig_signer_memo_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/name_and_icon_edit_bottom_sheet.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/icon/vault_icon.dart';
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
  final Offset _tooltipIconPosition = Offset.zero;
  final double _tooltipTopPadding = 0;
  late final MultisigSetupInfoViewModel _viewModel;
  late final WalletProvider _walletProvider;

  Timer? _tooltipTimer;
  final int _tooltipRemainingTime = 0;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _viewModel = MultisigSetupInfoViewModel(_walletProvider, widget.id);
    // vaultList 변경 시 signer 정보 갱신
    _walletProvider.vaultListNotifier.addListener(_onVaultListChanged);
  }

  void _onVaultListChanged() {
    if (mounted) {
      _viewModel.refreshVaultItem(widget.id);
    }
  }

  void onComplete() {
    _viewModel.deleteVault();
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

  Future<void> _authenticateAndDelete() async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValid() && context.mounted) {
      onComplete();
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
            onComplete();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          _removeTooltip();
        },
        child: Consumer<MultisigSetupInfoViewModel>(
          builder: (context, viewModel, child) {
            if (!viewModel.isInitialized) {
              return const Scaffold(
                backgroundColor: CoconutColors.white,
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final walletName = viewModel.name;
            return GestureDetector(
              onTapDown: (details) => _removeTooltip(),
              child: Scaffold(
                backgroundColor: CoconutColors.white,
                appBar: CoconutAppBar.build(
                  title: walletName,
                  context: context,
                  isBottom: false,
                  onBackPressed: () {
                    Navigator.pop(context);
                  },
                  actionButtonList: [
                    IconButton(
                      onPressed: () {
                        _removeTooltip();
                        _showDeleteDialog(context, walletName);
                      },
                      icon: SvgPicture.asset(
                        'assets/svg/trash.svg',
                        width: 20,
                        colorFilter: const ColorFilter.mode(CoconutColors.red, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  child: SafeArea(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            CoconutLayout.spacing_500h,
                            _buildVaultItemCard(context, viewModel),
                            _buildSignerList(context, viewModel),
                            CoconutLayout.spacing_500h,
                            _buildSignMenu(),
                            CoconutLayout.spacing_500h,
                            _buildMenuList(context),
                            CoconutLayout.spacing_500h,
                            _buildExportWalletMenu(),
                            CoconutLayout.spacing_1500h,
                          ],
                        ),
                        _buildTooltip(context, viewModel),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVaultItemCard(BuildContext context, MultisigSetupInfoViewModel viewModel) {
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

  void _updateVaultInfo(
    String newName,
    int newColorIndex,
    int newIconIndex,
    MultisigSetupInfoViewModel viewModel,
  ) async {
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

  Widget _buildSignerList(BuildContext context, MultisigSetupInfoViewModel viewModel) {
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
              _showNameEditBottomSheet(signer, index, viewModel);
            }
          },
          child: _buildSignerCard(signer, index),
        );
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

  void _showNameEditBottomSheet(MultisigSigner signer, int index, MultisigSetupInfoViewModel viewModel) {
    final selectedName = signer.signerName ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MultisigSignerNameBottomSheet(
            name: selectedName,
            autofocus: true,
            onUpdate: (newName) async {
              final navigator = Navigator.of(context);
              if (newName.trim() != selectedName.trim()) {
                await viewModel.updateOutsideVaultName(index, newName.trim());
              }
              if (mounted) {
                navigator.pop();
              }
            },
          ),
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
            _buildIndex(index + 1),
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
                      customIconSource: isVaultInside ? null : signer.getSignerIconSource(),
                      size: 20,
                      onPressed:
                          isVaultInside
                              ? null
                              : () {
                                _showAddIconBottomSheet(signer.getSignerIconSource(), index);
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
                                      name: signer.getSignerName(),
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

  Widget _buildIndex(int index) {
    return SizedBox(
      width: 24,
      child: Text('$index', textAlign: TextAlign.center, style: CoconutTypography.body1_16_Number),
    );
  }

  Widget _buildSignerName({String? name}) {
    return Text(name ?? '', style: CoconutTypography.body2_14, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _buildMfpAndDerivationPath(String mfp, String derivationPath, {String? name, bool isLeftAlign = false}) {
    return Column(
      crossAxisAlignment: isLeftAlign ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(mfp, style: CoconutTypography.body2_14_Number),
        name != null
            ? Row(
              mainAxisAlignment: isLeftAlign ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Text('$derivationPath • ', style: CoconutTypography.body3_12.setColor(CoconutColors.gray600)),
                Expanded(
                  child: Text(
                    name,
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
        final result = await MyBottomSheet.showDraggableBottomSheet<SignerSource?>(
          context: context,
          showDragHandle: false,
          maxChildSize: 0.45,
          minChildSize: 0.2,
          initialChildSize: 0.45,
          childBuilder: (context) => MultisigAddKeyOptionBottomSheet(signer: signer),
        );
        if (result != null) {
          debugPrint('result: $result');
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
            enableShrinkAnim: true,
            title: t.multi_sig_setting_screen.view_bsms,
            onPressed: () {
              _removeTooltip();
              Navigator.pushNamed(context, AppRoutes.multisigBsmsView, arguments: {'id': widget.id});
            },
          ),
        ],
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
    MyBottomSheet.showBottomSheet_ratio(
      context: context,
      ratio: 0.5,
      child: SelectSyncOptionBottomSheet(
        onSyncOptionSelected: (format) {
          if (!context.mounted) return;
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.syncToWallet, arguments: {'id': walletId, 'syncOption': format});
        },
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, MultisigSetupInfoViewModel viewModel) {
    final totalSingerCount = viewModel.signers.length;
    final requiredSignatureCount = viewModel.requiredSignatureCount;
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
              padding: const EdgeInsets.only(top: 25, left: 10, right: 10, bottom: 10),
              color: CoconutColors.gray800,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$requiredSignatureCount/$totalSingerCount, ${t.multi_sig_setting_screen.tooltip(total: totalSingerCount, n: requiredSignatureCount)}',
                    style: CoconutTypography.body3_12.merge(const TextStyle(height: 1.3, color: CoconutColors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddIconBottomSheet(String? iconSource, int index) async {
    final result = await MyBottomSheet.showDraggableBottomSheet<SignerSource?>(
      context: context,
      showDragHandle: false,
      maxChildSize: 0.45,
      minChildSize: 0.2,
      initialChildSize: 0.45,
      childBuilder: (context) => MultisigAddIconBottomSheet(iconSource: iconSource),
    );
    if (result != null) {
      _viewModel.updateSignerSource(index, result);
    }
  }

  /// 25.09.04 변경으로 멀티시그 지갑 상세화면에는 툴팁 없음
  void _showTooltip(BuildContext context) {
    // if (_tooltipRemainingTime > 0) {
    //   // 툴팁이 이미 보여지고 있는 상태라면 툴팁 제거만 합니다.
    //   _removeTooltip();
    //   return;
    // }
    // _removeTooltip();

    // setState(() {
    //   _tooltipRemainingTime = 5;
    // });

    // _tooltipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   setState(() {
    //     if (_tooltipRemainingTime > 0) {
    //       _tooltipRemainingTime--;
    //     } else {
    //       _removeTooltip();
    //       timer.cancel();
    //     }
    //   });
    // });
  }

  /// 25.09.04 변경으로 멀티시그 지갑 상세화면에는 툴팁 없음
  void _removeTooltip() {
    // if (_tooltipRemainingTime == 0) return;
    // setState(() {
    //   _tooltipRemainingTime = 0;
    // });
    // _tooltipTimer?.cancel();
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
              if (!_viewModel.isSigningOnlyMode) {
                // 안전 저장 모드
                _authenticateAndDelete();
              } else {
                // 서명 전용 모드
                onComplete();
              }
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _walletProvider.vaultListNotifier.removeListener(_onVaultListChanged);
    _tooltipTimer?.cancel();
    _viewModel.dispose();
    super.dispose();
  }
}
