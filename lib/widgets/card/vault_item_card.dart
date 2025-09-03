import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
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
    late int colorIndex;
    late int iconIndex;
    late String rightText;
    late String tooltipText;

    if (vaultItem is MultisigVaultListItem) {
      /// 멀티 시그
      MultisigVaultListItem multiVault = vaultItem as MultisigVaultListItem;
      signers = multiVault.signers;
      colorIndex = multiVault.colorIndex;
      iconIndex = multiVault.iconIndex;
      int innerSignerCount = multiVault.signers.where((s) => s.innerVaultId != null).length;
      rightText =
          '${innerSignerCount > multiVault.requiredSignatureCount ? multiVault.requiredSignatureCount : innerSignerCount}개 서명 가능';

      tooltipText = '${multiVault.requiredSignatureCount}/${multiVault.signers.length}';
      isMultisig = true;
    } else {
      /// 싱글 시그
      SingleSigVaultListItem singleVault = vaultItem as SingleSigVaultListItem;
      final singlesigVault = singleVault.coconutVault as SingleSignatureVault;
      colorIndex = singleVault.colorIndex;
      iconIndex = singleVault.iconIndex;
      rightText = singlesigVault.keyStore.masterFingerprint;
      tooltipText = t.wallet_id;
    }

    return Container(
      margin: isMultisig
          ? const EdgeInsets.only(top: 20, left: 16, right: 16)
          : const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
          border: isMultisig ? null : Border.all(color: CoconutColors.borderLightGray, width: 1),
          gradient: isMultisig
              ? LinearGradient(
                  colors: CustomColorHelper.getGradientColors(signers!),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(math.pi / 10))
              : null),
      child: Container(
        margin: isMultisig ? const EdgeInsets.all(2) : null,
        padding: isMultisig ? const EdgeInsets.all(20) : const EdgeInsets.all(24),
        decoration: isMultisig
            ? BoxDecoration(
                color: CoconutColors.white,
                borderRadius: BorderRadius.circular(26), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onNameChangeClicked,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CoconutColors.backgroundColorPaletteLight[colorIndex],
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: SvgPicture.asset(
                      CustomIcons.getPathByIndex(iconIndex),
                      colorFilter:
                          ColorFilter.mode(CoconutColors.colorPalette[colorIndex], BlendMode.srcIn),
                      width: 24.0,
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4.3),
                      decoration: const BoxDecoration(
                          color: CoconutColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CoconutColors.gray300,
                              offset: Offset(2, 2),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ]),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: CoconutColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset('assets/svg/edit-outlined.svg',
                            width: 12,
                            colorFilter:
                                const ColorFilter.mode(CoconutColors.gray700, BlendMode.srcIn)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                        child: Text(
                      vaultItem.name,
                      style: CoconutTypography.heading4_18_Bold,
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
            GestureDetector(
              onTap: () {
                onTooltipClicked();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        TooltipButton(
                          isSelected: false,
                          text: rightText,
                          isLeft: true,
                          iconkey: tooltipKey,
                          containerMargin: EdgeInsets.zero,
                          onTap: () {},
                          onTapDown: (details) {
                            onTooltipClicked();
                          },
                          textStyle: CoconutTypography.heading4_18_NumberBold,
                          iconColor: CoconutColors.black,
                          iconSize: 18,
                          isIconBold: true,
                        ),
                      ],
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
              ),
            )
          ],
        ),
      ),
    );
  }
}
