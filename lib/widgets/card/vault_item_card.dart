import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
import 'package:coconut_vault/widgets/icon/vault_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'dart:math' as math;

class VaultItemCard extends StatefulWidget {
  final VaultListItemBase vaultItem;
  final VoidCallback onTooltipClicked;
  final VoidCallback onNameChangeClicked;
  final GlobalKey tooltipKey;

  const VaultItemCard({
    super.key,
    required this.vaultItem,
    required this.onTooltipClicked,
    required this.onNameChangeClicked,
    required this.tooltipKey,
  });

  @override
  State<VaultItemCard> createState() => _VaultItemCardState();
}

class _VaultItemCardState extends State<VaultItemCard> {
  bool isItemTapped = false;

  @override
  Widget build(BuildContext context) {
    List<MultisigSigner>? signers;
    bool isMultisig = false;
    late String rightText;

    if (widget.vaultItem is MultisigVaultListItem) {
      /// 멀티 시그
      MultisigVaultListItem multiVault = widget.vaultItem as MultisigVaultListItem;
      signers = multiVault.signers;
      rightText = '${multiVault.requiredSignatureCount}/${multiVault.signers.length}';
      isMultisig = true;
    } else {
      /// 싱글 시그
      SingleSigVaultListItem singleVault = widget.vaultItem as SingleSigVaultListItem;
      final singlesigVault = singleVault.coconutVault as SingleSignatureVault;
      rightText = singlesigVault.keyStore.masterFingerprint;
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
        border: isMultisig ? null : Border.all(color: CoconutColors.borderLightGray, width: 1),
        gradient:
            isMultisig
                ? LinearGradient(
                  colors: CustomColorHelper.getGradientColors(signers!),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(math.pi / 10),
                )
                : null,
      ),
      child: Container(
        margin: isMultisig ? const EdgeInsets.all(2) : null, // 멀티시그의 경우 border 대신
        padding: const EdgeInsets.all(20),
        decoration:
            isMultisig
                ? BoxDecoration(
                  color: CoconutColors.white,
                  borderRadius: BorderRadius.circular(12), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
                )
                : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  setState(() {
                    isItemTapped = true;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    isItemTapped = false;
                  });
                },
                onTap: () {
                  widget.onNameChangeClicked();
                  setState(() {
                    isItemTapped = false;
                  });
                },
                child: Row(
                  children: [
                    _buildIcon(),
                    CoconutLayout.spacing_200w,
                    Expanded(child: Text(widget.vaultItem.name, style: CoconutTypography.body1_16_Bold, maxLines: 1)),
                  ],
                ),
              ),
            ),
            CoconutLayout.spacing_200w,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMultisig) Text(rightText, style: CoconutTypography.heading4_18_NumberBold),
                if (!isMultisig)
                  TooltipButton(
                    isSelected: false,
                    text: rightText,
                    isLeft: true,
                    iconkey: widget.tooltipKey,
                    containerMargin: EdgeInsets.zero,
                    onTapDown: (details) {
                      widget.onTooltipClicked();
                    },
                    textStyle: CoconutTypography.heading4_18_NumberBold,
                    iconColor: CoconutColors.black,
                    iconSize: 18,
                    isIconBold: true,
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('yy.MM.dd HH:mm').format(widget.vaultItem.createdAt),
                      style: CoconutTypography.body3_12.setColor(CoconutColors.gray600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    int colorIndex = widget.vaultItem.colorIndex;
    int iconIndex = widget.vaultItem.iconIndex;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        VaultIcon(iconIndex: iconIndex, colorIndex: colorIndex),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            padding: const EdgeInsets.all(4.3),
            decoration: BoxDecoration(
              color: isItemTapped ? CoconutColors.gray300 : CoconutColors.gray150,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: CoconutColors.gray300, offset: Offset(2, 2), blurRadius: 10, spreadRadius: 0),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isItemTapped ? CoconutColors.gray300 : CoconutColors.gray150,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/svg/edit-outlined.svg',
                width: 10,
                colorFilter: const ColorFilter.mode(CoconutColors.gray700, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
