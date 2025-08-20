import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/widgets/animation/shake_widget.dart';
import 'package:coconut_vault/widgets/icon/vault_item_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/home/vault_menu_bottom_sheet.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../utils/text_utils.dart';

class VaultRowItem extends StatefulWidget {
  const VaultRowItem({
    super.key,
    required this.vault,
    this.isSelectable = false,
    this.onSelected,
    this.isPressed = false,
    this.isStarVisible = false,
    this.isFavorite = false,
    this.isPrimaryWallet = false,
  });

  final VaultListItemBase vault;
  final bool isSelectable;
  final VoidCallback? onSelected;
  final bool isPressed;
  final bool isStarVisible;
  final bool isFavorite;
  final bool isPrimaryWallet;

  @override
  State<VaultRowItem> createState() => _VaultRowItemState();
}

class _VaultRowItemState extends State<VaultRowItem> {
  bool isPressing = false;

  bool _isMultiSig = false;
  String _subtitleText = '';
  bool _isUsedToMultiSig = false;
  List<MultisigSigner>? _multiSigners;
  bool hasPassphrase = false;

  Future<void> checkPassphraseStatus() async {
    hasPassphrase = await context.read<WalletProvider>().hasPassphrase(widget.vault.id);
  }

  @override
  void initState() {
    super.initState();
    checkPassphraseStatus();
  }

  void _updateVault() {
    _isMultiSig = false;
    _subtitleText = '';
    _isUsedToMultiSig = false;
    _multiSigners = null;

    if (widget.vault.vaultType == WalletType.multiSignature) {
      _isMultiSig = true;
      final multi = widget.vault as MultisigVaultListItem;
      _subtitleText = '${multi.requiredSignatureCount}/${multi.signers.length}';
      _multiSigners = multi.signers;
    } else {
      final single = widget.vault as SingleSigVaultListItem;
      if (single.linkedMultisigInfo != null) {
        final multisigKey = single.linkedMultisigInfo!;
        if (multisigKey.keys.isNotEmpty) {
          final model = Provider.of<WalletProvider>(context, listen: false);
          try {
            final multisig = model.getVaultById(multisigKey.keys.first);
            _subtitleText = t.wallet_subtitle(
                name: TextUtils.ellipsisIfLonger(multisig.name),
                index: multisigKey.values.first + 1);
            _isUsedToMultiSig = true;
          } catch (_) {}
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateVault();

    return widget.isSelectable
        ? ShakeWidget(
            key: ValueKey('${widget.vault.name}_$_subtitleText'), // _subTitle 이 바뀌면 Shake 재시작
            curve: Curves.easeInOut,
            deltaX: 5,
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 100),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPressing = false;
                      });
                      if (widget.onSelected != null) {
                        widget.onSelected!();
                      }
                    },
                    onTapDown: (details) {
                      setState(() {
                        isPressing = true;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        isPressing = false;
                      });
                    },
                    child: _buildVaultSelectableWidget(),
                  ),
                ),
                const SizedBox(
                  height: 10,
                )
              ],
            ),
          )
        : ShrinkAnimationButton(
            pressedColor: CoconutColors.gray150,
            borderGradientColors: null,
            borderRadius: 8,
            onPressed: () {
              // MyBottomSheet.showBottomSheet(
              //   context: context,
              //   title: TextUtils.ellipsisIfLonger(widget.vault.name), // overflow
              //   child: VaultMenuBottomSheet(id: widget.vault.id, isMultiSig: _isMultiSig),
              // );
              Navigator.pushNamed(
                  context, _isMultiSig ? AppRoutes.multisigSetupInfo : AppRoutes.singleSigSetupInfo,
                  arguments: {'id': widget.vault.id});
            },
            child: _buildVaultContainerWidget(),
          );
  }

  Widget _buildVaultContainerWidget({
    bool isEditMode = false,
    ValueChanged<(bool, int)>? onTapStar,
    int? index,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isEditMode ? 8 : 20, vertical: 12),
      child: Row(
        children: [
          if (isEditMode)
            Opacity(
              opacity: widget.isStarVisible ? 1 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (!widget.isStarVisible) return;
                  onTapStar?.call((!widget.isFavorite, widget.vault.id));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    'assets/svg/${widget.isFavorite ? 'star-filled' : 'star-outlined'}.svg',
                  ),
                ),
              ),
            ),
          VaultItemIcon(
            iconIndex: widget.vault.iconIndex,
            colorIndex: widget.vault.colorIndex,
            gradientColors: _isMultiSig && _multiSigners != null
                ? CustomColorHelper.getGradientColors(_multiSigners!)
                : null,
          ),
          CoconutLayout.spacing_200w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isMultiSig || _isUsedToMultiSig) ...{
                        Text(
                          _subtitleText,
                          style: CoconutTypography.body3_12.copyWith(color: CoconutColors.gray600),
                        ),
                      },
                      Text(
                        widget.vault.name,
                        style: CoconutTypography.body2_14_Bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (widget.isPrimaryWallet == true)
                      Text(
                        ' • ${t.vault_list_screen.primary_wallet}',
                        style: CoconutTypography.body3_12.setColor(CoconutColors.gray500),
                      ),
                  ],
                ),
              ],
            ),
          ),
          CoconutLayout.spacing_200w,
          isEditMode
              ? ReorderableDragStartListener(
                  index: index!,
                  child: GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SvgPicture.asset(
                        'assets/svg/hamburger.svg',
                      ),
                    ),
                  ),
                )
              : SvgPicture.asset(
                  'assets/svg/chevron-right.svg',
                  width: 6,
                  height: 10,
                )
        ],
      ),
    );
  }

  Widget _buildVaultSelectableWidget() {
    return Container(
      decoration: BoxDecoration(
          color: CoconutColors.white,
          borderRadius: BorderRadius.circular(28),
          border: widget.isPressed
              ? Border.all(color: CoconutColors.black.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: CoconutColors.black.withOpacity(0.15),
              offset: const Offset(0, 0),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ]),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      child: Row(
        children: [
          // 1) 아이콘
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CoconutColors.backgroundColorPaletteLight[widget.vault.colorIndex],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: SvgPicture.asset(CustomIcons.getPathByIndex(widget.vault.iconIndex),
                  colorFilter: ColorFilter.mode(
                      CoconutColors.colorPalette[widget.vault.colorIndex], BlendMode.srcIn),
                  width: 20.0)),
          const SizedBox(width: 8.0),
          // 2) 이름
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isMultiSig || _isUsedToMultiSig) ...{
                  Text(
                    _subtitleText,
                    style: CoconutTypography.body2_14.copyWith(color: CoconutColors.gray600),
                  ),
                },
                Text(
                  widget.vault.name,
                  style: CoconutTypography.body2_14_Bold.copyWith(letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          if (widget.isSelectable)
            AnimatedScale(
              scale: widget.isSelectable && widget.isPressed ? 1.0 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.check,
                size: 32,
                color: CoconutColors.black.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
}
