import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_type.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/widgets/animation/shake_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/vault_detail/vault_menu_screen.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:provider/provider.dart';

import '../model/state/vault_model.dart';
import '../styles.dart';
import '../utils/text_utils.dart';

class VaultRowItem extends StatefulWidget {
  const VaultRowItem({
    super.key,
    required this.vault,
    this.isSelectable = false,
    this.onSelected,
    this.isPressed = false,
  });

  final VaultListItemBase vault;
  final bool isSelectable;
  final VoidCallback? onSelected;
  final bool isPressed;

  @override
  State<VaultRowItem> createState() => _VaultRowItemState();
}

class _VaultRowItemState extends State<VaultRowItem> {
  bool isPressing = false;

  bool _isMultiSig = false;
  String _subtitleText = '';
  bool _isUsedToMultiSig = false;
  List<MultisigSigner>? _multiSigners;

  void _updateVault() {
    _isMultiSig = false;
    _subtitleText = '';
    _isUsedToMultiSig = false;
    _multiSigners = null;

    if (widget.vault.vaultType == VaultType.multiSignature) {
      _isMultiSig = true;
      final multi = widget.vault as MultisigVaultListItem;
      _subtitleText = '${multi.requiredSignatureCount}/${multi.signers.length}';
      _multiSigners = multi.signers;
    } else {
      final single = widget.vault as SinglesigVaultListItem;
      if (single.linkedMultisigInfo != null) {
        final multisigKey = single.linkedMultisigInfo!;
        if (multisigKey.keys.isNotEmpty) {
          final model = Provider.of<VaultModel>(context, listen: false);
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
    final row = widget.isSelectable
        ? GestureDetector(
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
            child: _vaultContainerWidget(),
          )
        : ShrinkAnimationButton(
            pressedColor: MyColors.darkgrey.withOpacity(0.05),
            borderGradientColors: _isMultiSig && _multiSigners != null
                ? CustomColorHelper.getGradientColors(_multiSigners!)
                : null,
            onPressed: () {
              MyBottomSheet.showBottomSheet(
                context: context,
                title:
                    TextUtils.ellipsisIfLonger(widget.vault.name), // overflow
                child: VaultMenuScreen(
                    id: widget.vault.id, isMultiSig: _isMultiSig),
              );
            },
            child: _vaultContainerWidget());

    return ShakeWidget(
      key: ValueKey(
          '${widget.vault.name}_$_subtitleText'), // _subTitle 이 바뀌면 Shake 재시작
      curve: Curves.easeInOut,
      deltaX: 5,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            child: row,
          ),
          const SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }

  Widget _vaultContainerWidget() {
    return Container(
        decoration: BoxDecoration(
          color: isPressing ? MyColors.lightgrey : MyColors.white,
          borderRadius: BorderRadius.circular(28),
          border: widget.isPressed
              ? Border.all(color: MyColors.transparentBlack_30, width: 2)
              : null,
          boxShadow: widget.isSelectable
              ? [
                  const BoxShadow(
                    color: MyColors.transparentBlack_15,
                    offset: Offset(0, 0),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Row(children: [
          // 1) 아이콘
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BackgroundColorPalette[widget.vault.colorIndex],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: SvgPicture.asset(
                  CustomIcons.getPathByIndex(widget.vault.iconIndex),
                  colorFilter: ColorFilter.mode(
                      ColorPalette[widget.vault.colorIndex], BlendMode.srcIn),
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
                    style: Styles.body2.copyWith(color: MyColors.body2Grey),
                  ),
                },
                Text(
                  widget.vault.name,
                  style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: MyColors.black,
                      letterSpacing: 0.2),
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
              child: const Icon(
                Icons.check,
                size: 32,
                color: MyColors.transparentBlack_70,
              ),
            ),
          if (!widget.isSelectable)
            // 3) 오른쪽 화살표
            SvgPicture.asset('assets/svg/arrow-right.svg',
                width: 24,
                colorFilter:
                    const ColorFilter.mode(MyColors.darkgrey, BlendMode.srcIn))
        ]));
  }
}
