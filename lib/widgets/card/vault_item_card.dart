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

class VaultItemCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    List<MultisigSigner>? signers;
    bool isMultisig = false;
    late String rightText;

    if (vaultItem is MultisigVaultListItem) {
      /// 멀티 시그
      MultisigVaultListItem multiVault = vaultItem as MultisigVaultListItem;
      signers = multiVault.signers;
      rightText = '${multiVault.requiredSignatureCount}/${multiVault.signers.length}';
      isMultisig = true;
    } else {
      /// 싱글 시그
      SingleSigVaultListItem singleVault = vaultItem as SingleSigVaultListItem;
      final singlesigVault = singleVault.coconutVault as SingleSignatureVault;
      rightText = singlesigVault.keyStore.masterFingerprint;
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
          border: isMultisig ? null : Border.all(color: CoconutColors.borderLightGray, width: 1),
          gradient: isMultisig
              ? LinearGradient(
                  colors: CustomColorHelper.getGradientColors(signers!),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(math.pi / 10))
              : null),
      child: Container(
        margin: isMultisig ? const EdgeInsets.all(2) : null, // 멀티시그의 경우 border 대신
        padding: const EdgeInsets.all(20),
        decoration: isMultisig
            ? BoxDecoration(
                color: CoconutColors.white,
                borderRadius: BorderRadius.circular(12), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onNameChangeClicked,
              child: _buildIcon(),
            ),
            const SizedBox(width: 12.0),
            Flexible(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                        child: Text(
                      vaultItem.name,
                      style: CoconutTypography.body1_16_Bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                ],
              ),
            ),
            const Spacer(
              flex: 1,
            ),
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
                    iconkey: tooltipKey,
                    containerMargin: EdgeInsets.zero,
                    onTapDown: (details) {
                      onTooltipClicked();
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
                      DateFormat('yy.MM.dd HH:mm').format(vaultItem.createdAt),
                      style: CoconutTypography.body3_12.setColor(CoconutColors.gray600),
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    int colorIndex = vaultItem.colorIndex;
    int iconIndex = vaultItem.iconIndex;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        VaultIcon(iconIndex: iconIndex, colorIndex: colorIndex),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            padding: const EdgeInsets.all(4.3),
            decoration: const BoxDecoration(
                color: CoconutColors.gray150,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CoconutColors.gray300,
                    offset: Offset(2, 2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: CoconutColors.gray150,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset('assets/svg/edit-outlined.svg',
                  width: 6,
                  colorFilter: const ColorFilter.mode(CoconutColors.gray700, BlendMode.srcIn)),
            ),
          ),
        ),
      ],
    );
  }
}
